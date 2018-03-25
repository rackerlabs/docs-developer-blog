---
layout: post
title: "Code Dive: Openstack Live Migrations"
date: 2018-04-01 00:00
comments: false
author: Brooks Kaminski
published: true
categories:
    - Openstack
---

#Code-Dive: Openstack Live-Migration

The Openstack live migration process is one of the most vital processes in the compute drivers, but also easily one of the most complex.  This complexity drove my curiosity to better understand what is happening under the hood, and I wanted to share that knowledge with you.  Through the next 700 words, we will dive deep into the Openstack codebase, but first,  this article does assume a few things...

<!-- more -->

- Openstack-Nova running version is not completely up to date so is missing a feature such as live-migration Force.
- Virt Driver in use is XenAPI, so we will spend some time in that code base.  
- Finally, while we will walk deeply through the entire process, there may be locations where skipping through code is beneficial, such as when code enters into "computeRPC", we will instead just enter computer.manager, where we know this code will finally rest without going through the RPC services. this assumption is that you have a basic understanding of RPC and why we do this.
- We will skip some basic setting and getting with ellipsis for clarity and not just re-inventing the wheel here.
- We will start this by using nova-client such as: nova live-migration [--block-migrate] <server> [<host>]


### Chapter 1.  The Nova API Layer.

- User submits the request for a live-migration without --block-migrate and without a host. The Xenserver host in use does NOT have shared storage as an option.

- The request enters the osapi\_compute API drivers following the path for live-migration.  This variable is defined within nova.conf as enabled_apis and then picked up from nova.cmd.api.main as follows:


*nova.cmd.api.main* ->
{% highlight python %}
    def main():
    ...
    for api in CONF.enabled_apis:
        should_use_ssl = api in CONF.enabled_ssl_apis
        try:
            server = service.WSGIService(api, use_ssl=should_use_ssl)
            launcher.launch_service(server, workers=server.workers or 1)
    ...
{% endhighlight %}

- The osapi\_compute service is defined in nova.openstack.compute.wsgi.py with a simple init\_application method.  This let's us know that nova.openstack.compute will be the home of our API methods.

- The Call then looks for the live\_migration call in the built list of routes by the nova.openstack.compute.wsgi service.  These routes are defined and tell us where to look for the API method that handles this action.

*nova.api.openstack.compute.routes* ->
{% highlight python %}
   def routes():
    ...
    from nova.api.openstack.compute import migrate_server
    ...
    server_controller = functools.partial(_create_controller,
        ...,
        migrate_server.MigrateServerController,
        ...)
    ...
{% endhighlight %}


Above we can see that this leads us into nova.api.openstack.compute.migrate\_server.py and into the \_migrate\_live method as the WSGI action passed from nova-client would be "os-migrateLive".  Here the API sets a couple of important variables.  The first it looks at if the --block-migrate flag was included.  The default behavior of block\_migration is to contain the "auto" key unless overridden by including --block-migrate.  If the "auto" key is still included, we set this to None, otherwise set it to a Boolean rather than "True".  We get the instance information since this will be vital for migrating an instance, and pass the Instance, Context, Block\_migration over to the Compute API which we resolve down to nova.compute.API.live\_migrate

*nova.api.openstack.compute.migrate\_server.MigrateServerController.\_migrate* ->
{% highlight python %}
def _migrate():
    from nova import compute 
    self.compute_api = compute.API()
    ...
    @wsgi.action('os-migrateLive')
    def _migrate_live(self, req, id, body):
    ...
    block_migration = body["os-migrateLive"]["block_migration"]
    ...
    if api_version_request.is_supported(req, min_version='2.25'):
        if block_migration == 'auto':
            block_migration = None
        else:
            block_migration = strutils.bool_from_string(block_migration,
                                                            strict=True)
    ...
    instance = common.get_instance(self.compute_api, context, id)
    try:
        self.compute_api.live_migrate(context, instance, block_migration,
                                          disk_over_commit, host, force, async)
{% endhighlight %}
                         
                                          
### Chapter 2.  Compute API.

We have made the rounds through the basic Nova API service and set off the asyncronous request to start the Live Migration.  So far we started by issuing this request using nova client which sent a os-migrateLive action, we traced this through the confusing WSGI process which eventually set the block_migration variable, the instance variable, and passed them both to the self.compute_api.live_migrate method.  We know by looking at the imports in the beginning of the last bit of psuedocode that we can resolve this to be nova.compute.api.live_migrate, so let's head there and take a look at our first steps:

The first steps of firing off this live migration.  We set the initial task_state of the server to MIGRATING and we pull the RequestSpec.  This RequestSpec comes from the nova.objects.RequestSpec.get_by_instance_uuid method and is passed into scheduler a little bit later.  The RequestSpec contains details about the instance that scheduler will need to verify if enough room is present.  This information includes NUMANodes, vGPU/CPU, Memory, and Disk information.  Should a host have been specified, there is some additional relevant code in this method, but is not important to our purposes as we will be allowing Scheduler to go wild.  We take the RespectSpec that we gained here, and pass our None host_name, the block_migration/disk_over_commit/async(that we generated in Nova API) to the compute Task_API.  Again we can track this down looking at the imports, and it looks like we are immediately leaving and heading into the Conductor API!

*nova.compute.api.live\_migrate* ->
{% highlight python %}
def live_migrate():
    from nova import conductor
    self.compute_task_api = conductor.ComputeTaskAPI()
    ...
    instance.task_state = task_states.MIGRATING
    ...
    request_spec = objects.RequestSpec.get_by_instance_uuid(context, instance.uuid)
    ...
    try:
            self.compute_task_api.live_migrate_instance(context, instance,
                host_name, block_migration=block_migration,
                disk_over_commit=disk_over_commit,
                request_spec=request_spec, async=async)
{% endhighlight %}

