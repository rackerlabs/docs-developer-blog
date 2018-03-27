---
layout: post
title: "Code Dive: Openstack Live Migrations"
date: 2018-04-01 00:00
comments: false
author: Brooks Kaminski
published: true
authorIsRacker: true
categories:
    - Openstack
---

#Code-Dive: Openstack Live-Migration

The OpenStack live migration process is one of the most vital processes in the compute drivers, but it is also easily one of the most complex. This complexity drove my curiosity to better understand what is happening under the hood, and I wanted to share that knowledge with you. In this article, we dive deep into the OpenStack codebase, but first, the article does assume a few things.

<!-- more -->

### Assumptions

- The current OpenStack-Nova version is not completely up to date and is missing the live-migration `Force` feature.
- The `Virt Driver` in use is XenAPI, so we will spend some time in that code base.  
- Finally, while I go deep into the entire process, there may be sections where skipping through code is beneficial, such as when code enters into *computeRPC*. In those cases, I instead just enter compute.manager, where this code finally lives, without going through the RPC services. I'm assuming that you have a basic understanding of RPC and what it does.
- I use ellipses to skip some basic *set* and *get* instructions for clarity (no need to re-invent the wheel here).

### Chapter 1: The Nova API layer

Throughout the article, I share some code and explain what's going on or highlight interesting points.

#### Exploration 1

Let's examine the nova-client instruction: 

{% highlight python %}
    nova live-migration [--block-migrate] <server> [<host>]
{% endhighlight %}

I submitted a request for a live-migration without --block-migrate and without a host. The Xenserver host does not have shared storage as an option. The request enters the *osapi_compute* API drivers following the path for *live-migration*. This variable is defined within *nova.conf* as `enabled_apis` and then picked up from *nova.cmd.api.main* as shown in the following sample.

#### Exploration 2

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

The *osapi_compute* service is defined in *nova.openstack.compute.wsgi.py* with a simple *init_application* method. This tells us that *nova.openstack.compute* is the home of the API methods. The operation then looks for the *live_migration* call in the built-in list of routes within the *nova.openstack.compute.wsgi* service. These routes are defined and tell us where to look for the API method that handles this action.

#### Exploration 3

The following code leads us into *nova.api.openstack.compute.migrate_server.py* and into the *_migrate_live* method because the WSGI action passed from nova-client is `os-migrateLive`.  

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

#### Exploration 4

Here the API sets a couple of important variables. It looks at the first if the `--block-migrate` flag was included. The default behavior of *block_migration* is to contain the `auto` key unless overridden by including the `--block-migrate` parameter. If the `auto` key is still included, set this to `None`, otherwise set it to a Boolean rather than `True`. We get the instance information because this is vital for migrating an instance and passing the instance, context, and block_migration over to the Compute API, which is resolved down to *nova.compute.API.live_migrate*.

*nova.api.openstack.compute.migrate_server.MigrateServerController._migrate* ->
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
                                          
### Chapter 2. The Compute API

We have made the rounds through the basic Nova API service and kicked off the asynchronous request to start the live migration. I issued this request by using the nova client, which sent a *os-migrateLive* action. We traced this through the confusing WSGI process, which eventually set the *block_migration* variable and the instance variable, passing them both to the *self.compute_api.live_migrate* method. We know (by looking at the imports at the beginning of the previous psuedocode sample) that we can resolve this to be *nova.compute.api.live_migrate*, so let's head there and take a look at our first steps.

#### Exploration 5

*nova.compute.api.live_migrate* ->
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

These are the first steps for firing off this live migration. I set the initial *task_state* of the server to `MIGRATING` and pull the *RequestSpec*. This *RequestSpec* comes from the *nova.objects.RequestSpec.get_by_instance_uuid* method and is passed into scheduler a little bit later on. The *RequestSpec* contains details about the instance that the scheduler needs to verify to determine whether enough room is present to complete the process. This information includes NUMANodes, vGPU/CPU, Memory, and Disk information. If a host was specified, the method would have included additional relevant code, but this is not important for our purposes - we're allowing the scheduler to go wild. Next, I take the *RespectSpec* from the previous sample and pass the `None` *host_name* and the *block_migration/disk_over_commit/async* (that we generated in Nova API) to the compute *Task_API*. Again, track this down by examining the imports, and we are now heading into the Conductor API!

### Chapter 3.  Conductor magic

Conductor is a strange beast primarily designed to act as a go-between for compute nodes and the nova database and to add a layer of security. This theoretically prevents the servers from accessing the database directly, however, in practice, Conductor winds up picking up more weight than some people think it should. When we left the Compute API, we were sent into the *nova.condutor.ComputeTaskAPI.live_migrate_instance*. Let's look at the class `ComputeTaskAPI`, which is stored in the *api.py* file.
   
#### Exploration 6

*nova.conductor.api.ComputeTaskAPI.live_migrate_instance* ->
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

