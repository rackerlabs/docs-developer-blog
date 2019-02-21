---
layout: post
title: 'OpenStack OSAD and Nagios, against the world'
date: '2015-07-02 13:00'
comments: true
author: Walter Bentley
published: true
categories:
  - Private Cloud
  - OSAD
  - OpenStack
  - Ansible
---

Through the course of technology, infrastructure and application monitoring have changed positions.  Not so long ago, monitoring was an afterthought when rolling out your new application or standing up your new rack of servers.  More recently, I have observed monitoring to be one of the first considerations, to the point where it is actually in the initial project plan.

This evolution, while late in my mind, is the right direction…not just for the System Admin who gets the 2AM email alert or the application owner who on a monthly basis sadly report to his leadership 97% SLA on his app.  Truly knowing how your application is affecting your infrastructure is one of the keys to a successful cloud.

With monitoring now being in an elevated position, that then leaves you to think: what should I use for monitoring?  While there are plenty of software solutions in the market, many of which solve for different problems.

<!-- more -->

Your choice should be made around the following thoughts:

   * Keep it simple
   * Keep your monitoring close to your infrastructure
   * Create good monitors

To keep it simple, you can't do better than by going with [Nagios](http://www.nagios.com/products) Core.  Yes, while it may not be the flashiest dashboard visually, it is one of the most powerful and lightweight monitoring applications I have used.  With Nagios, you have ultimate control on many aspects of your monitoring ecosystem, ranging from being able to create custom plugins, all the way to explicitly defining execution windows for that host.  Administration can be handled directly from the flat files, or you can use many of the third party tools, such as [NConf](http://exchange.nagios.org/directory/Addons/Configuration/NConf/details).  With the launch of the new versions, XI, more and more of the features only found in the third party tools are built right in.  Some of the new features that stand out would be the advanced graphs, integration into Incident management tools, and cleaner SLA reports.

Of course, with great capability comes great overhead, sometimes.  Typically, I have found that keeping your monitoring close to your infrastructure avoids limiting what you are monitoring due to firewall restrictions and so on.  I strongly recommend using SNMP (UDP port 161), rather than the NRPE agent.  No agent install needed.  Also, I normally stick with Perl written plugins to ease troubleshooting.  Creating ‘good’ monitors is essential to minimize false alerts, that in time turn to ignored alerts.  If you find a service check continuously sending off false alerts, FIX IT!  Do not let it linger for days.

Because of the power behind OpenStack exposing all functionality thru APIs, monitoring is made easy.  Custom plugin scripts can be created to monitor the whole OpenStack stack and to cross reference any bottlenecks to physical infrastructure problems.  This type of proactive monitoring can lead to preventing down time, which lead to outages.

OpenStack monitoring consists of:

   * Monitoring the physical hardware (base resource consumption)
   * Monitoring the OpenStack API endpoints
   * Monitoring the OpenStack services processes
   * Monitoring your Compute nodes via your Infrastructure nodes

Since I have such a deep-seated love for OSAD (OpenStack Ansible Deployment) used and created by Rackspace, it seemed only fitting to put together a series of Ansible playbooks to handle most of the Nagios and NConf process.  Also, because I love to pay it forward, I included are OSAD-focused Nagios configs (checkcommands, services and a bunch of global Nagios configs), which can be used to monitor your OpenStack OSAD cloud within minutes.

Base prerequisites are:

* OpenStack OSAD cloud (technically, the Nagios configs can work against any OpenStack deployment with tweaks; playbooks tested against v10.6)
* Monitoring server to run Nagios and NConf

Let’s get started!  Early disclaimer, the steps below will take some time and
should not be rushed.

### Step 1: Clone repo

Connect via SSH to the node used to deploy your OSAD cloud (most likely is the
first Infrastructure node).  Within the root home directory, clone the following
repo to pull down the roles that you need.

	 $ git clone --recursive https://github.com/wbentley15/nagios-openstack.git

### Step 2: Examine roles and populate variables

Take a look at the roles, and familiarize yourself with the steps. Find below all the variables for which you will need to supply values. The variable files are located in the **group_vars** directory.  The **all_containers** and **hosts** files are meant to be identical, so please supply the same variables below for both.

