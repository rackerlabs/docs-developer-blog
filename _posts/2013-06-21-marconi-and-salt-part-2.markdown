---
layout: post
title: 'Marconi and Salt: Part 2'
date: '2013-06-21 09:51'
comments: true
author: Oz Akan
published: true
categories:
  - OpenStack
---
In the [first article][1] we configured salt-master and created a Cloud Server. In this article we will start building up the Marconi environment and while doing so shape what our salt configuration will look like. 

We have two goals in mind. First, we have to be capable of creating several Marconi environments with little effort. As an example, we should have servers under dev, test and production environments managed under one configuration. Taking it a step further, we may have these in different locations. So having the ability to managing multiple environments is essential. Second, we will try to build generic configurations (SLS Formulas) that we can use for different projects. For example, we could have a generic firewall formula that will set proper iptables rules on Linux servers based on the role and environment they are in.<!-- more -->

##Setup Environments

We will start with setting up environments for Marconi by editing the `/etc/salt/master` configuration file which is read by the `salt-master` process during the initialization. Open the file and search for `file_roots`:

	root@salt01:~# emacs /etc/salt/master
	...
	# Example:
	# file_roots:
	#   base:
	#     - /srv/salt/
	#   dev:
	#     - /srv/salt/dev/services
	#     - /srv/salt/dev/states
	#   prod:
	#     - /srv/salt/prod/services
	#     - /srv/salt/prod/states
	...

The three periods are just to indicate that I clipped the file.

As in the file above, Salt uses YAML by default to format several files. [Here][2], you can find more information on YAML.

These directories indicate where state files are located for each environment. States are stored in text files on the master and transferred to the minions via the master's file server. We will change this section as seen below:

	root@salt01:~# emacs /etc/salt/master
	... 
	file_roots:
	  base:
	    - /srv/salt/base
	  marconi-base:
	    - /srv/salt/marconi/base
	  marconi-preview-ord:
	    - /srv/salt/marconi/preview-ord
	    - /srv/salt/marconi/base
	...

Above we defined three environments. The first is the `base` environment, which is the default. If no environment is specified, the `base` environment will be used. The second line after `base` indicates where the files are located for the `base` environment. So, by looking at the configuration above, we know that they are under `/srv/salt/base`. Here, all we do is define a root directory for a file server that `salt-master` will serve. Environment name and directory location is matched by Salt. When you refer to the `base` environment, Salt will serve the files from the `/srv/salt/base` directory. It is that simple. `salt-master` is a fast file server, powered by ZeroMQ.

The second environment is `marconi-base`. Here we will have all Marconi-related configuration files.

The third environment is `marconi-preview-ord`. I decided to name the environments that are not `base` for others as project-environment-location. Marconi is the project, preview is the environment and ORD (Chicago) is the location of the data center where we will provision our cloud servers. Similarly, for production environment in Sydney it could be `marconi-prod-syd`.

In `marconi-preview-ord` we have two directory definitions. `salt-master` supports directory overlay, which means a file is searched in the first directory and if it is not found it is searched in the second one. There can be more than two directories and prioritization is done in the order they are listed. This is an essential feature as we will use it to create new environments by only maintaining the files that have to be different in each environment and using everything else from the `marconi-base` environment.

Apart from states, Salt has an interface called "pillar." The pillar interface is one of the most important components of a Salt deployment. pillar is the interface used to generate arbitrary data for specific minions. The data generated in pillar is made available to almost every component of Salt and is used for a number of purposes like highly sensitive data, minion configurations, variables and arbitrary data. For more on pillar see [docs.saltstack.org][3].

We need to change the pillar configuration for Marconi as well. On the same file `/etc/salt/master`, this time search for `pillar_roots` and change it as seen below:

	root@salt01:~# emacs /etc/salt/master
	...
	pillar_roots:
	  base:
	    - /srv/salt/base/pillar
	  marconi-base:
	    - /srv/salt/marconi/base/pillar
	  marconi-preview-ord:
	    - /srv/salt/marconi/preview-ord/pillar
	    - /srv/salt/marconi/base/pillar
	...

After doing so, we need to restart salt-master.

	root@salt01:~# service salt-master restart
	salt-master stop/waiting
	salt-master start/running, process 26433

From now on, salt-master will look in the directories we indicated.

##Create Marconi Web Server