This simple chunk of code sets up a new dictionary with the scheduled host name, but, because I didn't specify this, it's unimportant for our needs. We see from this code that the process calls one of two locations, depending on whether the async setting is included or not. The code also reveals that "async" is essentially a live_migration, because this code calls *self.conductor_compute_rpcapi.live_migrate_instance*. I kept the includes for this operation to show where it leads.
  
#### Exploration 7          
    
At this point, we run into the problem mentioned previously regarding the RPC service, which enters a land of extreme abstraction. While my knowledge of how these RPC services work is limited, basically it defines a namespace and sends a message to that namespace. Thus far, I have stayed in the Nova API services, but now I'm passing a message for Conductor nodes themselves to pick up and begin to work within their managers. The RPC call for this looks like the following, with the `kw` variable here being the payload passed through messenger.
    
*nova.conductor.rpcapi.ComputeTaskAPI.live_migrate_instance* ->
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

The main takeaway from this is that we are now officially running on Conductor nodes, and from here the Conductor Manager runs the code that is called (*live_migrate_instance*). This code is *nova.conductor.manager* with the *ComputeTaskManager* having an `@profiler` decorator for direction. From here, Conductor conducts and coordinates with various other services to complete the migration process. This is an example of Conductor handling a larger amount of work rather than just passing traffic. Since so much work is necessary during a live migration, it is nice to have a centralized location (or "command center") where information is passed back and forth. So, now we are in the Conductor Manager.
    
#### Exploration 8  

The following method is just a little redirect from the API, received into a private method, to start the work:
    
*nova.conductor.manager.ComputeTaskManager.live_migrate_instance* ->
{% highlight python %}
        def live_migrate_instance():
        self._live_migrate(context, instance, scheduler_hint, block_migration, disk_over_commit, request_spec)
{% endhighlight %}
        
#### Exploration 9

Now we actually enter the server meat and potatoes. The main purpose of the following method is to build a task object that keeps track of the progress and moves things along. This task also allows me to cancel to the live-migrate prematurely or, if I want to in later API versions, to issue a force complete. It also sets up some basic variables for later use. Some task work is done here, which I'm skipping over because it is more relevant to learning Conductor tasks than the live migration process itself. Breaking down the work here, I create a new "migration" object from the nova primitives set: *nova.objects.Migration*. This creates a basic dictionary set with empty values. Similar to instantiating a new class, this instantiates an empty python object with data that we expect. I fill in some of this data that I already know, such as the instance data, source host, and migration type. Then I create this task and execute it. From here, the task execution handles the work. Find this task, once it is running, in *nova.conductor.tasks.live_migrate*.
    
    
*nova.conductor.manager.ComputeTaskManager._live_migrate* ->
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

#### Exploration 10
            
Now, we enter the execution phase, where all of the heavy lifting begins and the chain to complete the migration starts. The following code first calls the scheduler to find a suitable destination. We will refer back to this method several times, because the code splits off completes several very important tasks before returning. Before calling scheduler, however, the method sets up some basic variables within its class definition that are overwritten by subsequent methods. It is important to understand that these are *class* variables or objects and are not method-owned - these variables are not passed around but instead overwrite the class data. Since many of the variables remain within the class, there is no reason for them to be returned or to require much input, and the methods might use these class variables as reference. Since so much is happening here, I've also placed comments inline in the code. Please pay attention to `#*#*#` lines - I will walk you through this as much as possible.
    
 *nova.conductor.tasks.live_migrate.LiveMigrationTask(Class.class)* ->
{% highlight python %}
        class LiveMigrationTask():
        def __init__:
        
            #*#*# We can see here that the data (which we gathered from Nova API and our first little run through conductor) is being set. The instance information, the source, the block_migration, the `None` destination, and some other stub data is created that is very important, such as migrate_data. This will be a valuable variable later on.
            
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

The first thing done here is verification that the instance is in an active state - a relatively simple code check that is a private method within the class. 

#### Exploration 11

Next, the method checks the power state of the instance. It pulls the data from the class instance variable that was set up in the INIT and which contains the *power_state* field. An exception is created if this does not match a *running* or *paused* state. Assuming no exception, the execution moves on.
    
*nova.conductor.tasks.live_migrate.LiveMigrationTask._check_instance_is_active* ->
{% highlight python %}
    def _check_instance_is_active():
        if self.instance.power_state not in (power_state.RUNNING,
                                             power_state.PAUSED):
        raise exception.InstanceInvalidState
{% endhighlight %}

#### Exploration 12

I completed the active check (marked with an 'X' in the following code), and now the process ensures that the host is up. We head to another private method *_check_host_is_up*.

*nova.conductor.tasks.live_migrate_LiveMigrationTask._execute* ->
{% highlight python %}
    def _execute():
        self._check_instance_is_active()  (X)
        self._check_host_is_up(self.source) -->
{% endhighlight %}
  