- `USER`: user to be created on the OSAD nodes to match up against the default Nagios user created. The default user is 'nagios'
- `SNMP_COMMUNITY`: the SNMP community string used for the OSAD nodes and containers
- `SYS_LOCATION`: additional SNMP information (optional)
- `SYS_CONTACT`: additional SNMP information (optional)

The variables needed for the nagios-server variable file are:

- `DB_NAME`: name of the NConf database to be created
- `DB_USER`: root user for the local mysql server
- `DB_PASS`: root user password for the local mysql server

### Step 2b: Add the IP address of the Nagios server

Add the IP address of the Nagios server to the **hosts** file in the root of the playbook directory.

### Step 3: Move the playbooks and roles into the OSAD deployment directory

In order to leverage the dynamic inventory capabilities that come with OSAD, the playbooks and roles need to be local to the deployment directory.  Trust me, you will like this!

	 $ cd ~/nagios-openstack
	 $ mkdir /opt/os-ansible-deployment/rpc_deployment/playbooks/groups_vars
	 $ cp ~/nagios-openstack/group_vars/* /opt/os-ansible-deployment/rpc_deployment/playbooks/group_vars
	 $ cp -r ~/nagios-openstack/roles/* /opt/os-ansible-deployment/rpc_deployment/roles
	 $ cp ~/nagios-openstack/base* /opt/os-ansible-deployment/rpc_deployment/playbooks
	 $ cp ~/nagios-openstack/hosts /opt/os-ansible-deployment/rpc_deployment/playbooks

### Step 4: Execute the following playbook to install and configure SNMP on your OSAD cloud:

	 $ cd /opt/os-ansible-deployment/rpc_deployment/
    $ ansible-playbook -i inventory/dynamic_inventory.py playbooks/base.yml

In the event the SNMP service does not start the first time, please execute the following commands:

	 $ ansible all_containers -m shell -a "service snmpd start"
	 $ ansible hosts -m shell -a "service snmpd start"

### Step 5: Execute the following playbook to install and configure Nagios onto your monitoring server:

    $ cd playbooks
    $ ansible-playbook -i hosts base-nagios.yml

Then connect to the monitoring server via SSH and execute the following commands to set the `nagiosadmin` user password (used to log into Nagios web dashboard) and to restart Nagios:

	 $ sudo htpasswd -c /etc/nagios3/htpasswd.users nagiosadmin
    $ service nagios3 restart

### Step 6: Execute the following playbook to install and configure NConf onto your monitoring server:

    $ ansible-playbook -i hosts base-nconf.yml

### Step 6b: NConf initial configuration

My attempt to automate this part was not successful, so you have to finish the NConf configuration using the NConf web console.  Browse to `http://<monitoring server IP>/nconf` and follow the prompts to complete the initial configuration.  I suggest using the following inputs and keeping the defaults for the others:

- `DBNAME`: same as what you inputed in the variables file above
- `DBUSER`: same as what you inputed in the variables file above
- `DBPASS`: same as what you inputed in the variables file above
- `NCONFDIR`: /var/www/html/nconf
- `NAGIOS_BIN`: /usr/sbin/nagios3

### Step 6c: Execute the post NConf playbook:

	 ansible-playbook -i hosts post-nconf-install.yml

### Step 7: Execute the following playbook to configure the OSAD nodes to allow for monitoring via SSH:

In order to monitor the OpenStack processes and APIs running on the local containers, you must run the service checks remotely over SSH.  Good news is the Nagios plugin to do this already exists (`check_by_ssh`).

    $ cd ..
    $ ansible-playbook -i inventory/dynamic_inventory.py playbooks/base-infra.yml


### Step 7b: Confirm the Nagios and NConf install:

In a browser go to the following URLs:

-	http://<monitoring server IP>/nagios3
-	http://<monitoring server IP>/nconf


### Step 8: Time to configure Nagios for monitoring OSAD:

Unfortunately, this part does require manual configuration as each installation will differ too much to automate.  In the big picture, this will just help you sharpen your Nagios skills.  Do not worry, a copy of the Nagios directory was already taken. This step will take some time and should not be rushed.

First step here would be to customize the Nagios configuration files located in the **/etc/nagios3/rpc-nagios-configs** directory on your monitoring server.  All the configuration files are important but, the most critical ones are the advanced_services.cfg and hosts.cfg files.