### Chapter 3.  Conductor Magic

   Conductor is a strange beast with a general purpose to act as a go-between for compute nodes and the nova database to add a new layer of security.  This prevents these servers from accessing the database directly in theory, however in practice Conductor winds up picking up more weight than some people think it should.  We immediately left the Compute API and were sent into what we now know is nova.condutor.ComputeTaskAPI.live\_migrate_instance.  Let's take a look. The Class "ComputeTaskAPI" is stored in the api.py file.
   
   A pretty simple chunk of code here that just sets up a new dictionary with the scheduled host name, but we didn't specify this, so a bit unimportant for our needs.  We additionally see that from here it will call one of two locations, depending on whether an async is included for not, this also shows us that essentially "async" is a live\_migration, as this is what calls self.conductor\_compute\_rpcapi.live\_migrate_instance.  I have included the includes for this again to show where it leads.
  
   *nova.conductor.api.ComputeTaskAPI.live\_migrate\_instance* ->
{% highlight python %}
    def live_migrate_instance():
    ...
    from nova.conductor import rpcapi
    self.conductor_compute_rpcapi = rpcapi.ComputeTaskAPI()
    ...
    def live_migrate_instance(self, context, instance, host_name, block_migration, disk_over_commit, request_spec=None, async=False):
    scheduler_hint = {'host': host_name}
    
    if async:
            self.conductor_compute_rpcapi.live_migrate_instance(context, instance, scheduler_hint, block_migration,disk_over_commit, request_spec)
        else:
            self.conductor_compute_rpcapi.migrate_server(context, instance, scheduler_hint, True, False, None, block_migration, disk_over_commit, None, request_spec=request_spec)
{% endhighlight %}            
    
From here we run into the problem mentioned previously of running into the RPC service that enters a land of extreme abstraction.  While my knowledge of how these RPC services work is limited, the basic functions seem to be that it defines a namespace and sends a message to that namespace.  Thus far we have actually remained on the Nova API services, and are now passing a message for the Conductor nodes themselves to pick up and begin work within their Managers.  The RPC call for this looks like the following, with the kw variable here being the payload passed through messenger.
    
*nova.conductor.rpcapi.ComputeTaskAPI.live\_migrate\_instance* ->
{% highlight python %}
    def live_migrate_instance():
    ...
    RPC_TOPIC = 'conductor'
    ...
     kw = {'instance': instance, 'scheduler_hint': scheduler_hint,
              'block_migration': block_migration,
              'disk_over_commit': disk_over_commit,
              'request_spec': request_spec,
              }
        version = '1.15'
        cctxt = self.client.prepare(version=version)
        cctxt.cast(context, 'live_migrate_instance', **kw)
{% endhighlight %}

The main takeaway from this can be to know that we are now officially running on Conductor nodes, and from here the Conductor Manager will run the code that is called (live\_migrate\_instance).  This code is nova.conductor.manager with the ComputeTaskManager having a @profiler decorator for direction.  From here, Conductor will.. Conduct, and coordinate with various other services to complete this migration process.  This is one of the examples where Conductor handles a larger amount of work than just passing traffic, since so much work is being done during a live migration, it is nice to have a centralized location where information is passed back and forth and an essential "Command Center" for the process.  So now we are in the Conductor Manager.
    
    
This method is just a little redirect from the API received into a private method to start the work
    
*nova.conductor.manager.ComputeTaskManager.live\_migrate\_instance* ->
{% highlight python %}
        def live_migrate_instance():
        self._live_migrate(context, instance, scheduler_hint, block_migration, disk_over_commit, request_spec)
{% endhighlight %}
        
Now we actually enter the the Meat and Serverpotatoes. The main purpose of this method is to build a task object that will keep track of the progress and move things along.  This task also allows for us to issue a cancel to the live-migrate prematurely or a force complete if we desire in later API versions. We also set up some basic variables that will be used later.  Some "Task" work is done here that we will skip over as it is more relevant to learning conductor tasks than the Live Migration process itself. Breaking down the work here, we create a new "migration" object from the nova primitives set "nova.objects.Migration".  This hydrates a basic dictionary set for use with empty values, similar to instaniating a new class, this instaniates an empty python object for us with data that we know we will need.  We fill in some of this data that we have the infroamtion for, such as the instance data and source host and migration type.  We then create this "task" and execute it.  From here, the task execution will handle the work.  We can find this task once it is running in nova.conductor.tasks.live\_migrate.
    
    
*nova.conductor.manager.ComputeTaskManager.\_live_migrate* ->
{% highlight python %}
        def _live_migrate():
        destination = scheduler_hint.get("host")
        ...
        migration = objects.Migration(context=context.elevated())
        migration.dest_compute = destination
        migration.status = 'accepted'
        migration.instance_uuid = instance.uuid
        migration.source_compute = instance.host
        migration.migration_type = 'live-migration'
        ...
        task = self._build_live_migrate_task(context, instance, destination,
                                             block_migration, disk_over_commit,
                                             migration, request_spec)
        try:
            task.execute()
{% endhighlight %}
            
Now we are in the execution phase where all of the heavy lifting begins and the chain to complete the migration will start.  This method will call scheduler to find a suitable destination first.  We will refer back to this method several times, as the code does split off into very important parts before returning.  Before calling scheduler however the method will handle setting up some basic variables within its class definition that will be overwritten by the following methods.  Having the knowledge that these are CLASS variables / objects and not method owned is very important to see how these variables are not passed around, but just overwrite the class data.  Since many of these methods remain within the class, there is no reason for them to return or require much input, and just use those class variables as reference. Since so much is happening here I will also begin placing comments inline so please pay attention to "#*#*#"  We will walk through this as much as possible.
    
 *nova.conductor.tasks.live\_migrate.LiveMigrationTask(Class.class)* ->
{% highlight python %}
        class LiveMigrationTask():
        def __init__:
        
            #*#*# We can see here that the data that we gathered from Nova API and our first little run through conductor is being set, the instance information, the source, the block_migration, the None destination, and some other stub data is created that is very important, such as migrate_data.  This will be a valuable variable later on.
            
            self.destination = destination
            self.block_migration = block_migration
            self.disk_over_commit = disk_over_commit
            self.migration = migration
            self.source = instance.host
            self.migrate_data = None

            self.compute_rpcapi = compute_rpcapi
            self.servicegroup_api = servicegroup_api
            self.scheduler_client = scheduler_client
            self.request_spec = request_spec
            self._source_cn = None
            self._held_allocations = None
            
        def _execute(self):
            self._check_instance_is_active() -->
{% endhighlight %}            

The absolute first thing done here is just to verify that the instance is in an active state.  A relatively simple code check here that is a private method within the class. The method checks the power state of the instance.  It pulls the data from the clas instance variable that was set up in the INIT which does contain the "power_state" field.  should this not match a running or paused state, it excepts.  Assuming no exception, the execution moves on, and we head back.
    