#### Exploration 13

Here's another fairly simple check to verify that the source server is up and online. To do this, it reaches out to the    `servicegroup`, which is the database driver, to run some checks against down time. A long as this returns successfully, we move on again. There is not too much to say about this code, because it mostly relates to the database drivers.  If there's no exception here, we return to the execution.

*nova.conductor.tasks.live_migrate_LiveMigrationTask._check_host_is_up* ->
{% highlight python %}
    def _check_host_is_up():
        service = objects.Service.get_by_compute_host(self.context, host)
        if not self.servicegroup_api.service_is_up(service):
            raise exception.ComputeServiceUnavailable(host=host)
{% endhighlight %}

#### Exploration 14

The following code completes two more basic checks, and I'm going to skip some migration allocation code (noted by the ellipses). This doesn't have much to do with the current discussion.  

Now that the instance and the source are both verified as good to go, it is time to find that destination! This code ensures that a destination was not already given (remember that our destination is `None`) and overrides *self.destination* and *dest_node* with the results of *_find_destination*.
    
*nova.conductor.tasks.live_migrate_LiveMigrationTask._execute* ->
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
   
#### Exploration 15

The following code works closely with the scheduler to find a destination and is a section that we will move past quickly. In general, we know that we provided a *requestSpec* to the class with the instance information for what kind of host we need.  This information is piped to the scheduler to find a matching host in a loop. While we don't care too much about the scheduling parts, we do care about some checks that are run in the loop. This method (and the ones it calls) are returned to several times before we go back to the *_execute* method, but we will get back to it, eventually. Remember that the only values that *_find_destination* needs to return is the host and the node (*Compute*, and *Hypervisor*).
    
*nova.conductor.tasks.live_migrate_LiveMigrationTask._find_destination* ->
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
                #*#*# Sets host back to `None` in the event any of the above checks fail, this continues the loop while we schedule and try again.
                host = None
                
            return host, node
{% endhighlight %}

#### Exploration 16

The first method called here (*_check_compatible_with_source_hypervisor*) is quite short. This takes the host information of the source (stored in the class as *self.host*) and the destination (just *host*) and compares the versions of their platforms to see if there is compatability. Without compatability, an exception is triggered, which unsets the host and continues the loop. Interestingly, this method does return data in the form of the source info and destination info, however this information is not stored during the *_find_destination* call and is lost.
    
*nova.conductor.tasks.live_migrate_LiveMigrationTask._check_compatible_with_source_hypervisor* ->
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

#### Exploration 17
        
Now that I completed these simple but important checks, I execute the *_call_livem_checks_on_host*. This beefy call leads us into several other methods. Again, it's worth noting that anything returned here is lost. We are just looking to find an exception or to continue. We do, however, set the *class migrate_data* variable, which (as you may remember) was set to `None` during the class instantiation. This *migrate_data* is filled with the returned values from *compute_rpcapi.check_can_live_migrate_destination*. Remember that the RPC services left a message, in this case, for *compute*. I could trace this all the way through the *compute_rpcapi*, but we know now that it's going to end up in the Compute Manager. This means the code that runs here is going to run on the destination Compute node. Just like when a message was left for Conductor and a Conductor node picked it up, if we were to look into the scheduler calls, we'd find that a message has been left for them. This isn't critical to understanding the code, but it is good to know that, during this section, the code is run on the destination Compute node. Thus, we can skip some code here and go straight to *nova.compute.manager.method_called*.
    
*nova.conductor.tasks.live_migrate_LiveMigrationTask._call_livem_checks_on_host* ->
{% highlight python %}
    def _call_livem_checks_on_host():
        try:
            self.migrate_data = self.compute_rpcapi.
                check_can_live_migrate_destination(self.context, self.instance,
                    destination, self.block_migration, self.disk_over_commit)
        except
            raise exception.MigrationPreCheckError(msg)
{% endhighlight %}

#### Exploration 18
   
The execution is now at the compute manager on the destination, ready to run checks against the chosen destination, moving from Nova API manager to Conductor Manager to Destination Compute. This method is just a redirect (called by using RPC) into a private method.
    
*nova.compute.manager.check\_can\_live\_migrate\_destination* -> 
{% highlight python %}
    def check_can_live_migrate_destination():
            return self._do_check_can_live_migrate_destination(ctxt, instance,
                                                            block_migration,
                                                            disk_over_commit)
{% endhighlight %}
         
#### Exploration 19

Now I need to handle some setup here and to make a few returns to this code, so let's step through it. First, I set up some variables for the source and destination by using the host variables that were passed to us from Conductor. Interestingly, it pulls the Destination host from its own *CONF* file, since this code is actually running on the destination. Once that is done, the code is first passed over to *driver.check_can_live_migrate_destination*. It stores the returned data of this operation in *dest_check_data*. Because the driver is XenAPI, execution shifts there for now, and returns once the *dest_check_data* is filled in.
    