Marconi uses uWSGI and has several dependencies. Configuring a web server means installing all required packages, putting configuration files in place and starting services. Let’s create our first Marconi web server with salt-cloud. I will use the definitions we mentioned in the [first article][1].

	root@salt01:~# salt-cloud -p marconi-test-1GB marconi-pre-web-01
	... a few pages of logs..
	[INFO    ] Salt installed on marconi-pre-web-01
	[INFO    ] Created Cloud VM 'marconi-pre-web-01'
	marconi-pre-web-01:
	    ----------
	    _uuid:
	        None
	    driver:
	    extra:
	        ----------
	        created:
	            2013-06-19T14:58:51Z
	        flavorId:
	            3
	        hostId:

	        imageId:
	            b3ed73ef-b922-4b61-bb4d-472bb52e6326
	        key_name:
	            None
	        metadata:
	            ----------
	        password:
	            k3j67iiWJHEd
	        tenantId:
	            806067
	        updated:
	            2013-06-19T14:58:54Z
	        uri:
	            https://ord.servers.api.rackspacecloud.com/v2/806067/servers/8473b61a-fa99-4385-b86e-b6fd891a997a
	    id:
	        8473b61a-fa99-4385-b86e-b6fd891a997a
	    image:
	        None
	    name:
	        marconi-pre-web-01
	    private_ips:
	        - 10.178.192.108
	    public_ips:
	        - 162.209.50.219
	        - 2001:4801:7820:0076:53f3:b724:ff10:c4c8
	    size:
	        None
	    state:
	        3

The server is ready. Let’s ping.

	root@salt01:~# salt marconi-pre-web-01 test.ping
	marconi-pre-web-01:
	    True

##Set Grains

We can identify which server to ping by server ID. Even better, we can identify a server by the project, environment and location information so we can match the servers with the environments defined in Salt. We will use grains for this. 

Grains are static bits of information about the server populated when the minion first starts. There is a good amount of information about the server initially and we can query this as shown below:

    root@salt01:~# salt marconi-pre-web-01 grains.items
    marconi-pre-web-01:
    cpu_flags: fpu de tsc msr pae cx8 cmov pat clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt lm up rep_good nopl pni pclmulqdq ssse3 fma cx16 sse4_1 sse4_2 popcnt aes f16c hypervisor lahf_lm cmp_legacy extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch xop fma4 tce tbm perfctr_core arat cpb hw_pstate
    cpu_model: AMD Opteron(tm) Processor 4332 HE
    cpuarch: x86_64
    defaultencoding: None
    defaultlanguage: None
    domain:
    fqdn: marconi-pre-web-01
    gpus:
    host: marconi-pre-web-01
    id: marconi-pre-web-01
    ipv4:
        10.178.192.108
        127.0.0.1
        162.209.50.219
    kernel: Linux
    kernelrelease: 3.5.0-31-generic
    localhost: marconi-pre-web-01
    lsb_codename: quantal
    lsb_description: Ubuntu 12.10
    lsb_id: Ubuntu
    lsb_release: 12.10
    master: 162.209.15.12
    mem_total: 991
    nodename: marconi-pre-web-01
    num_cpus: 1
    num_gpus: 0
    os: Ubuntu
    os_family: Debian
    oscodename: quantal
    osfullname: Ubuntu
    osrelease: 12.10
    path: /usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
    ps: ps -efH
    pythonpath:
        /usr/bin
        /usr/lib/python2.7
        /usr/lib/python2.7/plat-linux2
        /usr/lib/python2.7/lib-tk
        /usr/lib/python2.7/lib-old
        /usr/lib/python2.7/lib-dynload
        /usr/local/lib/python2.7/dist-packages
        /usr/lib/python2.7/dist-packages
        /usr/lib/pymodules/python2.7
    pythonversion: 2.7.3.final.0
    saltpath: /usr/lib/pymodules/python2.7/salt
    saltversion: 0.15.3
    server_id: 263703182
    shell: /bin/sh
    virtual: xen
    virtual_subtype: Xen PV DomU

Let’s add project, environment and location grains.

    root@salt01:~# salt marconi-pre-web-01 grains.setval project marconi
    marconi-pre-web-01:
      project: marconi
    root@salt01:~# salt marconi-pre-web-01 grains.setval environment preview
    marconi-pre-web-01:
      environment: preview
    root@salt01:~# salt marconi-pre-web-01 grains.setval location ord
    marconi-pre-web-01:
      location: ord