*nova.conductor.tasks.live_migrate.LiveMigrationTask.\_check\_instance\_is\_active* ->
{% highlight python %}
    def _check_instance_is_active():
        if self.instance.power_state not in (power_state.RUNNING,
                                             power_state.PAUSED):
        raise exception.InstanceInvalidState
{% endhighlight %}

We completed the active check (marked with an 'x'), and now the execution wants to ensure the host is up. We head to another private method \_check\_host\_is\_up

*nova.conductor.tasks.live_migrate_LiveMigrationTask.\_execute* ->
{% highlight python %}
    def _execute():
        self._check_instance_is_active()  (x)
        self._check_host_is_up(self.source) -->
{% endhighlight %}

Another fairly simple check here to verify that the source server is up and online.  To do this it reaches out to the "servicegroup" which is the database driver to run some checks against down time. So long as this returns fine, we move on again. There is not too much to be said directly about this code, as it mostly is regarding to the database drivers.  We verify no exception here and we return to the execution.
    
*nova.conductor.tasks.live\_migrate\_LiveMigrationTask.\_check\_host\_is\_up* ->
{% highlight python %}
    def _check_host_is_up():
        service = objects.Service.get_by_compute_host(self.context, host)
        if not self.servicegroup_api.service_is_up(service):
            raise exception.ComputeServiceUnavailable(host=host)
{% endhighlight %}

We have completed two basic checks so far, and we are going to skip some migration allocation code which is the new ellipsis you will see.  This doesn't have much to do with our context at the moment.  Now that we verified that the instance is good to go and the source is good to go, it is time to find that destination! This code ensures that a destination was not already given (ours is None, remember) and overrides self.destination and dest\_node with the results of \_find\_destination.
    
*nova.conductor.tasks.live\_migrate\_LiveMigrationTask.\_execute* ->
{% highlight python %}
    def _execute():
        self._check_instance_is_active()  (x)
        self._check_host_is_up(self.source) (x)
        ...
        if not self.destination:
            # Either no host was specified in the API request and the user
            # wants the scheduler to pick a destination host, or a host was
            # specified but is not forcing it, so they want the scheduler
            # filters to run on the specified host, like a scheduler hint.
            self.destination, dest_node = self._find_destination() ->
{% endhighlight %}            
            
This code deals heavily with scheduler to find a destination, and is a section that we will skip over.  In general, we know that we provided a requestSpec to the class with the instance information for what kind of host we need.  This information is piped to Scheduler to find a matching host in a loop.  While we don't care too much about the scheduling parts, we do care about some checks that are run in the loop. This method and the ones it calls are returned to several times before we go back to the \_execute method, but we will eventually go back. Remember that the only thing that \_find\_destination needs to return is the host, and the node (Compute, and Hypervisor)
    
*nova.conductor.tasks.live\_migrate\_LiveMigrationTask.\_find_destination* ->
{% highlight python %}
        def _final_destination():
        ...
        host = None
        while host is None:
            ...
            host = Schedule_Stuff_And_find_A_Host
            try:
                self._check_compatible_with_source_hypervisor(host) -->
                self._call_livem_checks_on_host(host) -->
            except:
                #*#*# Sets host back to None in the event any of the above checks fail, this continues the loop while we schedule and try again.
                host = None
                
            return host, node
{% endhighlight %}

The first method called here is quite short, the \_check\_compatible\_with\_source\_hypervisor.  This takes the host information of source which is stored in the class as self.host and the destination which is just "host" and compares the versions of their platforms to see if there is compatability.  Without compatability, we except which we now know will unset host and continue the loop. Interestingly this method does return data in the form of the source info and destination info, however this information is not stored during the \_find\_destination call and is lost.
    
*nova.conductor.tasks.live\_migrate\_LiveMigrationTask.\_check\_compatible\_with\_source\_hypervisor* ->
{% highlight python %}
        def _check_compatible_with_source_hypervisor():
        ...
        if source_type != destination_type:
            raise exception.InvalidHypervisorType()
        ...
        if source_version > destination_version:
            raise exception.DestinationHypervisorTooOld()
        return source_info, destination_info
{% endhighlight %}        
        
Now that we completed these simple but important checks, we run into the \_call\_livem\_checks\_on\_host. This one is a beefy call that will lead us into several other methods.  Again here it's worth nothing that anything that returns here is lost, we are just looking for an exception or continue. We do however set the class migrate\_data variable as you may remember was set to None during the class instantiation. This migrate\_data is filled with the returns from compute\_rpcapi.check\_can\_live\_migrate\_destination.  Remember that the RPC services leave a message, and in this case for Compute.  We can trace this all the way through the "compute_rpcapi" but we know now that it's going to end up in the Compute Manager.  We also know that this means the code that runs here is going to run on the destination Compute Node, just like when a message was left for Conductor, a conductor node picked it up, and if we were to look into the scheduler calls, a message would be left for them.  This isn't critical to understanding the code, but it is good to know that during this part, The Code will be run on the Destination Compute Node, and that we can skip some code here and go straight to nova.compute.manager.method\_called.
    
*nova.conductor.tasks.live_migrate_LiveMigrationTask.\_call\_livem\_checks\_on\_host* ->
{% highlight python %}
    def _call_livem_checks_on_host():
        try:
            self.migrate_data = self.compute_rpcapi.
                check_can_live_migrate_destination(self.context, self.instance,
                    destination, self.block_migration, self.disk_over_commit)
        except
            raise exception.MigrationPreCheckError(msg)
{% endhighlight %}

We arrive now at the compute mananager on the destination to run checks against the chosen destination. From Nova API manager, to Conductor Manager, to Destination Compute. This method is just a redirect as we saw before from the way it is called via RPC, into a private method.
    
*nova.compute.manager.check\_can\_live\_migrate\_destination* -> 
{% highlight python %}
    def check_can_live_migrate_destination():
            return self._do_check_can_live_migrate_destination(ctxt, instance,
                                                            block_migration,
                                                            disk_over_commit)
{% endhighlight %}
                                                            
We handle some setup here and make a few returns to this code, so let's step through it one at a time.  First we set up some variables for the source and destination by using the host variables that were passed to us from Conductor.  Interestingly if you look at how it pulls the Destination host.. it just pulls it from its own CONF file, since the "destination" is actually where this is running.  Once that is done the code is first passed over to driver.check\_can\_live\_migrate\_destination.  It stores the return of this into dest\_check\_data, and remember that our driver is Xenapi, we head over there for now and will come back here once we fill in the dest\_check\_data.
    