*nova.compute.manager._do_check_can_live_migrate_destination* ->
{% highlight python %}
    def _do_check_can_live_migrate_destination():
        src_compute_info = obj_base.obj_to_primitive(self._get_compute_info(ctxt, instance.host))
        dst_compute_info = obj_base.obj_to_primitive(self._get_compute_info(ctxt, CONF.host))
        dest_check_data = self.driver.check_can_live_migrate_destination(ctxt,
                                                    instance, src_compute_info, dst_compute_info,
                                                    block_migration, disk_over_commit)
{% endhighlight %}

#### Exploration 20

To find data in a driver, such as where that *check_can_live_migrate_destination* method lives, look in the *driver.py* file, which is similar to the routes for an API and tells us where to go. Let's take a look now, but I won't do this review in future explorations of the code. You can see from the imports that our new home is the *nova.virt.xenapi.vmops.check_can_live_migrate_destination* method. Remember, this is how you can find all calls to the *driver.call* methods. *From compute* is issuing commands directly to the driver that it controls by using its login credentials in the *Nova Conf* file.
    
*nova.virt.xenapi.driver.check\_can\_live\_migrate\_destination* ->
{% highlight python %}
    def check_can_live_migrate_destination():
        ...
        from nova.virt.xenapi import vmops
        self._vmops = vmops.VMOps(self._session, self.virtapi)
        ...
        return self._vmops.check_can_live_migrate_destination(context,instance,block_migration,disk_over_commit)
{% endhighlight %}

#### Exploration 21

The following method makes sure that the destination is ready for use. First, it creates a new object from the primitives, like we have seen before, and the returned *dest_check_data* is saved. It then handles some specific actions depending on whether or not `Block Migration` was specified. In this case, I did not specify block migration and said that I did not have shared storage. This lack of shared storage means that the *_ensure_host_in_aggregate* call fails. Thus, the block_migration is turned on and execution continues into the "if block_migration" code. See the inline comments in the following sample for more details.
    
*nova.virt.xenapi.vmops.check_can_live_migrate_destination* ->
{% highlight python %}
    def check_can_live_migrate_destination():
        dest_check_data = objects.XenapiLiveMigrateData()
        
        #*#*# We currently have our block_migration set to `None`, so we hit the if state, fail the try clause, and have our block_migration set to true.
        
        if block_migration is None:
            try:
                ...
                self._ensure_host_in_aggregate(ctxt, src)
                ...
            except exception.MigrationPreCheckError:
                block_migration = True

        #*#*# Note:  If we were on shared storage, we could have followed the above trail, which continues to set up some of the same data as the following, but this has been trimmed because it is irrelevant to us. We now have *block_migration* set, and we have filled in our *dest_check_data* with information. We set up the *block_migration*, *migrate_send_data*, *destination_sr_ref*, and a basic blank VIF mapping that contains the network UUID that XenAPI returns. Most of this is fairly simple to understand because we have been dealing with it for a while. The Network UUID call queries XenAPI for its network, and the *migrate_receive* call sets up a token and tells the destination to prepare itself to accept a migration. Let's take a closer look at these for our own deeper understanding. Once these are all set, the compute method version *_do_check_can_live_migrate_destination* continues. This quickly gets confusing soon after we realize this method does far more than just checking a destination.
        
        if block_migration:
            dest_check_data.block_migration = True
            dest_check_data.migrate_send_data = self._migrate_receive(ctxt)
            dest_check_data.destination_sr_ref = vm_utils.safe_find_sr(self._session)
            net_ref = self._get_network_ref()
            dest_check_data.vif_uuid_map = {'': net_ref}
        return dest_check_data
{% endhighlight %}

#### Exploration 22

In the following code, the *migrate_receive* call issues a warning through XenAPI. It sends XenAPI the *migrate_receive* command including the nw_ref, destination, and options details. These options can be `sr` references. Live migration, block migration, and xen returns a token. This token signifies that the server is ready to accept the connection over the nw_ref that you specified to the host that you specified with the parameters that you specified. This token is stored as the *dest_check_data.migrate_send_data* variable and is returned to Compute services *_do_check_can_live_migrate_destination* method.
    
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

#### Exploration 23

The inline comments from the code's author explain the following function pretty well. It just pulls the network reference for the management network. It's not a super important bit of code, but it does become more useful later. Additionally, the previous method uses this method as well, so it is useful to know what is happening.
    
*nova.virt.xenapi.vmops._get_network_ref* ->
{% highlight python %}   
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

#### Exploration 24

The execution now returns to the *_do_check_can_live_migrate_destination* call with a populated *dest_check_data* which importantly contains the *migrate_send_data* field. Let's do a quick review to remember what is happening. Notice that the method is suddenly no longer just checking a destination but also is checking a source. I set *migrate_data* to the result of *compute.manager.check_can_live_migrate_source (compute_rpcapi)*! More information is in the inline comments in the following code but notice that we are moving through *compute_rpcapi* when going to the source. This means that the code chunk runs on the source Compute node.
    