Let’s see if grains are set properly.

    root@salt01:~# salt marconi-pre-web-01 grains.item project environment location
    marconi-pre-web-01:
      environment: preview
      location: ord
      project: marconi

Now, we can query our server for the project Marconi that is in preview in ord data center.

    root@salt01:~# salt -C "G@project:marconi and G@environment:preview and G@location:ord" test.ping
    marconi-pre-web-01:
        True

For more about targeting with grains you can check [this page][4].

##Setup Roles

Salt doesn't define a role by default. Still, it is pretty easy to use grains as a way of defining roles. I think of a role as a set of packages (and related configuration files) that can be installed on a server independent of other roles and packages. A server can both serve a web site and a database so it can have both Apache and MySQL installed. In this case, we could say, this server has `web_server` and `database` roles. Or we could go further and define roles like `apache_server`, `mysql_server`, `postgre_server`, `ftp_server` etc. I tend not to have a role defined at single package level if its configuration is specific to the project or is affected by other services in the environment.

The Marconi web server is going to have a set of packages that defines only a web server for the Marconi project. We won't be trying to make it generic; instead this is the `web_server` role only for Marconi. As a good start, let's set roles in grain for our web server.

    root@salt01:~# salt marconi-pre-web-01 grains.setval roles ['web_server']
    marconi-pre-web-01:
      roles:
          web_server

Since a server may have multiple roles, we defined roles as an array.

##Salt States (SLS)

Salt uses state files to define which state a server should be in. There are several state modules already present in Salt. These modules let you install packages, modify hosts file, change IP addresses, manage cron jobs, mount file systems and several perform several other functions. You can find a complete list of built-in state modules [here][5].

##First SLS Example: Install NTP

We will start with installing the NTP service on the web server. We will create this file (SLS Formula) under file server root for `marconi-base`.

    root@salt01:~# mkdir -p /srv/salt/marconi/base
    root@salt01:~# touch /srv/salt/marconi/base/ntp.sls

Content of the file will be like below:
  
    root@salt01:~# emacs /srv/salt/marconi/base/ntp.sls
    ntp-package:
    pkg:
      - name: ntp
      - installed

In the `ntp.sls` file above, the first line is free text. The second, indented line, indicates which Salt state module to call with the parameters that are provided in the file. Here Salt will call the pkg module, which then will call the proper package management tool to install the package indicated in the line that has `name: ntp`. The last line means that this package is going to be installed. (More about pkg state module can be found [here][6]). Instead of installed, we could write “removed” and Salt would ensure that package is removed from the server.

A shorter version of the `ntp.sls` file is below:

    ntp:
      pkg.installed

Now, we will run this state for our server.

    root@salt01:~# salt marconi-pre-web-01 state.sls ntp
    marconi-pre-web-01:
      Data failed to compile:
      ----------
      No matching sls found for 'ntp' in env 'base'

First about the output: As we didn't provide `marconi-preview-ord` as environment, Salt looked for base environment that is configured to be under `/srv/salt/base`. Obviously, there is no `ntp.sls` file there.

Salt is a command line tool that talks to salt-master to take actions. The first parameter above is the name of the server. The second parameter (`state.sls`) indicates that Salt will call the sls function of the [state module][7]. The last parameter tells the sls function which state module to run. In our example it is the ntp formula that we created. 

Let's run the same command with the correct environment.

    root@salt01:~# salt marconi-pre-web-01 state.sls ntp marconi-preview-ord
    marconi-pre-web-01:
    ----------
        State: - pkg
        Name:      ntp
        Function:  installed
            Result:    True
            Comment:   The following packages were installed/updated: ntp.
            Changes:   libcap2: { new : 1:2.22-1ubuntu4
    old :
    }
                       ntp: { new : 1:4.2.6.p3+dfsg-1ubuntu5
    old :
    }
                       libopts25: { new : 1:5.12-0.1ubuntu2
    old :
    }

When we create a module, we have two options. We can create it as a single file, like we did, so it will look like:

    /srv/salt/marconi/base/ntp.sls

Or we can create a directory named sls and create a file named `init.sls` in it, which will look like:

    /srv/salt/marconi/base/ntp/init.sls