*nova.compute.manager.\_do\_check\_can\_live\_migrate\_destination* ->
{% highlight python %}
    def _do_check_can_live_migrate_destination():
        src_compute_info = obj_base.obj_to_primitive(self._get_compute_info(ctxt, instance.host))
        dst_compute_info = obj_base.obj_to_primitive(self._get_compute_info(ctxt, CONF.host))
        dest_check_data = self.driver.check_can_live_migrate_destination(ctxt,
                                                    instance, src_compute_info, dst_compute_info,
                                                    block_migration, disk_over_commit)
{% endhighlight %}
    
When looking for data in a driver, such as where that "check\_can\_live\_migrate\_destination" method lives, we look in the "driver.py" file, which will be similar to the Routes for an API, and tell us where to go.  We will go over that just this once to show this, and just assume we looked in the future. We can see here from the imports that our new home will be the nova.virt.xenapi.vmops.check\_can\_live\_migrate\_destination method. Remember this is how you can find all calls to the driver.call methods. From compute is issuing commands directly to the driver it controls using its login credentials in the Nova Conf file.
    
*nova.virt.xenapi.driver.check\_can\_live\_migrate\_destination* ->
{% highlight python %}
    def check_can_live_migrate_destination():
        ...
        from nova.virt.xenapi import vmops
        self._vmops = vmops.VMOps(self._session, self.virtapi)
        ...
        return self._vmops.check_can_live_migrate_destination(context,instance,block_migration,disk_over_commit)
{% endhighlight %}
        
This methods job is to make sure that the destination is ready for use.  First it hydrates a new object from the primitives like we have seen before and the dest_check_data that is returned is born.  It will then handle some specific actions depending on whether or not Block Migration was specified.  In our case, we did not specify block migration, and we said we did not have shared storage.  This lack of shared storage means that the "\_ensure\_host\_in\_aggregate" will fail. This means that the block_migration is turned on for us, and we continue into the "if block_migration" code.  See inline comments for more details.
    
*nova.virt.xenapi.vmops.check\_can\_live\_migrate\_destination* ->
{% highlight python %}
    def check_can_live_migrate_destination():
        dest_check_data = objects.XenapiLiveMigrateData()
        
        #*#*# We currently have our block_migration set to None, so we will hit the if state, fail the try clause, and have our block_migration set to true.
        
        if block_migration is None:
            try:
                ...
                self._ensure_host_in_aggregate(ctxt, src)
                ...
            except exception.MigrationPreCheckError:
                block_migration = True

        #*#*# Note:  Should we have been on shared storage, we could have continued with the above trail, which contginues to set up some of the same data as below, but has been trimmed as it is irrelevant to us. We now have block_migration set, and fill in our dest_check_data with information.  We set up the block_migration, migrate_send_data, destination_sr_ref, and a basic blank VIF mapping that contains the network UUID that xenAPI returns . Most of this is fairly simple to understand as we have been dealing with it for a while. The Network UUID call will query Xenapi for its network, and the migrate_receive call will set up a token and tell the destination to prepare itself to accept a migration, but let's take a closer look at these for our own deep understanding. Once these are all set, the compute method version _do_check_can_live_migrate_destination continues. This gets fairly confusing soon as we realize this method does far more than just checking a destination.
        
        if block_migration:
            dest_check_data.block_migration = True
            dest_check_data.migrate_send_data = self._migrate_receive(ctxt)
            dest_check_data.destination_sr_ref = vm_utils.safe_find_sr(self._session)
            net_ref = self._get_network_ref()
            dest_check_data.vif_uuid_map = {'': net_ref}
        return dest_check_data
{% endhighlight %}

migrate\_receive issues a "warning" in some ways through xenapi.  It sends xenapi the "migrate\_receive" command including the nw\_ref (see below), destination, and options) These options can be sr references, live migration, block migration and xen will return a token.  This Token signifies that the server is ready to accept this connection over the nw_ref that you specified to the host that you specified with the parameters that you specified.  This token is stored  as the dest\_check\_data.migrate\_send\_data and returned back to the compute services \_do\_check\_can\_live\_migrate\_destination
    
*nova.virt.xenapi.vmops.migrate\_receive* ->
{% highlight python %}
    def migrate_receive():
        destref = self._session.host_ref
        nwref = self._get_network_ref()
        ...
        try:
            options = {}
            migrate_data = self._session.call_xenapi("host.migrate_receive", destref, nwref, options)
        ...
        return migrate_data
    
    The inline comments from the author explain this function pretty well.  It just pulls the network ref for the management network. Not a super important bit of code here, but it does become more useful later.  Additionally the previous method uses this method as well, so it is useful to know what is happening.
    nova.virt.xenapi.vmops._get_network_ref ->
        # Get the network to for migrate.
        # This is the one associated with the pif marked management. From cli:
        # uuid=`xe pif-list --minimal management=true`
        # xe pif-param-get param-name=network-uuid uuid=$uuid
        expr = 'field "management" = "true"'
        pifs = self._session.call_xenapi('PIF.get_all_records_where',
                                         expr)
        ...
        nwref = pifs[list(pifs.keys())[0]]['network']
        return nwref
        ...
{% endhighlight %}
        
We now return back to \_do\_check\_can\_live\_migrate\_destination with a populated dest\_check\_data which importantly contains the migrate\_send\_data field.  So let's take a look at the method up to where we are now just to remember what is happening. and see that we suddenly are no longer just checking a destination but also are checking a source.  We make an attempt to set migrate\_data to the result of compute.manager.check\_can\_live\_migrate\_source (compute\_rpcapi)!  More data Inline, but note here we are moving through compute\_rpcapi when going to the source, this means tthat code chunk will run on the source compute node.
    
*nova.compute.manager.\_do\_check\_can\_live\_migrate\_destination* ->
{% highlight python %}
    def _do_check_can_live_migrate_destination():
        src_compute_info = obj_base.obj_to_primitive(self._get_compute_info(ctxt, instance.host))
        dst_compute_info = obj_base.obj_to_primitive(self._get_compute_info(ctxt, CONF.host))
        dest_check_data = self.driver.check_can_live_migrate_destination(ctxt,                      (x)
                                                    instance, src_compute_info, dst_compute_info,   (x)
                                                    block_migration, disk_over_commit)              (x)
           
        #*#* Now that we have the populated dest_check_data, we use this to run checks against the source. While this doesn't make a ton of sense within the destination check rather than happening, remember that not a lot of data is returned back to Conductor, so doing this while we still have the data is a little more streamlined.  This method as well runs a couple of methods deep, but once we complete we will return the migrate_data field that is generated here back to conductor.tasks.live_migrate_LiveMigrationTask._call_livem_checks_on_host which stores the returned migrate data is the class variable self.migrate_data.
        
        try:
            migrate_data = self.compute_rpcapi.check_can_live_migrate_source(ctxt, instance, dest_check_data)
        ...
        return migrate_data
{% endhighlight %}

