---
layout: post
title: 'Life Without DevStack: OpenStack Development With OSA'
date: '2015-10-26 10:00'
comments: true
author: Miguel Grinberg
published: true
categories:
  - openstack
  - osad
  - ansible
  - database
  - architecture
---

If you are an OpenStack contributor, you likely rely on DevStack for most of
your work. DevStack is, and has been for a long time, the de-facto platform
that contributors use for development, testing, and reviews. In this article, I
want to introduce you to a project I'm a contributor to, called
[openstack-ansible](https://github.com/openstack/openstack-ansible). For the
last few months, I have been using this project as an alternative to DevStack
for OpenStack upstream development, and the experience has been very positive.

<!-- more -->

What’s Wrong with DevStack?
---------------------------

Before I delve into openstack-ansible, I want to briefly discuss the reasons
that motivated me to look for an alternative to DevStack. Overall, DevStack is
a well rounded project, but there are a couple of architectural decisions that
bother me.

First of all, DevStack comes with a monolithic installer. To perform an
install, you run `stack.sh` and that installs all the modules you configured.
If you later want to add or remove modules, the only option is to run
`unstack.sh` to uninstall everything, and then re-run `stack.sh` with the
updated configuration. A few times, when I made source
code changes to a module, I inadvertently caused the module to operate in an
erratic way. If I'm in that situation, the safest option is to reinstall it,
and the only way to do that with DevStack is to reinstall everything.

DevStack performs a development
installation of all the modules, which creates an environment that is very
different from production deployments. In my opinion, a proper development
environment would have the module I'm working on installed for development,
with everything else installed for production. This is not possible to do with
DevStack.

Another problem I used to have with DevStack is the constant fight to keep
dependencies in a consistent state. In DevStack, dependencies are shared among
all the modules, so a simple action of syncing the dependencies for one module
may cause a chain reaction that requires updating several other modules. To
some extent, this can be alleviated in recent DevStack releases with the use of
per-module virtual environments, but, even with that, OS level packages remain
shared.

What is openstack-ansible (OSA)?
--------------------------------

The [openstack-ansible](https://github.com/openstack/openstack-ansible) project
is a Rackspace open source initiative that uses the power of
[Ansible](https://www.ansible.com/) to deploy OpenStack. You may have
heard of this project with the name *os-ansible-deployment* on StackForge
before it moved to the OpenStack big tent.

Like DevStack, openstack-ansible deploys all the OpenStack services directly
from their git repositories, without any vendor patches or add-ons. But the big
difference is that openstack-ansible deploys the OpenStack services in [LXC
containers](https://linuxcontainers.org/lxc/introduction/), so there is
complete OS level and Python package isolation between the services hosted on a
node.

Another difference between DevStack and openstack-ansible is that the latter
is a production distribution. With it, you can deploy enterprise scale private
clouds that range from a handful nodes to large cluster with hundreds or even
thousands of nodes.

The following diagram shows the structure of an openstack-ansible private
cloud:

{% img center 2015-10-26-life-without-devstack-openstack-development-with-osa/osa-arch.jpg "openstack-ansible architecture" %}

After looking at this, you are probably scratching your head thinking how can
this project match the simplicity of DevStack for upstream development, given
that it is clearly oriented to multi-node private clouds. Do not despair! I
cover this in the next section.

OSA All-In-One
--------------

The openstack-ansible project contributors
use a single-node deployment for day-to-day work and for gating, because that is
much more convenient and resource efficient. With this method of deployment it
is possible to stand up OSA on a cloud server or virtual machine, so taking
advantage of this feature makes this project comparable to DevStack.

Unfortunately, the host requirements for a single-node deployment of OSA are
higher than DevStack, mainly due to the overhead introduced by the container
infrastructure. For a usable installation, the host must have 16GB of RAM and
80GB of disk space. At this time, the only host OS that is supported is Ubuntu
14.04.

One nice advantage that OSA has over DevStack is that, thanks to the
containerized architecture, it can deploy redundant services even on a
single-node install. On a default single-node deployment, galera, rabbitmq, and
keystone are deployed with redundancy, and HAProxy is installed in the host to
do the load balancing.

Are you ready to get your hands dirty? If you have access to a fresh Ubuntu
14.04 server that meets the specs mentioned above, you can clone the OSA
repository with the following commands:

    # apt-get -y install git
    # git clone https://github.com/openstack/openstack-ansible /opt/openstack-ansible

You do not need to clone the project to this directory. Instead, you can clone
it anywhere you like.

Next, generate a single-node configuration file. Luckily, the
project comes with a script that does that for you:

    # cd /opt/openstack-ansible
    # scripts/bootstrap-aio.sh

After the above command runs, the directory */etc/openstack_deploy* will be
populated with several configuration files in [YAML](https://yaml.org/) format.
Of particular interest is file *user_secrets.yml*, which contains all the
passwords that will be used in your installation. These passwords are randomly
generated, so they are hard to remember. I typically edit the admin password,
because I use it a lot. Basically I change this:

    keystone_auth_admin_password: cY3QHwjMLRdSuZMlKI3OvujScCNeIMdH

to this:

    keystone_auth_admin_password: secrete

The remaining passwords are not that useful, so I leave them
alone. However, you can change any password you think you may need to use to
something that is easy to remember.

Next, run another script that installs Ansible in the host, plus
a few Ansible extras and wrapper scripts that simplify its use:

    # scripts/bootstrap-ansible.sh

At this point, the host is ready to receive the OSA install, so
run the Ansible playbooks that carry out the installation:

    # scripts/run-playbooks.sh

On a Rackspace Public Cloud server, a full run through all the playbooks takes
about 45 minutes to complete. One nice aspect of working with Ansible is that
all the tasks are idempotent, meaning that the playbooks can be executed
multiple times without causing any problem. If a task has already been
performed, running it a second time does nothing. This is actually
very useful, as it makes it possible to re-configure a live system simply by
changing the appropriate configuration files and re-running the playbooks,
without the need to tear everything down first.

A Quick Tour of openstack-ansible
---------------------------------

In this section, I want to give you an overview of the OSA single-node
structure, so that those of you that were brave enough to stand one
up know where everything is.

First of all, the Horizon dashboard is deployed and should be accessible on the
public IP address of the host. You can use the *admin* account, with the
password that you entered in the */etc/openstack_deploy/user_secrets.yml* file.
If you did not edit this file, you have to open this file and locate the
`keystone_auth_admin_password` setting to find out what password was used.

As I mentioned above, the servers are all installed in LXC containers. The
following command shows you the list of containers:

    root@miguel-lxc-server:~# lxc-ls -f
    NAME                                          STATE    IPV4                                        IPV6  AUTOSTART
    --------------------------------------------------------------------------------------------------------------------------------
    aio1_ceilometer_api_container-c8e825de        RUNNING  10.0.3.203, 172.29.237.195                  -     YES (onboot, openstack)
    aio1_ceilometer_collector_container-2da3371f  RUNNING  10.0.3.10, 172.29.238.178                   -     YES (onboot, openstack)
    aio1_cinder_api_container-88e59c04            RUNNING  10.0.3.125, 172.29.238.106, 172.29.247.183  -     YES (onboot, openstack)
    aio1_cinder_scheduler_container-69d2bec4      RUNNING  10.0.3.4, 172.29.239.79                     -     YES (onboot, openstack)
    aio1_galera_container-2f36d624                RUNNING  10.0.3.95, 172.29.237.18                    -     YES (onboot, openstack)
    aio1_galera_container-3b8e14d7                RUNNING  10.0.3.18, 172.29.237.166                   -     YES (onboot, openstack)
    aio1_galera_container-618973ae                RUNNING  10.0.3.82, 172.29.238.189                   -     YES (onboot, openstack)
    aio1_glance_container-4b41140f                RUNNING  10.0.3.21, 172.29.237.77, 172.29.246.233    -     YES (onboot, openstack)
    aio1_heat_apis_container-40ec9f3e             RUNNING  10.0.3.193, 172.29.239.6                    -     YES (onboot, openstack)
    aio1_heat_engine_container-36e270c9           RUNNING  10.0.3.171, 172.29.239.171                  -     YES (onboot, openstack)
    aio1_horizon_container-3497588e               RUNNING  10.0.3.33, 172.29.239.114                   -     YES (onboot, openstack)
    aio1_horizon_container-6cac5348               RUNNING  10.0.3.30, 172.29.238.168                   -     YES (onboot, openstack)
    aio1_keystone_container-821e7cf8              RUNNING  10.0.3.38, 172.29.238.105                   -     YES (onboot, openstack)
    aio1_keystone_container-d63c657e              RUNNING  10.0.3.69, 172.29.239.208                   -     YES (onboot, openstack)
    aio1_memcached_container-8baf34d5             RUNNING  10.0.3.158, 172.29.237.135                  -     YES (onboot, openstack)
    aio1_neutron_agents_container-21b819b7        RUNNING  10.0.3.233, 172.29.239.130, 172.29.240.182  -     YES (onboot, openstack)
    aio1_neutron_server_container-b4279bbe        RUNNING  10.0.3.52, 172.29.239.216                   -     YES (onboot, openstack)
    aio1_nova_api_metadata_container-79faf41a     RUNNING  10.0.3.60, 172.29.239.110                   -     YES (onboot, openstack)
    aio1_nova_api_os_compute_container-fed67563   RUNNING  10.0.3.231, 172.29.239.17                   -     YES (onboot, openstack)
    aio1_nova_cert_container-72f66c56             RUNNING  10.0.3.155, 172.29.237.152                  -     YES (onboot, openstack)
    aio1_nova_conductor_container-7d0f1b0f        RUNNING  10.0.3.164, 172.29.239.144                  -     YES (onboot, openstack)
    aio1_nova_console_container-62af2918          RUNNING  10.0.3.106, 172.29.238.236                  -     YES (onboot, openstack)
    aio1_nova_scheduler_container-e6b79b3b        RUNNING  10.0.3.250, 172.29.236.153                  -     YES (onboot, openstack)
    aio1_rabbit_mq_container-0e0fe308             RUNNING  10.0.3.86, 172.29.239.93                    -     YES (onboot, openstack)
    aio1_rabbit_mq_container-a4a04124             RUNNING  10.0.3.253, 172.29.237.188                  -     YES (onboot, openstack)
    aio1_rabbit_mq_container-b9c6dce6             RUNNING  10.0.3.22, 172.29.238.111                   -     YES (onboot, openstack)
    aio1_repo_container-6a8377fc                  RUNNING  10.0.3.102, 172.29.237.47                   -     YES (onboot, openstack)
    aio1_repo_container-b92c563a                  RUNNING  10.0.3.223, 172.29.239.251                  -     YES (onboot, openstack)
    aio1_rsyslog_container-a6e4f7d4               RUNNING  10.0.3.170, 172.29.237.249                  -     YES (onboot, openstack)
    aio1_swift_proxy_container-9f0130d3           RUNNING  10.0.3.20, 172.29.237.227, 172.29.247.52    -     YES (onboot, openstack)
    aio1_utility_container-d83fab91               RUNNING  10.0.3.39, 172.29.237.161                   -     YES (onboot, openstack)

By going through this list, you can see what services were deployed. You can
get inside a container using the `lxc-attach` command. A particularly
interesting container is the one with the *utility* name at the bottom of the
list. To enter this container this is the command that you should use:

    # lxc-attach -n aio1_utility_container-d83fab91

The utility container is useful because it has all the OpenStack command line
clients installed, plus a ready to go *openrc* file for the admin account.
In the following example session, I use the `openstack` utility to
query the list of users in my deployment:

    root@miguel-lxc-server:~# lxc-attach -n aio1_utility_container-d83fab91
    root@aio1_utility_container-d83fab91:~# source openrc
    root@aio1_utility_container-d83fab91:~# openstack user list
    +----------------------------------+--------------------+
    | ID                               | Name               |
    +----------------------------------+--------------------+
    | 2257ddc66d4c41ba8500114944cbb852 | dispersion         |
    | 22f1824610b34eb2a6cfaba09b8feb93 | ceilometer         |
    | 271f9bd069b2440ebb27c8f460bb3bcf | neutron            |
    | 2ecb372f6563410ab8138625c45a72e3 | heat               |
    | 35a7c9373ff640c4ba768963c1f53f02 | keystone           |
    | 37041c2377c44f5cb84ffafee5bfed6f | cinder             |
    | 4b7f43c7c2cc443889cd6b5d90a30e49 | glance             |
    | 6ee6a4abb7e64b3d801f2653efb9c9ec | swift              |
    | 9b375e06cb0a481a8ed2f94e28e1cb39 | nova               |
    | b2b90c7eed704c63bbc8ea0eb23f43c4 | admin              |
    | bd3eed1e0cf54b93a0d7c6a7849be778 | stack_domain_admin |
    +----------------------------------+--------------------+

To exit the container and return to the host, type `exit` or hit
Ctrl-D.

Here is another nice feature of Ansible: it allows you to
reinstall a service, like one that got corrupted during development by
mistake. To do this, simply destroy the affected container:

    # lxc-stop -n <container-name>
    # lxc-destroy -n <container-name>

After the sick container is destroyed, running the playbooks one more time will
cause a fresh one to be made as a replacement, in a fraction of the time it
would take to install everything from scratch.

Development Workflow
--------------------

You surely want to know how I use an OSA all-in-one deployment as a replacement
for DevStack, in practical terms. The process involves a few simple steps:

1. Deploy OSA-AIO

    Obviously, everything starts with deploying a single-node openstack-ansible
    cloud. I normally use a Rackspace Public Cloud server as my host, but you can use any
    Ubuntu 14.04 host with the specs I listed above.

2. Attach to the target container

    I then go inside the container that runs the service I want to work on,
    using the `lxc-attach` command I showed above. If I'm going to work on a
    service that was deployed with redundancy, I first edit the HAProxy
    configuration to leave only one container active. The remaining containers
    can be used as backups if something goes wrong with the selected one.

3. Stop the target service

    The container is running a production version of the service I intend to
    work on. Because this service is of no use to me, I stop it by using
    the standard `service <name> stop` command. For example,
    if I'm in the heat-engine container, I would run `service heat-engine
    stop`.

4. Clone development version

    Now I have a container that is prepared to run the target service, so I can
    clone the actual code I will be working with. For this, I might use the
    official git repository, my fork with custom changes, or maybe a patch
    from Gerrit, if I'm doing a review.

5. Update dependencies

    The development version might require a different set of dependencies than
    the version that was installed by the Ansible playbooks, so, for safety, I
    run `pip install -r requirements.txt` in the container. Since OSA creates
    its own private Python package repository, a required version of a
    package might not be available in it. When that happens, I set `no-index = False`
    in the container's */root/.pip/pip.conf* file to enable access to pypi, and
    then try again.

6. Sync database

    Another possible difference between the original version installed
    with OSA and my development version is in database migrations, so I always
    sync the database, just in case. The command to do this varies slightly
    between services, but it usually requires invoking the management script
    with the `db_sync` option. For example, when working with Keystone, the
    command to sync the database is `keystone-manage db_sync`

7. Make changes to the original config files, if necessary

    The playbooks create configuration files for all the services, so, in most
    cases, the configuration that was left in the */etc* directory by the
    installer can be used without changes for development. If I need to make
    any custom changes related to my work, I make them manually with a text
    editor.

8. Run manually, or install and run as a service

    Finally, the development version can be started. To do that easily,
    just run the Python application directly. For example, if I'm working
    on the heat-engine service, I can run `bin/heat-engine` from the root
    directory of the project to start the service in the foreground, with logs
    going out to the terminal. To stop the service, I can hit Ctrl-C, just like
    it's done in DevStack.

    Terminal friendly debuggers, such as pdb (command line) or pudb
    (interactive), can be installed inside containers and work great. Remote
    debugging over ssh from the host to the container is also possible, if you
    prefer to use more complex debuggers such as PyCharm.

    For most services, running them manually is enough to work as comfortably as
    with DevStack. The only exception is for services that do not run Python
    scripts directly, such as Keystone, which normally runs under Apache. Even
    though Apache is used in production, for development it is perfectly safe
    to run the Python application directly, which will likely run an eventlet
    based web server. If for any reason using Apache is desired, then the
    alternative is to install the development version by running `python
    setup.py install` and then restart the already installed Apache service
    with `service apache2 restart`. It is also possible to run the application
    from its source directory by installing it with `python setup.py develop`
    and then adding the home directory to the Apache site configuration file.

OSA-AIO: The Pros
-----------------

Working with OSA in place of DevStack has been a mostly pleasant experience for
me. Not having dependency conflicts anymore is great, because with OSA, if I
need to rebase one of the services and that requires new dependencies, the
other services are unaffected in their own containers.

I have also found I rarely need to recreate the whole deployment from scratch.
I usually do that when I want to upgrade the entire system to a new release of
OpenStack, but, for day to day work, I find it easy to do local updates or
repairs to an existing installation. I like being able to destroy a container
and then have Ansible regenerate it for me without touching the rest of the
services.

Finally, I really like that OSA allows me to choose what part of the system I
install as development packages, while keeping the rest of the OpenStack cloud
installed and configured for production use.

OSA-AIO: The Cons
-----------------

But of course, as is the case with everything, there are some aspects of
working with OSA that are not great, so I want to give you that side of the
story as well.

OSA is a young project, and, as such, it does not have the wide support of the
community that DevStack enjoys. This is particularly important if you work on
modules that are not at the core of OpenStack. At the time I'm writing this,
OSA supports the deployment of Keystone, Nova, Neutron, Glance, Cinder, Swift,
Heat, Ceilometer and Horizon. If you want to work on a module not included in
this list, then OSA is probably not that useful to you. But on the other side,
if you want to create an Ansible playbook for a module currently not supported,
you will be received with open arms.

In general, there are a fair number of configuration options exposed as Ansible
variables for all modules, with one exception. When it comes to Neutron,
configuration is not as flexible. Network tunnels across containers and VMs are
always configured to use Linux Bridge. For example, if you need to work with
Open vSwitch, you'll need to manually modify the configuration after running
the playbooks, which is not fun. Also, none of the Neutron plugins are
supported at this time.

Conclusion
----------

I hope you find my workflow with openstack-ansible interesting to learn and
use. It has saved me time when working on Heat upstream features and
bug fixes. I have also heavily relied on OSA to debug and troubleshoot Keystone
federation.

If you are interested in using OSA, I also encourage you to do a little bit of
searching, as that will lead you to more articles and blog posts (such as
[this one](https://developer.rackspace.com/blog/reviewing-patches-with-os-ansible-deployment/)
or [this other one](https://mechanicalcat.net/richard/log/OpenStack)), in which
other OpenStack contributors explain how they incorporated OSA into their own
workflows.
