---
layout: post
title: Run OpenStack Keystone and Horizon using Nginx
date: 2015-10-01 00:02
comments: true
author: Phil Hopkins
published: true
categories:
    - OpenStack
    - OSAD
    - NGINX
authorIsRacker: true
---

In my previous series of articles about installing [OpenStack from source](https://developer.rackspace.com/blog/install-openstack-from-source/), we installed keystone as a standalone application. This technique has been deprecated in the Kilo release in favor of running the keystone server, as a web server gateway interface (wsgi) service behind the Apache server. This allows for each Apache thread to start its own separate keystone thread. Example configuration files are available in the httpd directory in the cloned keystone repo. This article is a how to setup both keystone and the horizon dashboard to run under Nginx.

<!-- more -->

All work is to be performed on the controller node that was built in the previous article. This procedure can be easily adapted to almost any other Linux environment running keystone and horizon. 
 

First, stop the running keystone and apache services:

    service apache2 stop
    service keystone stop

Install the nginx server and other required packages:

    apt-get install -y nginx libgd-tools nginx-doc
    
Apache uses wsgi, however nginx has no direct wsgi support, instead there are several projects that bring wsgi functionality to nginx. Of these, the uwsgi python package is used, so use pip to install it. 

    pip install uwsgi
    
Since Ubuntu usually starts services when the package is installed, stop the nginx service until we get it configured:

    service nginx stop

Since keystone and horizon run behind the uwsgi service, delete the upstart scripts for both keystone and horizon so they don't get started for some reason:

    rm /etc/init/horizon.conf
    rm /etc/init/keystone.conf
    
We are not running a simple web server, so disable the default site that comes with the nginx install:
    
    rm /etc/nginx/sites-enabled/default
    
Make a log directory for keystone under nginx, and set the proper permissions:
    
    mkdir /var/log/nginx/keystone
    chown www-data:www-data /var/log/nginx/keystone/
    
and a base directory for the keystone wsgi python script:

    mkdir /var/www/keystone
    
Keystone comes with a python script for interfacing to servers running a wsgi interface. Keystone listens on two tcp ports, one for processing admin level requests and one for requests that don't need admin level permissions. Copy it over into the web directory for nginx. One copy is used to handle requests that need the keystone admin role and the other is for non-admin requests.

    cp keystone/httpd/keystone.py /var/www/keystone/admin
    cp keystone/httpd/keystone.py /var/www/keystone/main
    chown -R www-data:www-data /var/www/keystone
    chmod ug+x /var/www/keystone/*

    mkdir /etc/uwsgi

Ubuntu runs the Nginx server in the www-data group. The following command adds the keystone users as an additional member of this group. By doing this, we allow for proper resource access between the web server and keystone.

    usermod -G www-data keystone
    
uwsgi has a broad set of configuration parameters. We are only going to set a minimum number of values to get this configuration running. You need to read the uwsgi documentation to ensure proper security is set up and the best performance values are selected for your environment. We set uwsgi to run 10 processes with 2 threads per process. The keystone process runs as the keystone user and the www-data group. The following creates the needed uwsgi configuration file for running keystone admin requests:

    cat >> /etc/uwsgi/keystone-admin.ini << EOF
    [uwsgi]
    master = true  
    processes = 10  
    threads = 2  
    chmod-socket = 666
    
    socket = /run/uwsgi/keystone-admin.socket  
    pidfile = /run/uwsgi/keystone-admin.pid  
    log-syslog = '[keystone-admin]'
    
    name = keystone
    uid = keystone
    gid = www-data
    
    chdir = /var/www/keystone/  
    wsgi-file = /var/www/keystone/admin
    
    EOF
    
Next create the needed uwsgi configuration file for running keystone non-admin requests:
    
    cat >> /etc/uwsgi/keystone-main.ini << EOF
    [uwsgi]
    master = true  
    processes = 4  
    threads = 2  
    chmod-socket = 666
    
    socket = /run/uwsgi/keystone-main.socket  
    pidfile = /run/uwsgi/keystone-main.pid  
    
    name = keystone
    uid = keystone
    gid = www-data
    
    log-syslog = '[keystone-main]'
    
    chdir = /var/www/keystone/  
    wsgi-file = /var/www/keystone/main
    EOF

Create the needed uwsgi configuration file for running horizon:
    
    cat >> /etc/uwsgi/horizon.ini << EOF
    [uwsgi]
    master = true  
    processes = 10  
    threads = 2  
    chmod-socket = 666
    
    socket = /run/uwsgi/horizon.sock  
    pidfile = /run/uwsgi/horizon.pid  
    log-syslog = '[horizon]'
    
    name = horizon
    uid = horizon
    gid = horizon
    
    chdir = /etc/openstack_dashboard/  
    env = DJANGO_SETTINGS_MODULE=openstack_dashboard.settings  
    module = django.core.handlers.wsgi:WSGIHandler() 
    EOF

Create an upstart script to start the uwsgi service. Since we have multiple applications running we are using uwsgi's emperor mode:

    cat >> /etc/init/uwsgi.conf << EOF
    description "uwsgi for nginx keystone admin"
    
    
    start on runlevel [2345]
    stop on runlevel [!2345]
    
    respawn
    
    pre-start script
      if [ ! -d /run/uwsgi ]; then
          mkdir /run/uwsgi/
          chown keystone:horizon /run/uwsgi
          chmod 775 /run/uwsgi
      fi
    end script
    
    post-stop script
      if [ -d /run/uwsgi ]; then
         rm -r /run/uwsgi
      fi
    end script
    
    exec /usr/local/bin/uwsgi --master --emperor /etc/uwsgi
    EOF
    
Create the configuration file keystone, remember that keystone listens on ports 5000 for normal requests and 35357 for admin requests, so we will need server entries for each port in nginx:
    
    cat >> /etc/nginx/sites-available/keystone.conf << EOF
    server {
            listen          5000;
            access_log /var/log/nginx/keystone/access.log;
            error_log /var/log/nginx/keystone/error.log;
    
            location / {
                uwsgi_pass      unix:///run/uwsgi/keystone-main.socket;
                include         uwsgi_params;
                uwsgi_param      SCRIPT_NAME   admin;
             }
    }
    server {
            listen          35357;
            access_log /var/log/nginx/keystone/access.log;
            error_log /var/log/nginx/keystone/error.log;
    
            location / {
                uwsgi_pass      unix:///run/uwsgi/keystone-admin.socket;
                include         uwsgi_params;
                uwsgi_param      SCRIPT_NAME   admin;
    
           }
    }
    EOF
 
And finally create the configuration file for nginx and horizon:
    
    cat >> /etc/nginx/sites-available/horizon.conf << EOF
    server {  
        listen 80;
        server_name openstack.foo.com;
    
        location / { try_files  \$uri @horizon; }
        location @horizon {
            include uwsgi_params;
            uwsgi_pass unix:/run/uwsgi/horizon.sock;
        }
        location /static {
          alias /usr/local/lib/python2.7/dist-packages/static;
        }
    }
    EOF
    
   
Enable both the keystone and horizon functions (sites) in nginx:
    
    ln -s /etc/nginx/sites-available/keystone.conf /etc/nginx/sites-enabled/keystone.conf
    ln -s /etc/nginx/sites-available/horizon.conf /etc/nginx/sites-enabled/horizon.conf
    
Start both the uwsgi service and nginx:
    
    service uwsgi start
    service nginx start
    
Let's verify that keystone properly responds to requests:

    root@controller:~# source openrc
    
    root@controller:~# keystone tenant-list
    +----------------------------------+---------+---------+
    |                id                |   name  | enabled |
    +----------------------------------+---------+---------+
    | 9d314f96330a4e459420623a922e2c09 |   demo  |   True  |
    | 4382d14df2004903a16edf17e3c58652 | service |   True  |
    +----------------------------------+---------+---------+
    
    root@controller:~# nova service-list
    +----+------------------+------------+----------+---------+-------+----------------------------+-----------------+
    | Id | Binary           | Host       | Zone     | Status  | State | Updated_at                 | Disabled Reason |
    +----+------------------+------------+----------+---------+-------+----------------------------+-----------------+
    | 1  | nova-cert        | controller | internal | enabled | up    | 2015-09-30T18:03:52.000000 | -               |
    | 2  | nova-conductor   | controller | internal | enabled | up    | 2015-09-30T18:03:58.000000 | -               |
    | 3  | nova-scheduler   | controller | internal | enabled | up    | 2015-09-30T18:03:54.000000 | -               |
    | 4  | nova-compute     | compute    | nova     | enabled | up    | 2015-09-30T18:03:58.000000 | -               |
    | 5  | nova-compute     | compute2   | nova     | enabled | down  | 2014-11-21T22:13:43.000000 | -               |
    | 6  | nova-consoleauth | controller | internal | enabled | up    | 2015-09-30T18:03:52.000000 | -               |
    +----+------------------+------------+----------+---------+-------+----------------------------+-----------------+

If you don't get valid responses from either keystone or the other client agents, look at both the nginx log files and the log files for keystone, or the failing api service for the appropriate agent. Lastly, verify that horizon responds properly. Open http://<server public IP> in your browser and log in. If the login is successful everything is working.