Just like before, we are going to pass this over the XenAPI drivers to handle work, but first computer will set up some basic variables to send with it that it has the ability to get a little easier than Xenapi.  This includes seeing if the server is volume backed, and getting basic Block Device Mapping information.  This information however does not contain Cinder target information (this will be important later for our XenAPI purposes).  Once we have that, we move into the driver. The driver's outcome is stored as "result" which is then returned.  This is a bit interesting as the name changes, where openstack tends to keep these things standard to avoid this kind of confusion. Just know that "result" will be what is stored in migrate\_data.
    
*nova.compute.manager.check\_can\_live\_migrate\_source* ->
{% highlight python %}
    def check_can_live_migrate_source():
        bdms = objects.BlockDeviceMappingList.get_by_instance_uuid(ctxt, instance.uuid)
        is_volume_backed = compute_utils.is_volume_backed_instance(ctxt, instance, bdms)
        dest_check_data.is_volume_backed = is_volume_backed
        block_device_info = self._get_instance_block_device_info(instance, refresh_conn_info=False, bdms=bdms)
        result = self.driver.check_can_live_migrate_source(ctxt, instance,
                                                           dest_check_data,
                                                           block_device_info)
        return result
{% endhighlight %}        
    
The primary focus of this method is to run the xenapi Assert\_can\_migrate command.  This command accepts mappings that are generated in the \_call\_live\_migrate\_command method that is called and then will just return the dest\_check\_data again, although it has been untouched.  More information inline, and we will review the \_call\_live\_migrate\_command method.
    
*nova.virt.xenapi.vmops.check\_can\_live\_migrate\_source* ->
{% highlight python %}
    def check_can_live_migrate_source():
        ...
        if ('block_migration' in dest_check_data and dest_check_data.block_migration):
            ...
            vm_ref = self._get_vm_opaque_ref(instance_ref)
            ...
            try:
                self._call_live_migrate_command("VM.assert_can_migrate", vm_ref, dest_check_data)
            except
                
                #*#*# This checks for a VDI NOT IN MAP exception if this assert fails, due to the organization of this code, if the server has volumes attached during this live migration and is running a newer version of XCP, we will fail as the SR is not set up on the destination yet, and we do not have the volume targets available to set them up.  We swallow this exception.
                
                if ("VDI_NOT_IN_MAP" in reason and
                        host_sw['platform_name'] == "XCP" and
                        versionutils.is_compatible("2.1.0", host_pfv)):
                    LOG.debug("Skipping exception for XCP>=2.1.0, %s", reason)
                    return dest_check_data
        return dest_check_data
{% endhighlight %}

This method calls the XenAPI driver to run a specified command.  This method is used twice during the live\_migration process, once to run this assert, and again later to actually start the live migration process. The method will generate maps for various resources to their owners, these maps are Source Vif -> Destination Network, Source VDI -> Destination SR.  These maps can be used more intensively by the call including such things as GPU and CPU maps, but we only use these two for our purposes.  We send that data to the call\_xenapi method which calls the "assert\_can\_migrate" that we called this method with and if any of these maps fail the process will Except. Essentially it is looking at these maps to ensure that everything exists properly and is ready to accept the migration. Some extraneous content is trimmed here for simplicity. Note that nothing is returned here, we are inside of the Try block and will just except, or continue and return the dest_check_data.
    
*nova.virt.xenapi.vmops.\_call\_live\_migrate\_command* ->
{% highlight python %}
    def _call_live_migrate_command():
        ...
        migrate_send_data = migrate_data.migrate_send_data
        ...
        destination_sr_ref = migrate_data.destination_sr_ref
        vdi_map = self._generate_vdi_map(destination_sr_ref, vm_ref)
        ...
        vif_map = {}
        vif_uuid_map = None
        if 'vif_uuid_map' in migrate_data:
            vif_uuid_map = migrate_data.vif_uuid_map
        if vif_uuid_map:
            vif_map = self._generate_vif_network_map(vm_ref, vif_uuid_map)
        self._session.call_xenapi(command_name, vm_ref, migrate_send_data, True, vdi_map, vif_map, options)
{% endhighlight %}

We assume the assert did not fail, so we have moved on now and return dest\_check\_data out of the driver's check\_can\_live\_migrate\_source. This rolls us back to compute.manager.check\_can\_live\_migrate\_source where result is now stored.  We learn now that result is just dest\_check\_data that has been un-modified.  We return result(dest\_check\_data) to \_do\_check\_can\_live\_migrate\_destination which stores result(dest\_check\_data) as migrate data and returns that data.  From here we roll all the way back into nova.conductor.tasks.live_migrate\_LiveMigrationTask.\_call\_livem\_checks\_on\_host which orginally called "self.migrate_data = self.compute\_rpcapi.check\_can\_live\_migrate\_destination". Since this method returns nothing, we can roll all the way back to \_find_destination! Now we have a class variable which just holds the dest\_check\_data that is now called migrate\_data.  This contains information such as the Block\_migrate, the dest information, and some other basics.  We are all the way back to conductor and our checks against both the Destination and Source can be considered complete.  Let's look at that code again to refresh:
    
    
We have completed both of these checks, call\_livem\_checks\_on\_host and \_check\_compatible\_with\_source\_hypervisor.  This means that we do not hit the except and return the host information further back the line.  We can now successfully head all the way back to the execute.  Remember that we now have a class variable set self.migrate\_data with the dest\_check\_data, and we will just return the destination information that we got from scheduler since the checks passed.
    
*nova.conductor.tasks.live\_migrate\_LiveMigrationTask.\_find_destination* ->
{% highlight python %}
    def _find_destination():
        ...
        host = None
        while host is None:
            ...
            host = Schedule_Stuff_And_find_A_Host
            try:
                self._check_compatible_with_source_hypervisor(host) -->
                self._call_livem_checks_on_host(host) -->
            except:
                #*#*# Sets host back to None in the event any of the above checks fail, this continues the loop while we schedule and try again.
                host = None
                
            return host, node
{% endhighlight %}
    