*nova.compute.manager._do_check_can_live_migrate_destination* ->
{% highlight python %}
    def _do_check_can_live_migrate_destination():
        src_compute_info = obj_base.obj_to_primitive(self._get_compute_info(ctxt, instance.host))
        dst_compute_info = obj_base.obj_to_primitive(self._get_compute_info(ctxt, CONF.host))
        dest_check_data = self.driver.check_can_live_migrate_destination(ctxt,                      (x)
                                                    instance, src_compute_info, dst_compute_info,   (x)
                                                    block_migration, disk_over_commit)              (x)
           
        #*#* Now that *dest_check_data* is populated, use this to run checks against the source. While this doesn't make a ton of sense within the destination check rather than happening, remember that not much data is returned to the conductor, so doing this while we still have the data is a little more streamlined. This method also runs a couple of methods deep, but once we complete we will return the migrate_data field that is generated here back to *conductor.tasks.live_migrate_LiveMigrationTask._call_livem_checks_on_host*, which stores the returned migrate data, is the class variable *self.migrate_data*.
        
        try:
            migrate_data = self.compute_rpcapi.check_can_live_migrate_source(ctxt, instance, dest_check_data)
        ...
        return migrate_data
{% endhighlight %}

#### Exploration 25

Just like before, I'm handing this over the XenAPI drivers to do the work, but first the process sets up some basic variables to send with it so that it gets a little easier for XenAPI.  This includes seeing if the server is volume-backed and getting basic block-device-mapping information. This information, however, does not contain Cinder target information (this will be important later for our XenAPI purposes). Once we have that, we move into the driver. The driver's outcome is stored as *result* and is then returned. This is a bit interesting because the name changes. Usually OpenStack keeps these things standard to avoid this kind of confusion. Just know that *result* is stored in *migrate_data*.
    
*nova.compute.manager.check_can_live_migrate_source* ->
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

#### Exploration 26

The primary focus of the following method is to run the XenAPI *assert_can_migrate* command. This command accepts mappings that are generated in the *_call_live_migrate_command* method, which is called and then just returns the untouched *dest_check_data*. More information is in inline comments.
    
*nova.virt.xenapi.vmops.check_can_live_migrate_source* ->
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
                
                #*#*# This checks for a `VDI NOT IN MAP` exception if the assert fails. Due to the organization of this code, if the server has volumes attached during the live migration and is running a newer version of XCP, the call fails because the SR is not set up on the destination yet, and we do not have the volume targets available to set them up. We swallow this exception.
                
                if ("VDI_NOT_IN_MAP" in reason and
                        host_sw['platform_name'] == "XCP" and
                        versionutils.is_compatible("2.1.0", host_pfv)):
                    LOG.debug("Skipping exception for XCP>=2.1.0, %s", reason)
                    return dest_check_data
        return dest_check_data
{% endhighlight %}

#### Exploration 27

The following method calls the XenAPI driver to run the specified command. This method is used twice during the *live_migration* process, once to run this assert, and again later to actually start the live migration process. The method generates maps for various resources to their owners. These maps are *Source Vif -> Destination Network* and *Source VDI -> Destination SR*. These maps could be used more intensively by the call (including such things as GPU and CPU maps), but I only use these two for my purposes. I send that data to the *call_xenapi* method, which calls the *assert_can_migrate* method with which I called this method, and, if any of these maps fail, the process fires an exception. Essentially, it is looking at these maps to ensure that everything exists properly and is ready to accept the migration. Some extraneous content is trimmed here for simplicity. Note that nothing is returned here. We are inside of the `try` block and just except or continue and return the *dest_check_data*.
    
*nova.virt.xenapi.vmops._call_live_migrate_command* ->
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

Assuming the assert did not fail, we move on and return *dest_check_data* from the driver's *check_can_live_migrate_source* operation. This rolls back to *compute.manager.check_can_live_migrate_source*, where the *result* is stored and we can see that *result* is just *dest_check_data* and has been un-modified.  *Result* (or *dest_check_data*) is returned to *_do_check_can_live_migrate_destination*, which then stores *result* (or *dest_check_data*) as *migrate_data* and returns it to the calling method.  

From here, we roll all the way back into *nova.conductor.tasks.live_migrate_LiveMigrationTask._call_livem_checks_on_host*, which orginally called *self.migrate_data = self.compute_rpcapi.check_can_live_migrate_destination*. Since this method returns nothing, we can roll all the way back to *_find_destination*! Now we have a class variable which just holds the *dest_check_data*, which is now called *migrate_data*.  This contains information such as the *block_migrate*, the dest information, and some other basics. We are all the way back to Conductor, and my checks against both the destination and source are complete.  Let's look at that code again as a refresher.
    