Within the **advanced_services.cfg** file, you will need to update each service check with the IP addresses of the containers within your OSAD install.  The fastest way to get that information is to execute the following command and capture the output on each Infrastructure node:  `lxc-ls --fancy`.  Below is an example:

	 define service {
    	 service_description          infra1_check_ssh_process_glance-api
         check_command                check_by_ssh_process!<glance container IP>!glance-api
         check_period                 24x7
         notification_period          24x7
         host_name                    <OSAD node name>
         contact_groups               +admins,rpc-openstack-support
         use                          rpc-service
	 }

Same goes for the **hosts.cfg** file.  Please update the OSAD node names and IP addresses.

	 define host {
         host_name                     <OSAD node name>
         address                       <OSAD node IP>
         icon_image_alt                Ubuntu 14.04
         icon_image                    base/ubuntu.gif
         statusmap_image               base/ubuntu.gd2
         check_command                 check-host-alive
         check_period                  24x7
         notification_period           24x7
         contact_groups                +admins,rpc-openstack-support
         use                           rpc-node
	  }

Please also add the following to the bottom of the **resources.cfg** file located in the root of the Nagios directory (**/etc/nagios3**):

	 $USER10$=<random SNMP community string of your choice, keep it simple>

If you are having trouble making the updates to the configs using an editor, do not stress out as the next step will make this process a bit easier.

### Step 9: Import Nagios configuration into NConf:

Next, append the contents of the configuration files in the **/etc/nagios3/rpc-nagios-configs** directory to current Nagios configuration files (add to bottom).  Every host, host group, check, service, and contact group is uniquely named so that they don't conflict with current Nagios setup.  Then we will step thru the instructions found on the [NConf website](http://www.nconf.org/dokuwiki/doku.php?id=nconf:help:how_tos:import:import_nagios).

As the NConf tutorial suggests, first run the commands with the `-s` parameters to simulate the import process.  Once you're able to run with no errors, remove the '-s' parameter to do the final import.  Connect to the monitoring server via SSH, run the following commands:

	 $ cd /var/www/html/nconf
	 $ bin/add_items_from_nagios.pl -c timeperiod -f /path/to/timeperiods.cfg -s
	 $ bin/add_items_from_nagios.pl -c misccommand -f /path/to/misccommands.cfg -s
	 $ bin/add_items_from_nagios.pl -c checkcommand -f /path/to/checkcommands.cfg -s
	 $ bin/add_items_from_nagios.pl -c contact -f /path/to/contacts.cfg -s
	 $ bin/add_items_from_nagios.pl -c contactgroup -f /path/to/contactgroups.cfg -s
	 $ bin/add_items_from_nagios.pl -c host-template -f /path/to/host_templates.cfg -s
    $ bin/add_items_from_nagios.pl -c service-template -f /path/to/service_templates.cfg -s
	 $ bin/add_items_from_nagios.pl -c hostgroup -f /path/to/hostgroups.cfg -s
	 $ bin/add_items_from_nagios.pl -c host -f /path/to/hosts.cfg -s
	 $ bin/add_items_from_nagios.pl -c advanced-service -f /path/to/advanced-services.cfg -s

Now your can edit all the Nagios configs within the NConf web console.

### Step 10: Execute the post Nagios playbook:

	 $ cd playbooks
    $ ansible-playbook -i hosts post-nagios-install.yml

### Step 11: Generate your first Nagios config:

Once you are satisfied with all of your custom Nagios configs (trust me, you will do this a couple of times), click on the **Generate Nagios config** link on the sidebar of the NConf web console.  It will note if any errors were encountered.  From time to time, you will see warnings, but they are just that warnings, nothing urgent.

Last and not least, from the monitoring server, execute the following command to deploy the Nagios configurations to Nagios (may need to use sudo):

	 $ cd /var/www/html/nconf/ADD-ONS
	 $ ./deploy_local.sh

### Last thought

If you wanted to get fancy you can follow the instructions found on the [digitalcardboard blog](http://digitalcardboard.com/blog/2010/08/24/nagios-and-nconf-on-ubuntu-10-04-lucid-lynx) under the **Configuring NConf to Deploy Nagios Configurations Automatically** section.

**Go check out your work in Nagios now!**