We finally return to execute and I mark what we completed with an (x).  We completed the destination find and move on to actually run the live\_migration finally.  We set up some basic variables into the class migration option, including the source node, the destination node and compute that we got from scheduling, and we pass this long to the compute\_rpc service for the source by calling self.compute\_rpcapi.live\_migration.  This is the end of the execution code for the live migration. These final steps will handle on the compute node.
    
*nova.conductor.tasks.live\_migrate\_LiveMigrationTask.\_execute* ->
{% highlight python %}
    def _execute():
        self._check_instance_is_active()  (x)
        self._check_host_is_up(self.source) (x)
        ...
        if not self.destination:
            ...
            self.destination, dest_node = self._find_destination() (x)
        self.migration.source_node = self.instance.node
        self.migration.dest_node = dest_node
        self.migration.dest_compute = self.destination
        self.migration.save()
        return self.compute_rpcapi.live_migration(self.context,
                host=self.source,
                instance=self.instance,
                dest=self.destination,
                block_migration=self.block_migration,
                migration=self.migration,
                migrate_data=self.migrate_data)
{% endhighlight %}    
    
### Chapter 4: Compute and Hypervisor controls
    
Like always with these RPC calls, we move into a private method. There is some complexity here in that this sets up an eventlet thread to run in the background, since this process can take a long period of time, we do not want the RPC worker to be locked to this method while the private runs.

*nova.compute.manager.live\_migration* ->
{% highlight python %}
    def live_migration():
        self._set_migration_status(migration, 'queued')
        ...
        
        #*#*# We call the private method here. _do_live_migration.
        
        def dispatch_live_migration(*args, **kwargs):
            with self._live_migration_semaphore:
                self._do_live_migration(*args, **kwargs)
        ...
{% endhighlight %}

This is is the beginning of the prep phase for the live migration proper.  We set the migration status to Preparing and if we are running a block_migration (we are now), then we gather details about the disks information and get basic BDM information again, since we threw this away during the scheduling phase and only returned host detail.  We pull that very basic information and throw it into the pre\_live\_migration through computeRPC once again. We save the result of this as migrate\_data.  Note here that we are actually passing in our current migrate\_data which was the dest\_check\_data, so we will be overwritting that variable with the result of pre\_live\_migration.  We will also look briefly into the get disk info method here for clarity. Once we finish the pre\_live\_migration, we will return to this method to continue.  Note:  We are running through ComputeRPC here as we are traversing to the Destination.  We need to set up the destination to be be ready here by attaching volumes, setting up networks, and filtering rules.
    
*nova.compute.manager.\_do\_live\_migration* ->
{% highlight python %}
    def _do_live_migration():
        self._set_migration_status(migration, 'preparing')
        ...
        try:
            if ( block_migration):
                block_device_info = self._get_instance_block_device_info(context, instance)
                disk = self.driver.get_instance_disk_info(instance, block_device_info=block_device_info)
            ...
            migrate_data = self.compute_rpcapi.pre_live_migration(instance, block_migration, disk, dest, migrate_data)
{% endhighlight %}

A case here where XenAPI actually doesn't implment this work and just passes the check, relying on this to be done later.
    
*nova.virt.xenapi.driver* ->
{% highlight python %}
    def driver():
        def get_instance_disk_info():
            pass
{% endhighlight %}

This method handles a decent amount of complicated work.  First it pulls the more complete Block Device Mappings including the Cinder Target information.  It will then pull networking information again, and pass the data into the driver's version of this method to handle work, passing the block device data that was generated.  The result of this driver "pre_live_migration" call is saved as migrate\_data.  Once complete it moves on and sets up the needed networks on the host machine if needed, and filtering rules before returning migrate\_data.  Very Very trimmed code below.  Again here note that we pass and override migrate\_data, and that we are running on the Destination.
    
*nova.compute.manager.pre\_live\_migration* ->
{% highlight python %}
    def pre_live_migration():
        migrate_data.old_vol_attachment_ids = {}
        bdms = objects.BlockDeviceMappingList.get_by_instance_uuid()
        try:
            connector = self.driver.get_volume_connector(instance)
            for bdm in bdms:
                if bdm.is_volume and bdm.attachment_id is not None:
                    ...
                    attach_ref = self.volume_api.attachment_create()
                    ...
                    bdm.attachment_id = attach_ref['id']
                    bdm.save()
                
        block_device_info = self._get_instance_block_device_info()
        network_info = self.network_api.get_instance_nw_info(context, instance)
        migrate_data = self.driver.pre_live_migration(,instance,block_device_info,network_info,disk,migrate_data) -->
        self.network_api.setup_networks_on_host()
        self.driver.ensure_filtering_rules_for_instance()

        return migrate_data
{% endhighlight %}

A fairly simple method that just adds more data to the migrate\_data object.  We connect the volumes on the destination hypervisor by passing the bdm information we gathered in the last method into "connect_block_device_volumes".  This code can delve fairly deep into Cinder and we do not need a huge grasp on this at the moment, just know that we are attaching them now on the destination.  We additionally create interim networks and the SR Mapping and VIF mapping for both of these are stored in the migrate\_data field.
    
*nova.virt.xenapi.vmops.pre\_live\_migration* ->
{% highlight python %}
    def pre_live_migration():
        migrate_data.sr_uuid_map = self.connect_block_device_volumes(bdms)
        migrate_data.vif_uuid_map = self.create_interim_networks(network_info)
        return migrate_data
{% endhighlight %}
 
We now have added even more data to our dest\_check\_data aka migrate data field.  We have destination information there now that networks have been set up, filtering rules are in place, volumes have been attached, and we pass that modified migrate\_data all the way back to nova.compute.manager.\_do\_live\_migration on the source.  And we'll look again at where we left off.
    
Now that we have completed the pre\_live_migration method we can move on, which leaves us just a status change into "running" (YAY), and into the driver's live\_migration code. Nothing is returned from here and it is just a try: except:.  From here the driver will handle the rest of the process.
    