#### Exploration 28

We have completed both the *call_livem_checks_on_host* and the *_check_compatible_with_source_hypervisor* checks.  This means that I did not hit the except and that the host information is returned further back up the line.  We can now successfully head all the way back to the execute. Remember that there is now a class variable *self.migrate_data*, which is set with *dest_check_data*. Because the checks passed, the destination information from the scheduler is returned.
    
*nova.conductor.tasks.live_migrate_LiveMigrationTask._find_destination* ->
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
                #*#*# Sets host back to `None` in the event any of the above checks fail, this continues the loop while we schedule and try again.
                host = None
                
            return host, node
{% endhighlight %}

#### Exploration 29
    
We finally return to execute, and I've marked what we have already completed with an (X) in the following code.  We completed the destination find and now move on to finally run the *live_migration*. I set up some basic variables in the class migration option, including the source node, the destination node, and compute, which we got from scheduling. Now, I pass this to the *compute_rpc* service for the source by calling *self.compute_rpcapi.live_migration*. This is the end of the execution code for the live migration. These final steps occur on the compute node.
    
*nova.conductor.tasks.live_migrate_LiveMigrationTask._execute* ->
{% highlight python %}
    def _execute():
        self._check_instance_is_active()  (X)
        self._check_host_is_up(self.source) (X)
        ...
        if not self.destination:
            ...
            self.destination, dest_node = self._find_destination() (X)
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

Now we explore the Compute and Hypervisor controls.

#### Exploration 30

As always with these RPC calls, the action now moves into a private method. Some complex code here sets up an eventlet thread to run in the background. Because this process can take a long time, the background processing means that the RPC worker is not locked to this method while the private method runs.

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

#### Exploration 31

This is the beginning of the prep phase for the live migration proper. The migration status is set to `Preparing`, and because I'm running a block_migration, I gather details about the disk information and get basic BDM information again (remember, I discarded this information during the scheduling phase and only returned host details). I pull that very basic information and throw it into the *pre_live_migration* through *computeRPC* once again. I save the result of this as *migrate_data*.  Note here that I actually pass in the current *migrate_data*, which was the *dest_check_data*, so I'm overwriting that variable with the result of *pre_live_migration*. Let's look briefly into the *get disk info* method here for clarity. Once the *pre_live_migration* method finishes, we return to this method to continue. Note:  We are running through *ComputeRPC* here as we are traversing to the destination. I need to set up the destination to be ready now by attaching volumes, setting up networks, and creating filtering rules.
    
*nova.compute.manager._do_live_migration* ->
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

#### Exploration 32

This is a case where XenAPI actually doesn't implement this work, but it just passes the check, relying on this to be done later.
    
*nova.virt.xenapi.driver* ->
{% highlight python %}
    def driver():
        def get_instance_disk_info():
            pass
{% endhighlight %}

#### Exploration 33

This method handles a decent amount of complicated work. First, it pulls the more complete Block Device Mappings including the Cinder Target information. It then pulls networking information again, and it passes the data into the driver's version of this method to handle the work, finally passing the block device data that was generated. The result of this driver *pre_live_migration* call is saved as *migrate_data*. Once completed, execution moves on and sets up any needed networks on the host machine and sets up the filtering rules before returning *migrate_data*. The following code has been significantly trimmed for clarity. Notice that *migrate_data* is passed and overridden, and that the code is running on the destination.
    
*nova.compute.manager.pre_live_migration* ->
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

#### Exploration 34

The following fairly simple method just adds more data to the *migrate_data* object. The volumes are connected on the destination hypervisor by passing the bdm information that was gathered in the previous method into *connect_block_device_volumes*. This code delves deeply into Cinder, but we don't need to focus on this right now. Just know that they are attached now on the destination. The code also creates interim networks, and the SR Mapping and VIF mapping for both of these are stored in the *migrate_data* field.
    
*nova.virt.xenapi.vmops.pre\_live\_migration* ->
{% highlight python %}
    def pre_live_migration():
        migrate_data.sr_uuid_map = self.connect_block_device_volumes(bdms)
        migrate_data.vif_uuid_map = self.create_interim_networks(network_info)
        return migrate_data
{% endhighlight %}
 
There is now even more data in the *dest_check_data* (or *migrate_data*) field. The destination information is there now that networks have been set up, filtering rules are in place, volumes have been attached, and that modified *migrate_data* is passed all the way back to *nova.compute.manager._do_live_migration* on the source. Let's look back at where we left off.

#### Exploration 35

Now that the *pre_live_migration* method has completed, execution moves on, which leaves us just a status change away from a "running" status (YAY!) and into the driver's *live_migration* code. Nothing is returned from here, and it is just a `try:` and `except:` block execution. From here, the driver handles the rest of the process.
    
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

#### Exploration 36