The commands below behave exactly the same way:

    root@salt01:~# salt marconi-pre-web-01 state.sls ntp marconi-preview-ord
    root@salt01:~# salt marconi-pre-web-01 state.sls ntp.init marconi-preview-ord

Soon we will see when it makes sense to create a directory and place sls files but before, let’s ensure ntp is running as a service. So edit ntp.sls as below:

    ntp-package:
      pkg:
        - name: ntp
        - installed

    ntp-service:
      service:
        - name: ntp
        - running
        - enable: True
        - require:
          - pkg: ntp-package

Here under ntp-service we used the state module named [service][8]. At the very end you can see that it required ntp-package to be installed. If we haven't used a name parameter and tried to do something below, Salt would fail to find the proper requirement because both the package and service would have the same name.

    ntp:
      pkg.installed

    ntp:
      service:
        - running
        - enable: True
        - require:
          - pkg: ntp

Actually, there is much better way to achieve the same goal. Check the code below, where we use pkg and service state modules under the same definition.

    ntp:
      pkg:        
       - installed
    service:
      - running
      - enable: True
      - require:
        - pkg: ntp

Let's run ntp state again

    root@salt01:~# salt marconi-pre-web-01 state.sls ntp marconi-preview-ord
    marconi-pre-web-01:
    ----------
        State: - pkg
        Name:      ntp
        Function:  installed
            Result:    True
            Comment:   Package ntp is already installed
            Changes:
    ----------
        State: - service
        Name:      ntp
        Function:  running
            Result:    True
            Comment:   Service ntp is already enabled, and is in the desired state
            Changes:

Let's verify it ntp is really running by running an actual Linux command

    root@salt01:~# salt marconi-pre-web-01 cmd.run 'ps -fe|grep ntpd'
    marconi-pre-web-01:
        ntp       7450     1  0 16:02 ?        00:00:00 /usr/sbin/ntpd -p /var/run/ntpd.pid -g -u 106:113

##Second SLS Example: Passwordless SSH from Master to Minions

It is convenient to have passwordless SSH from master to minions during the development phases. You can login to the server after it is created, check the configuration files to be sure they are created as planned, etc. As this configuration has no dependencies, we will place it under base environment and thereafter will use it on any server. Considering that there might be other configurations or packages we want to install by default, we will create a directory named “common” and place related sls files under it.

    root@salt01:~# mkdir /srv/salt/base/common

Create `ssh_auth.sls` file:

    root@salt01:~# touch /srv/salt/base/common/ssh_auth.sls

Content of the file will look like:

    salt-master:
      ssh_auth:
        - present
        - user: root
        - source: salt://common/files/salt-master.id_rsa.pub

Here we use the `ssh_auth` state module and provide `salt-master.id_rsa.pub` as the source file, which has the public key for the root user. `salt://` is a file server that has environments root directory as the root directory so we can think of it as:

    salt://common/files/salt-master.id_rsa.pub => /srv/salt/base/common/files/salt-master.id_rsa.pub

This means we need to create the files directory and place id_rsa file there.

    root@salt01:~# mkdir /srv/salt/base/common/files
    root@salt01:~# cp ~/.ssh/id_rsa.pub /srv/salt/base/common/files/salt-master.id_rsa.pub

Now, let’s run this SLS formula without providing the environment so Salt will use base as the environment.

    root@salt01:~# salt marconi-pre-web-01 state.sls common.ssh_auth
    marconi-pre-web-01:
    ----------
        State: - ssh_auth
        Name:      salt-master
        Function:  present
            Result:    True
            Comment:   The authorized host key salt-master for user root was added
            Changes:   salt-master: New

Let’s find the IP address of `marconi-pre-web-01` and connect to see if it worked.

    root@salt01:~# salt marconi-pre-web-01 network.ip_addrs eth1
    marconi-pre-web-01:
        - 10.178.192.108

    root@salt01:~# ssh 10.178.192.108
    The authenticity of host '10.178.192.108 (10.171.191.101)' can't be established.
    ECDSA key fingerprint is 88:r6:e1:dd:14:51:4b:bb:51:21:2b:aa:42:21:c9:bd.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added '10.178.192.108' (ECDSA) to the list of known hosts.
    Welcome to Ubuntu 12.10 (GNU/Linux 3.5.0-31-generic x86_64)

    Last login: Wed Jun 19 22:07:13 2013 from 161.109.115.12
    root@marconi-pre-web-01:~#

