---
layout: post
title: "Run keystone/horizon under NGINX on Ubuntu 16.04"
date: 2016-05-13 07:00
comments: true
author: Phil Hopkins
published: true
categories:
    - OpenStack
    - OSAD
---

Run OpenStack Keystone and Horizon using NGINX on Ubuntu 16.04
==============================================================

I previously wrote an article showing how to [convert OpenStack from using an Apache server for both Keystone and the Horizon interface](https://developer.rackspace.com/blog/keystone_horizon_nginx/). Since that article was written, OpenStack has moved to the Mitaka release, and Unbuntu has moved to a new long term release "Ubuntu 16.04 - xenial". These two releases bring a number of changes to the configuration. In this article, I show you how to make the transition to ngix running these newer releases.

<!-- more -->


The article assumes you have a working OpenStack cluster, running the Mitaka release on Ubuntu 16.04. All work will be performed on the controller node for those developers using a multi-node OpenStack cluster.


First, stop the running keystone and apache services:

    service apache2 stop
    service keystone stop
    systemctl disable apache2.service

Apache uses wsgi, however NGINX has no direct wsgi support. Instead there are several projects that bring wsgi functionality to NGINX. We will use the uwsgi packages provided by Ubuntu. Install the NGINX server and other required packages:

    apt-get install -y nginx libgd-tools nginx-doc python-django-uwsgi uwsgi uwsgi-core uwsgi-emperor uwsgi-plugin-python

Since Ubuntu usually starts services when the package is installed, stop the nginx service until we get it configured:

    service nginx stop

Since keystone and horizon run behind the uwsgi service, disable these services so they don't start as systemd services:

    systemctl disable keystone
    systemctl disable horizon

We are not running a simple web server, so disable the default site that comes with the NGINX install:

    rm /etc/nginx/sites-enabled/default

Make a log directory for keystone and horizon under NGINX, and set the proper permissions:
(in this configuration, nginx will run as the www-data user, the uwsgi keystone process runs as the keystone user and the horizon (django) uwsgi runs process as the horizon user)

    mkdir /var/log/nginx/keystone
    mkdir /var/log/nginx/horizon
    chown www-data:adm /var/log/nginx/keystone/
    chown www-data:adm /var/log/nginx/horizon/

Setup log directories for the uwsgi processes:

    mkdir /var/log/keystone
    mkdir /var/log/horizon
    chown keystone:keystone /var/log/keystone
    chown horizon:horizon /var/log/horizon


and a base directory for the keystone wsgi python script:

    mkdir /var/www/keystone

Keystone comes with a python script for interfacing to servers running a wsgi interface. Keystone listens on two tcp ports, one for processing admin level requests and one for requests that don't need admin level permissions. If you installed keystone from the Ubuntu package tree, this file was not included the the keystone packages. You will need to download it. For those having installed OpenStack from source, you will need to just copy the file as shown below. One copy will be used to handle requests that need the keystone admin role and the other copy is for non-admin requests.

To download it use:

    wget -O /var/www/keystone/admin https://github.com/openstack/keystone/blob/stable/mitaka/httpd/keystone.py
    wget -O /var/www/keystone/main https://github.com/openstack/keystone/blob/stable/mitaka/httpd/keystone.py

If you installed keystone from source cd into the horizon source directory and run:

    cp keystone/httpd/keystone.py /var/www/keystone/admin
    cp keystone/httpd/keystone.py /var/www/keystone/main

Now set the proper permissions on the file, so that the uwsgi keystone user can access it and it has execute permissions:

    chown -R keystone:keystone /var/www/keystone
    chmod ug+x /var/www/keystone/*

uwsgi has a broad set of configuration parameters. We are only going to set a minimum number of values to get this configuration running. You need to read the uwsgi documentation to ensure proper security is set up and the best performance values are selected for your environment. We set uwsgi to run 10 processes with 2 threads per process. The keystone process runs as the keystone user and the www-data group. We will also be using the uwsgi emperor to handle all of the uwsgi processes. These files will be located unter the uwsgi-emporer/vassals configuration directory. The following creates the needed uwsgi configuration file for running keystone admin requests:

    cat >> /etc/uwsgi-emperor/vassals/keystone-admin.ini << EOF
    [uwsgi]
    master = true
    workers = 10
    threads = 2
    no-orphans = true
    plugin = python
    chmod-socket = 660

    socket = /run/uwsgi/keystone-admin.sock
    pidfile = /run/uwsgi/keystone-admin.pid

    logto = /var/log/uwsgi/app/keystone-admin.log

    name = keystone
    uid = keystone
    gid = www-data

    chdir = /var/www/keystone/
    wsgi-file = /var/www/keystone/admin

    EOF


Next, create the needed uwsgi configuration file for running keystone non-admin requests:

    cat >> /etc/uwsgi-emperor/vassals/keystone-main.ini << EOF
    [uwsgi]
    master = true
    workers = 10
    threads = 2
    no-orphans = true
    plugin = python
    chmod-socket = 660

    socket = /run/uwsgi/keystone-main.sock
    pidfile = /run/uwsgi/keystone-main.pid

    name = keystone
    uid = keystone
    gid = www-data

    logto = /var/log/uwsgi/app/keystone-main.log

    chdir = /var/www/keystone/
    wsgi-file = /var/www/keystone/main
    EOF

Lastly, to finish the uwsgi configuration create the needed uwsgi configuration file for running horizon:

    cat >> /etc/uwsgi-emperor/vassals/horizon.ini << EOF
    [uwsgi]
    master = true
    workers = 10
    threads = 2
    no-orphans = true
    plugin = python
    chmod-socket = 660

    socket = /run/uwsgi-horizon/horizon.sock
    pidfile = /run/uwsgi-horizon/horizon.pid
    logto = /var/log/uwsgi/app/horizon.log

    name = horizon
    uid = horizon
    gid = www-data

    chdir = /etc/openstack_dashboard/
    env = DJANGO_SETTINGS_MODULE=openstack_dashboard.settings
    module = django.core.wsgi:get_wsgi_application()
    wsgi-file = /var/www/wsgi/horizon.wsgi
    EOF

The nginx and uwsgi processes need to talk to each other. Therefore we will use Unix sockets, becasue they don't require the overhead of TCP sockets and are faster. Create the directories for the sockets, and set the permissions for the directories:

    mkdir /run/uwsgi
    mkdir /run/uwsgi-horizon
    chown keystone:www-data /run/uwsgi
    chown horizon:www-data /run/uwsgi-horizon

Lastly, we want to set the user and group for the various uwsgi processes within the individual, so we need to remove this from the emperor configuration file:

    sed -i 's/uid = www-data/#uid = www-data/g' /etc/uwsgi-emperor/emperor.ini
    sed -i 's/gid = www-data/#gid = www-data/g' /etc/uwsgi-emperor/emperor.ini

Create the nginx configuration file for keystone. Remember that keystone listens on ports 5000 for normal requests and 35357 for admin requests, so we will need server entries for each port in nginx:

    cat >> /etc/nginx/sites-available/keystone.conf << EOF
    server {
            listen          5000;
            access_log /var/log/nginx/keystone/access.log;
            error_log /var/log/nginx/keystone/error.log;

            location / {
                uwsgi_pass      unix:///run/uwsgi/keystone-main.socket;
                include         uwsgi_params;
                uwsgi_param      SCRIPT_NAME   '';
             }
    }
    server {
            listen          35357;
            access_log /var/log/nginx/keystone/access.log;
            error_log /var/log/nginx/keystone/error.log;

            location / {
                uwsgi_pass      unix:///run/uwsgi/keystone-admin.socket;
                include         uwsgi_params;
                uwsgi_param      SCRIPT_NAME   '';

           }
    }
    EOF

Create the configuration file for nginx and horizon:

    cat >> /etc/nginx/sites-available/horizon.conf << EOF
        server {
        listen 80;
        server_name openstack.foo.com;
            access_log /var/log/nginx/horizon/access.log;
            error_log /var/log/nginx/horizon/error.log;

        location / { try_files  \$uri @horizon; }
        location @horizon {
            uwsgi_pass unix:///run/uwsgi-horizon/horizon.sock;
            include uwsgi_params;
            uwsgi_param      SCRIPT_NAME   '';
        }
        location /static {
          alias /var/www/static;
        }
    }
    EOF


Enable both the keystone and horizon functions (sites) in nginx:

    ln -s /etc/nginx/sites-available/keystone.conf /etc/nginx/sites-enabled/keystone.conf
    ln -s /etc/nginx/sites-available/horizon.conf /etc/nginx/sites-enabled/horizon.conf

Start both the uwsgi service and nginx:

    service uwsgi-emperor start
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

If you don't get valid responses from either keystone or the other client agents, look at both the nginx log files and the log files for keystone, or the failing api service for the appropriate agent. Lastly, verify that horizon responds properly. Open https://<server public IP> in your browser, and log in. If the login is successful everything is working.