The name of the following method actually changes a bit on the way into the driver for XenAPI, so it's just a little confusing. We are getting really close to the end here and have come a monumental distance in these code lines. Now, it's time for the driver to go ahead and start doing its thing. The method gathers some basic data once again, because often the needed data is not returned. The method then fills in even more data in *migrate_data* and issues the XenAPI Migrate command! This means that XenAPI begins the mirror, and the process is legitimately kicked off. This process handles getting the VM started on the destination, transferring the RAM states, and so on. This just leaves the OpenStack drivers to do the cleanup. More comments are inline in the following code. Once the long, long *migrate_send* command completes, the *post_method* executes.
    
*nova.virt.xenapi.vmops.live_migrate* ->
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
                
                    #*#*#*# We used this *_call_live_migrate_command* before to run our assert. We do the same thing here but to tell XenAPI to actually begin running the task. This officially means that the *live_migration* is running. The maps are again generated, and this time passed to the actual method. Running the assert before this step means that if these maps had a problem, they would have failed much earlier in the process to make the roll back easier. Now that networks are configured on the destination, volumes attached, and various other information has been pulled, it would have been a monumental waste of time to have mapping failure at this point.
                    
            post_method(context, instance, destination_hostname, 
                        block_migration, migrate_data)
 {% endhighlight %}                        
                        
The way that *post_method* is called is a bit interesting, because it is defined by the incoming variables accepted by the *self.driver.live_migration* method. You can see above that this is called with *self.post_live_migration* and *self._rollback_live_migration*. When a fault occurs, it calls that *recover_method*, and, in this case, it calls the *post_method*, which resolves to the *nova.compute.manager._post_live_migration* method. It is tempting to believe that this is the *nova.virt.xenapi.vmops.post_live_migration* method but remember that this data was sent from COMPUTE and not VIRT.  You can also see that the *post_live_migration* in XenAPI is *post_live_migration* and not *_post_live_migration*. So, let's take a look!

#### Exploration 37
   
Remember that the execution didn't move through RPC to get here, so the code is still running on the source. So far, execution was only transferred to RPC to handle the destination checks before bouncing back to source again. From now on, code runs on the source. The following method handles the cleanup actions that need to be done. It gathers BDM records (again!) and terminates and detaches the volumes from the source hypervisor, preparing to switch around networking information. This method gets very long, so we'll walk through it a little at a time and follow its cleanup steps where applicable. More comments are inline in the code.
    
*nova.compute.manager._post_live_migration* ->
{% highlight python %}
    def _post_live_migration():
        bdms = objects.BlockDeviceMappingList.get_by_instance_uuid()
        block_device_info = self._get_instance_block_device_info()
        
        #*#*# This method is fairly simple and just calls XenAPI to remove the Ramdisk files from the source
        #*#*# Since this data is no longer needed on the source, the code is essentially cleaning up.
        
        self.driver.post_live_migration() 

        #*#*# Pull the block devices again here and terminate the source connections
        
        connector = self.driver.get_volume_connector(instance)
        for bdm in bdms:
            if bdm.is_volume:
                if bdm.attachment_id is None:
                    self.volume_api.terminate_connection()
                else:
                    old_attachment_id = migrate_data.old_vol_attachment_ids[]
                    self.volume_api.attachment_delete(ctxt, old_attachment_id)

        #*#*#  The Networking API is a bit out of the scope for this article. Here filters placed on the instance VIFS are removed. In many instances, both of these just pass to continue, but this depends greatly on the networking API and Firewall API in use. Xenserver will often use NOOP firewall which passes, and neutron additionally passes here.
        
        network_info = self.network_api.get_instance_nw_info(ctxt, instance)
        self.driver.unfilter_instance()
        migration = {'source_compute': self.host, 'dest_compute': dest}
        self.network_api.migrate_instance_start(instance, migration)
        
        destroy_vifs = False
        try:
            self.driver.post_live_migration_at_source() -->
{% endhighlight %}           

#### Exploration 38
      
In the following code, the vif connections for the VM on the source are deleted, effectively stopping any connectivity to the source. This traverses two methods, so let's take a look at both. The first method just calls  *_delete_networks_and_bridges*. This method then calls the vif_driver to call *delete_network_and_bridge*. Kind of a long way around to get to the work, but you can see the *vif_driver* defined here as well.
    
*nova.virt.xenapi.post\_live\_migration\_at\_source* ->
{% highlight python %}
    def post_live_migration_at_source():
        self._delete_networks_and_bridges(instance, network_info)
 {% endhighlight %}
 
*nova.virt.xenapi._delete_networks_and_bridges* ->
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
 
Looking at a sample *nova.conf*, notice what that *CONF.xenserver.vif_driver* value is. Depending on the type of networking used (OpenVSwitch, Linux Bridges, and so on), this leads to different classes. Let's use OVS, for example.
    
    grep "vif_driver" /etc/nova/nova.conf 
    vif_driver = nova.virt.xenapi.vif.XenAPIOpenVswitchDriver