A better way to run all SLS files under a common directory is by creating an `init.sls` file that includes all other sls files under the directory. In a way "common" is the name of the module and all other files are the functions of the common module. `init` is the one that is called by default.

    root@salt01:~# touch /srv/salt/base/common/init.sls

Content of the file:

    include:
      - common.ssh_auth

Let’s run our common SLS formula without calling the function, so Salt will use init (common.init) by default.

    root@salt01:~#  salt marconi-pre-web-01 state.sls common
    marconi-pre-web-01:
    ----------
        State: - ssh_auth
        Name:      salt-master
        Function:  present
            Result:    True
            Comment:   The authorized host key salt-master is already present for user root
            Changes:

##Salt State Layers

The Salt state system has several layers that are described in detail [here][9]. Within the scope of this article, we are interested in SLS, highstate and overstate layers.
The SLS layer is what we executed in the previous example. It will run a set of SLS files. It is practical to use while developing new SLS modules.

    root@salt01:~# salt marconi-pre-web-01 state.sls ntp marconi-preview-ord  

The highstate layer is used when one or many servers needs to be in a desired state, where we will probably have several different SLS files in action. (It will make more sense later when we reach to a complexity that can demonstrate the need for highstate.) For now just check the command below:

    root@salt01:~# salt '*' state.highstate

To be able to run highstate in our environment we need to have `top.sls` file.

##top.sls and highstate

You may want to have a look at these pages about [top.sls][10] and [highstate][11] before moving on. These are important concepts and must be understood well.
There are two top.sls files that Salt looks for. These have to be in base environment. In other words, they have to be under the directories we configured for base environment in `/etc/salt/master` under `files_roots` and `pillar_roots` sections.

Salt checks `top.sls` to figure out which configuration files apply to which environments. Let's configure these for `base` and `marconi-preview-ord` environments.

Create `top.sls` for states:

    root@salt01:~# touch /srv/salt/base/top.sls

With this content:

    root@salt01:~# emacs /srv/salt/base/top.sls
    base:
      '*':
        - common

    marconi-preview-ord:
      'G@project:marconi and G@environment:preview and G@location:ord':
        - match: compound
        - ntp    

Create `top.sls` for pillar:

    root@salt01:~# touch /srv/salt/base/pillar/top.sls

With this content:

    root@salt01:~# emacs /srv/salt/base/pillar/top.sls
    base:
      '*':
        - common

    marconi-preview-ord:
      'G@project:marconi and G@environment:preview and G@location:ord':
        - match: compound
        - environment

At this point, we have `/srv/salt/marconi/base/ntp.sls` and `/srv/salt/base/common/init.sls` but not `/srv/salt/base/pillar/environment.sls` and `/srv/salt/marconi/base/pillar/environment.sls` files. It won't be a problem to run highstate without pillar files. We will create these files later, but for now let's run highstate.

    root@salt01:~# salt marconi-pre-web-01 state.highstate
    marconi-pre-web-01:
    ----------
        State: - pkg
        Name:      ntp
        Function:  installed
            Result:    True
            Comment:   Package ntp is already installed
            Changes:
    ----------
        State: - service
        Name:      ntp
        Function:  running
            Result:    True
            Comment:   Service ntp is already enabled, and is in the desired state
            Changes:
    ----------
        State: - ssh_auth
        Name:      salt-master
        Function:  present
            Result:    True
            Comment:   The authorized host key salt-master is already present for user root

When we run the `state.highstate` function, Salt reads `top.sls` file under the `base` environment. For each environment listed in the `top.sls` file, it checks if the minion that is to execute the state tree matches the target. In our `top.sls` file, the first environment is the `base` environment:

    base:
      '*':
        - common

Here any minion ID that matches '*' glob is going to execute common module. Our server `marconi-pre-web-01` matches '*' (like any ID would) so we see that `ssh_auth` (common.ssh_auth) is executed. The second environment in `top.sls` is `marconi-preview-ord`:

    marconi-preview-ord:
      'G@project:marconi and G@environment:preview and G@location:ord':
        - match: compound
        - ntp