*nova.compute.manager.\_do\_live\_migration* ->
{% highlight python %}
    def _do_live_migration():
        ...
        ...
        try:
            if ( block_migration):
                block_device_info = self._get_instance_block_device_info(context, instance)
                disk = self.driver.get_instance_disk_info(instance, block_device_info=block_device_info)
            ...
            migrate_data = self.compute_rpcapi.pre_live_migration(instance, block_migration, disk, dest, migrate_data) (x)
        
        self._set_migration_status(migration, 'running')
        try:
            self.driver.live_migration(context, instance, dest,
                                       self._post_live_migration,
                                       self._rollback_live_migration,
                                       block_migration, migrate_data)
{% endhighlight %}
 
The name of this method actually changes a bit on the way into the driver for Xenapi, so a bit of confusion there, but not too bad.  We are getting really close to the end here and have come a monumental amount of distance in thise code line.  Now we issue the driver to go ahead and start this thing.  The method gathers some basic data once again since so often it is not returned, fills even more data into migrate\_data, and issues the Xenapi Migrate command!  This means that XenAPI begins the mirror, and the process is legitimately kicked off. This process handles getting the VM started on the destination, transferring the RAM states, ETC... leaving just the cleanup to be done by the Openstack Drivers.  More comments In-Line.  Once the long long migrate\_send command completes, we move on to the "post\_method".
    
*nova.virt.xenapi.vmops.live\_migrate* ->
{% highlight python %}
    def live_migrate():
        ...
        vm_ref = self._get_vm_opaque_ref(instance)
        ...    
        (kernel, ramdisk) = vm_utils.lookup_kernel_ramdisk(self._session, vm_ref)
        migrate_data.kernel_file = kernel
        migrate_data.ramdisk_file = ramdisk

        if migrate_data is not None and migrate_data.block_migration:
                ...
                try:
                    self._call_live_migrate_command(
                        "VM.migrate_send", vm_ref, migrate_data)
                ...
                
                    #*#*#*# We used this _call_live_migrate_command before to run our assert, We do the same thing here but to tell Xenapi to actually begin running the task.  This officially means that the live_migration is running.  We will not review this method again, but the maps are again generated and this time passed to the actual method.  Running the assert previously to this means that if anything would have failed regarding these maps, they would have failed much earlier in the process where it was easier to roll back.  Now that networks are configured on the destination, volumes attached, and various other information ahs been pulled, we can consider it a monumental waste of time if we fail here for a mapping reason.
                    
            post_method(context, instance, destination_hostname, 
                        block_migration, migrate_data)
 {% endhighlight %}                        
                        
The way that post\_method is called is a bit interesting in that it is defined by the incoming variables accepted by the self.driver.live\_migration method.  You can see above that this is called with "self.post\_live\_migration" and "self.\_rollback\_live\_migration".  When a vault occurs it calls that "recover_method" and in this case it calls the "post_method" which resolves to the nova.compute.manager.\_post\_live\_migration. It is tempting to believe this being the nova.virt.xenapi.vmops.post\_live\_migration however remember that this data was sent from COMPUTE and not VIRT.  You can also see that the post\_live\_migration in XENAPI is "post_live_migration" and not "_post_live_migration"..  So let's take a look!
    
Remember that we didn't move through RPC to get here, so we are still running on the Source.  So far we only transferred RPC to handle the destination checks and some bouncing around back to source again.  From now we are on the source.  This method handles the cleanup actions that need to be done.  It gathers BDM records(again!) and terminates and detaches the volumes from the source hypervisor,  preparing to switch around networking information. This method gets very long, so we'll walk through it a little at a time and follow its cleanup steps where applicable.  More Comments Inline
    
*nova.compute.manager.\_post\_live\_migration* ->
{% highlight python %}
    def _post_live_migration():
        bdms = objects.BlockDeviceMappingList.get_by_instance_uuid()
        block_device_info = self._get_instance_block_device_info()
        
        #*#*# This method is fairly simple and just calls Xenapi to remove the Ramdisk files from the source
        #*#*# Since we will no longer need this data on the source and we are essentially cleaning up.
        
        self.driver.post_live_migration() 

        #*#*# We pull the block devices again here and terminate the source connections
        
        connector = self.driver.get_volume_connector(instance)
        for bdm in bdms:
            if bdm.is_volume:
                if bdm.attachment_id is None:
                    self.volume_api.terminate_connection()
                else:
                    old_attachment_id = migrate_data.old_vol_attachment_ids[]
                    self.volume_api.attachment_delete(ctxt, old_attachment_id)

        #*#*#  The Networking API is a bit out of the scope of this article.  Here we are removing filters placed on the instance VIFS.  In many instances both of these will just pass to continue, but this depends greatly on the networking API and Firewall API in use.  Xenserver will often use NOOP firewall which will pass, and neutron will additionally pass here.
        
        network_info = self.network_api.get_instance_nw_info(ctxt, instance)
        self.driver.unfilter_instance()
        migration = {'source_compute': self.host, 'dest_compute': dest}
        self.network_api.migrate_instance_start(instance, migration)
        
        destroy_vifs = False
        try:
            self.driver.post_live_migration_at_source() -->
{% endhighlight %}           
    
Here we actually delete the vif connections for the VM on the source, effectively stopping any connectivity to the source. This traverses two methods so we will take a look at both.  The first method just calls  \_delete\_networks\_and\_bridges.  This method then calls the vif_driver to call "delete_network_and_bridge".  Kind of a long way around to get to the work, but we can see the vif\_driver defined here as well
    
*nova.virt.xenapi.post\_live\_migration\_at\_source* ->
{% highlight python %}
    def post_live_migration_at_source():
        self._delete_networks_and_bridges(instance, network_info)
 {% endhighlight %}
 
*nova.virt.xenapi.\_delete\_networks\_and\_bridges* ->
{% highlight python %}
    def _delete_networks_and_bridges():
        ...
        vif_impl = importutils.import_class(CONF.xenserver.vif_driver)
        self.vif_driver = vif_impl(xenapi_session=self._session)
        ...
        for vif in network_info:
            try:
                self.vif_driver.delete_network_and_bridge(instance, vif)
 {% endhighlight %}
 
Looking at a sample nova.conf we can see what that CONF.xenserver.vif\_driver value is.  Depending on the type of networking used (OpenVSwitch, Linux Bridges, Etc) this will lead to different classes.  Let's use for example OVS.
    
    grep "vif_driver" /etc/nova/nova.conf 
    vif_driver = nova.virt.xenapi.vif.XenAPIOpenVswitchDriver
        