#### Exploration 39
      
Now let's look at *nova.virt.xenapi.vif.XenAPIOpenVswitchDriver.delete_network_and_bridge*. This method is very intense and again out of our scope, but feel free to look at this code on your own.  It destroys the OVS port bindings for the bridge, vif, and patch ports, and tears down the rest of the environment for routing to this VIF. Now that's done, let's look back at the Compute *post_live_migration* with a bit more code trimming. We will mark where left off with (X) in the following code.
    
Past the (X), you can see that now some cleanup is being handled on the destination. Notice that it passes through compute RPC now.  As you might expect, destination cleanup runs on the destination. Note that even if this fails, the line of code does not fail.  On an except, we set a variable that it failed and move on. This does cause the process to fail completely, but the code ensures that things are cleaned up in the proper order instead of just crashing.
    
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

#### Exploration 40
     
The following is another beefcake of a method, which handles actions on the destination but also reaches out to the source to tear even more information down. I added more inline so that we can keep our (read: my) thoughts straight.
    
*nova.compute.manager.post_live_migration_at_destination* ->
{% highlight python %}
    def post_live_migration_at_destination():
        *#*#* This is the second time these two methods are run because of some issues with Linux Bridges. Let's not follow this code line as it delves again into the neutron codebase. This sets up the linux bridges, OVS, etc on the destination to start handling the traffic for the VM.
        self.network_api.setup_networks_on_host()
        self.network_api.migrate_instance_finish()

        ...
        
        #*#*# We pull BDMS again, and we pass that data to the XenAPI driver for running its own *post_live_migration_at_destination*.
        #*#*# Without digging too deeply into the XenAPI call, this sets up rules on the VIF to actually block all traffic.  This is because Security Groups
        #*#*# have not been installed yet, so to avoid unwanted possible traffic, it kills everything temporarily.
        
        network_info = self.network_api.get_instance_nw_info(context, instance)
        block_device_info = self._get_instance_block_device_info(context,
                                                                 instance)
        try:
            self.driver.post_live_migration_at_destination()
        except Exception:
            EXCEPT
        
        
        #*#*# Now, update the instance details in the database to reflect the new destination host is live, ensure 
        #*#*# the power state is started, remove the *task_state* from the VM (almost done here!), and call the
        #*#*# networks API again to tear down the networks one last time on the source and set them up on the destination.
        #*#*# This process also removes the rule we just placed to block all traffic.
        
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

#### Exploration 41
           
Now we can return to *_post_live_migration* again, with more trimmed down psuedocode in the following sample to see where we left off marked with an (X).
    
The prevoius process essentially completed the migration. As far as the database is concerned, the task_state is empty, so this thing is no longer running. The instance points to the new host in the database, and *instance.host* = *self.host* (set from the destination). The remainder of the code is handling the last of the cleanup and ending the process completely. Comments are inline.
    
*nova.compute.manager._post_live_migration* ->
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
        
        #*#*#*  This calls the Driver Cleanup. XenAPI just passes on this as the work was handled by the *live_migration* process issued from XenAPI.
        
        do_cleanup, destroy_disks = self._live_migration_cleanup_flags()
        if do_cleanup:
            self.driver.cleanup()

        ...
        ...
        
        #*#*# Earlier, we set some statistical information such as allocations, usage information, and scheduler information, however this is non-vital for this walk-through. In this next code block, the actual migration status record in the database is set to complete. Once this is done, a couple more allocations are handled, and the code line dead ends. The live migration is done. The server is active, and hosts have changed. The destination is cleaned up, and the migration record is `completed`.

        if migrate_data and migrate_data.obj_attr_is_set('migration'):
            migrate_data.migration.status = 'completed'
            migrate_data.migration.save()
            migration = migrate_data.migration
        ...
 {% endhighlight %}
        
### Conclusion

We have now completed the full trace through the live migration process, while also taking some time to look at and understand how the RPC services are used to communicate back and forth between services. We started out in the Nova API service and quickly bounced between Compute API, Conductor, Scheduler, Destination and Source Compute and Hypervisor, Neutron, and many others. While some of these were a bit too difficult to cover in this article, you can use this same logic of moving through the code piece by piece to investigate any process, failure, or stack trace that you may receive. I encourage readers to use this information to dive deeper into the codebase to explore areas that interest them and that we did not cover. For example, within the Scheduler codebase, OpenStack uses interesting "Abstract Base Classes" (to handle scheduling efforts) and some very complicated and confusing rules that can be fun to explore. Neutron itself is a complicated beast, and understanding it better can be very valuable.

Please remember here however that this was not written by a professional writer or developer, but just a Racker with a passion for Openstack.  I hope you've enjoyed this code dive and gained some knowledge, and hopefully I'll return soon with a new process to explore!