Here we used a [compound matcher][12]. Because of the grains we set earlier, marconi-pre-web-01 matches this compound matcher and eventually runs the ntp module which installs the ntp package and starts the ntp service.

There is one important note here: remember `file_roots` configuration for `marconi-preview-ord` environment:

    marconi-preview-ord:
        - /srv/salt/marconi/preview-ord
        - /srv/salt/marconi/base

We created `ntp.sls` under `/srv/salt/marconi/base` directory. So salt-master initially looked for `ntp.sls` file in the `/srv/salt/marconi/preview-ord` directory and couldn't find it there. Then it found the file under `base` and executed the contents. This is called an overlay mechanism, and we will use it for all environments.

##Wrapping Up Base Formulas

In the `base` environment we will have two more packages and the configuration looks like this:

    root@salt01:~# emacs /srv/salt/base/common/packages.sls
    emacs:
      pkg:
        - installed

    screen:
      pkg:
        - installed

    /root/.emacs:
      file:
        - managed
        - source: salt://common/files/emacs.config
        - require:
          - pkg: emacs

Create emacs configuration file:

    root@salt01:~# emacs /srv/salt/base/common/files/emacs.config
    (setq backup-directory-alist
              `((".*" . ,temporary-file-directory)))
        (setq auto-save-file-name-transforms
              `((".*" ,temporary-file-directory t)))

    (setq-default indent-tabs-mode nil)
    (setq-default tab-width 4)
    (setq indent-line-function 'insert-tab)

Modify `init.sls` under the common directory:

    root@salt01:~# emacs /srv/salt/base/common/init.sls
    include:
      - common.ssh_auth
      - common.packages

Let's run highstate again:

    root@salt01:~# salt marconi-pre-web-01 state.highstate
    marconi-pre-web-01:
    ----------
        State: - pkg
        Name:      emacs
        Function:  installed
            Result:    True
            Comment:   The following packages were installed/updated: emacs.
            Changes:   mail-reader: { new : 1
    old : 
    }
    ...
                       libfontconfig1: { new : 2.10.1-0ubuntu3
    old :
    }

    ----------
        State: - file
        Name:      /root/.emacs
        Function:  managed
            Result:    True
            Comment:   File /root/.emacs updated
            Changes:   diff: New file
    ----------
        State: - pkg
        Name:      ntp
        Function:  installed
            Result:    True
            Comment:   Package ntp is already installed
            Changes:
    ----------
        State: - pkg
        Name:      screen
        Function:  installed
            Result:    True
            Comment:   Package screen is already installed
            Changes:
    ----------
        State: - service
        Name:      ntp
        Function:  running
            Result:    True
            Comment:   Service ntp is already enabled, and is in the desired state
            Changes:
    ----------
        State: - ssh_auth
        Name:      salt-master
        Function:  present
            Result:    True
            Comment:   The authorized host key salt-master is already present for user root
            Changes:

From the output we can see that emacs and screen are installed and the emacs configuration file is copied from salt-master to minion (marconi-pre-web-01).

##Conclusion

In this article, we went over a few primary Salt terms like environments, grains, state files and state layers. We also defined roles and environments for Marconi using grains and matched servers with environments using compound matchers.

In the following article, we will start using pillar data and configure Marconi specific services like MongoDB servers with replica sets and web servers running uWSGI.
Until then, if you have questions, you can find me at [Twitter][13] or at [Google+][14]. Comments on this page are welcome as well.

[1]: https://developer.rackspace.com/blog/marconi-and-salt.html
[2]: http://en.wikipedia.org/wiki/YAML
[3]: http://docs.saltstack.com/topics/tutorials/pillar.html
[4]: http://docs.saltstack.com/topics/targeting/grains.html
[5]: http://docs.saltstack.com/ref/states/all/index.html
[6]: http://docs.saltstack.com/ref/states/all/salt.states.pkg.html
[7]: http://docs.saltstack.com/ref/modules/all/salt.modules.state.html
[8]: http://docs.saltstack.com/ref/states/all/salt.states.service.html
[9]: http://docs.saltstack.com/ref/states/layers.html
[10]: http://docs.saltstack.com/ref/states/top.html
[11]: http://docs.saltstack.com/ref/states/highstate.html
[12]: http://docs.saltstack.com/topics/targeting/compound.html
[13]: https://twitter.com/ozgurakan
[14]: https://plus.google.com/110684487860941982359