With this we know we can look at nova.virt.xenapi.vif.XenAPIOpenVswitchDriver.delete\_network\_and\_bridge. This method is very intensive and again not in our scope here, but feel free to look at this code on your own.  It will destroy the OVS port bindings for the bridge and vif, patch ports, and tear down the rest of the environment for routing to this VIF.  With this method done we can move on.. Let's look back at the Compute post live migration with a bit more trimming. We will mark where left off with (X).
    
Now that we are past the (X) we can see that now some cleanup is handled on the destination.  We can also see it passing through compute RPC now.  We should be pretty used to this since it is a destination cleanup, we want it running on the destination, so we travel there for a minute to handle that.  It's also worth seeing that even if this fails, the codeline will not fail.  On an exception, we set a variable that it failed and move on.  This WILL cause the process to fail completely, but we want to ensure we clean up things in the proper order, and not just fail here.
    
*nova.compute.manager.\_post\_live\_migration* ->
{% highlight python %}
    def _post_live_migration():
        ...
        bdms = objects.BlockDeviceMappingList.get_by_instance_uuid()
        ...
        ...
        connector = self.driver.get_volume_connector(instance)
        for bdm in bdms:
           ...
                    self.volume_api.terminate_connection()

        ...
        ...
        destroy_vifs = False
        try:
            self.driver.post_live_migration_at_source() (X)
            
        source_node = instance.node
        ...
        try:
            self.compute_rpcapi.post_live_migration_at_destination() ->
        except Exception as error:
            WARNING
 {% endhighlight %}
            
    
Another pretty beefcake method here to handle actions on the destination, but also reachs out to the source to tear even more information down.  We will work inline here so that we can keep our (read: my) thoughts straight.
    
*nova.compute.manager.post\_live\_migration\_at\_destination* ->
{% highlight python %}
    def post_live_migration_at_destination():
        *#*#* This is the second time these two methods are done due to some issues with Linux Bridges.  We do not need to follow this code line as it delves again  into the neutron codebase.  This sets up the linux bridges, OVS, etc on the destination to start handling the traffic for the VM.
        self.network_api.setup_networks_on_host()
        self.network_api.migrate_instance_finish()

        ...
        
        #*#*# We pull BDMS sweet monkey we pull BDMS again, and we pass that data to the XenAPI driver for running its own post_live_migration_at_destination.
        #*#*# Without digging too deeply into the XenAPI call. This sets up rules on the VIF to actually block all traffic.  This is because Security Groups
        #*#*# have not been installed yet, so to avoid unwanted possible traffic, we kill everything temporarily.
        
        network_info = self.network_api.get_instance_nw_info(context, instance)
        block_device_info = self._get_instance_block_device_info(context,
                                                                 instance)
        try:
            self.driver.post_live_migration_at_destination()
        except Exception:
            EXCEPT
        
        
        #*#*# Now we update the instance details in the database.  We update to reflect the new destination host is live, ensure 
        #*#*# the power state is started, remove the task_state from the VM (meaning we are definately almost done here),
        #*#*# and call the networks API again to tear down the networks one last time on the source, and set them up on the destination.
        #*#*# This process will also remove the rule we just placed to block all traffic.
        
        finally:
            current_power_state = self._get_power_state(context, instance)
            node_name = None
            prev_host = instance.host
            try:
                compute_node = self._get_compute_info(context, self.host)
                node_name = compute_node.hypervisor_hostname
            finally:
                instance.host = self.host
                instance.power_state = current_power_state
                instance.task_state = None
                instance.node = node_name
                instance.progress = 0
                instance.save(expected_task_state=task_states.MIGRATING)

        self.network_api.setup_networks_on_host(context, instance, prev_host, teardown=True)
        self.network_api.setup_networks_on_host(context, instance, self.host)
 {% endhighlight %}
        
Now we can return back to _post_live_migration again, more trimmed down psuedocode here to see where we left off marked with an (X).
    
So the last process we did essentially completed the migration.  As far as the database is considered the task_state is empty so this thing is no longer running.  The instance is pointed to the new host in the database as well as we saw with the instance.host = self.host from the destination.  The rest of this process is handling the rest of the cleanup, and ending the process completely. Comments Inline.
    
*nova.compute.manager.\_post\_live\_migration* ->
{% highlight python %}
    def _post_live_migration():
        ...
        bdms = objects.BlockDeviceMappingList.get_by_instance_uuid()
        ...
        ...
        connector = self.driver.get_volume_connector(instance)
                self.volume_api.terminate_connection()
        ...
        ...
        self.driver.post_live_migration_at_source() (X)
        ...
        try:
            self.compute_rpcapi.post_live_migration_at_destination() (X)
        except Exception as error:
            WARNING
        
        #*#*#*  This calls the Driver Cleanup.  XenAPI just passes on this as the work was handled by the live_migration process issued from XenAPI.
        
        do_cleanup, destroy_disks = self._live_migration_cleanup_flags()
        if do_cleanup:
            self.driver.cleanup()

        ...
        ...
        
        #*#*# Previous to this we set some statistical information such as allocations, usage information, and scheduler information, however this is fairly non vital to our looking at this code, and in this next code block we set the actual migration status record in the database to complete.  Once this is done a couple of more allocations are handled, and the code line dead ends.  The live Migration is Done.  Server is Active, Hosts have Changed.  Destination is Cleaned up, and the Migration Record is "completed"

        if migrate_data and migrate_data.obj_attr_is_set('migration'):
            migrate_data.migration.status = 'completed'
            migrate_data.migration.save()
            migration = migrate_data.migration
        ...
 {% endhighlight %}
        
        
We have now completed the full trace through the Live Migration process, while also taking some time to look at and understand how the RPC services are used to communicate back and forth between services.  We started out in the Nova API service and quickly bounced between Compute API,  Conductor, Scheduler, Destination/Source Compute/Hypervisor, Neutron, and many others.  While some of these were a bit too difficult to cover in this article, you can use this same logic of moving through the code piece by piece to investigate any process, failure, or stack trace that you may receieve.  I would encourage readers to use this information to dive deeper into this codebase in areas where it interests them that we did not explore.  For example, within the Scheduler codebase it utilizes interesting "Abstract Base Classes" to handle scheduling efforts, and some very complicated and confusing rules that can be fun to explore.  Neutron itself is a complicated beast, and has a lot of value to understand deeper.

Please remember here however that this was not written by a professional writer or developer, but just a Racker with a passion for Openstack.  I hope you've enjoyed this code dive and gained some knowledge, and hopefully we will return soon with a new process to explore!
