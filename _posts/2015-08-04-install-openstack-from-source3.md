---
layout: post
title: Install OpenStack from source - part 3
date: '2015-08-04 23:59'
comments: true
author: Phil Hopkins
published: true
categories:
  - OpenStack
  - OSAD
---

In  [article one of this series](https://developer.rackspace.com/blog/install-openstack-from-source/), we started installing OpenStack from source, and, in [article two of this series](https://developer.rackspace.com/blog/install-openstack-from-source2/), we continued the process by installing glance and neutron onto the controller node.

<!-- more -->

Now, let's get started installing nova. First, we need to install a few more package dependencies so that the pip requirements can be installed successfully:

    apt-get install -y libpq-dev python-libvirt libxml2-dev libxslt1-dev
    pip install mydb

With that completed, now let's clone the nova repo:

    git clone https://github.com/openstack/nova.git -b stable/kilo

Next, copy the config files to their proper location and install nova:

    cd nova
    cp -r etc/nova/* /etc/nova/
    python setup.py install
    cd ~

As we have done before, create the MySQL nova database and set the permissions so the nova user can access it:

    mysql -u root -pmysql -e 'CREATE DATABASE nova;'
    mysql -u root -pmysql -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';"
    mysql -u root -pmysql -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'nova';"

The Python module tox can be used to build a full **nova.conf** file, but, in reality it is way too big and complex for what we need. The folllowing creates a usable nova.conf file for our needs. I recommend that you read it carefully and familiarize yourself with the parameters that are being set.

    cat > /etc/nova/nova.conf << EOF
    [DEFAULT]
    #verbose = True
    dhcpbridge_flagfile = /etc/nova/nova.conf
    dhcpbridge = /usr/local/bin/nova-dhcpbridge
    log_dir = /var/log/nova
    state_path = /var/lib/nova
    force_dhcp_release = True
    iscsi_helper = tgtadm
    libvirt_use_virtio_for_bridges = True
    connection_type = libvirt
    root_helper = sudo /usr/local/bin/nova-rootwrap /etc/nova/rootwrap.conf
    ec2_private_dns_show_ip = True
    api_paste_config = /etc/nova/api-paste.ini
    volumes_path = /var/lib/nova/volumes
    enabled_apis = ec2,osapi_compute,metadata
    network_api_class=nova.network.neutronv2.api.API
    firewall_driver = nova.virt.firewall.NoopFirewallDriver
    security_group_api = neutron
    linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
    auth_strategy = keystone
    force_config_drive = always
    my_ip = $MY_PRIVATE_IP
    fixed_ip_disassociate_timeout = 30
    enable_instance_password = False
    service_neutron_metadata_proxy = True
    neutron_metadata_proxy_shared_secret = openstack
    novncproxy_base_url = http://$MY_PUBLIC_IP:6080/vnc_auto.html
    vncserver_proxyclient_address= $MY_PRIVATE_IP
    vncserver_listen  =0.0.0.0

    [database]
    connection = mysql://nova:nova@$MY_PRIVATE_IP/nova

    [glance]
    host = 10.0.1.4

    [keystone_authtoken]
    auth_uri = http://$MY_PRIVATE_IP:5000
    auth_host = $MY_PRIVATE_IP
    auth_port = 35357
    auth_protocol = http
    admin_tenant_name = service
    admin_user = nova
    admin_password = nova

    [neutron]
    url=http://10.0.1.4:9696
    admin_username = neutron
    admin_password = neutron
    admin_tenant_name = service
    admin_auth_url = http://10.0.1.4:5000/v2.0
    auth_strategy = keystone

    [oslo_concurrency]
    lock_path = /var/lock/nova

    [oslo_messaging_rabbit]
    rabbit_host = 10.0.1.4

    EOF

Rotate the nova log files:

    cat >> /etc/logrotate.d/nova << EOF
    /var/log/neutron/*.log {
            daily
            missingok
            rotate 7
            compress
            notifempty
            nocreate
    }
    EOF

Set the permissions on the proper nova files so that the nova user can read them:

    chown nova:nova /etc/nova/*.{conf,json,ini}

And let nova populate the database with the needed tables:

    nova-manage db sync

We are almost ready to start nova, but we must first create the several needed nova upstart scripts. We need to start the nova api, cert, consoleauth, conductor and scheduler processes:

Note: These scripts are just copied from the scripts that the Ubuntu packaged version of nova installs.

Nova api:

    cat > /etc/init/nova-api.conf << EOF

    start on runlevel [2345]
    stop on runlevel [!2345]

    exec start-stop-daemon --start --chuid nova --exec /usr/local/bin/nova-api -- --config-file=/etc/nova/nova.conf
    EOF

Nova cert:

    cat > /etc/init/nova-cert.conf << EOF

    start on runlevel [2345]
    stop on runlevel [!2345]

    exec start-stop-daemon --start --chuid nova --exec /usr/local/bin/nova-cert -- --config-file=/etc/nova/nova.conf
    EOF

Nova consoleauth:

    cat > /etc/init/nova-consoleauth.conf << EOF

    start on runlevel [2345]
    stop on runlevel [!2345]

    respawn

    chdir /var/run

    exec start-stop-daemon --start --chuid nova --exec /usr/local/bin/nova-consoleauth -- --config-file=/etc/nova/nova.conf
    EOF

Nova conductor:

    cat > /etc/init/nova-conductor.conf << EOF
    description "Nova conductor"
    author "Chuck Short <zulcss@ubuntu.com>"

    start on runlevel [2345]
    stop on runlevel [!2345]

    chdir /var/run

    pre-start script
            mkdir -p /var/run/nova
            chown nova:root /var/run/nova/
            mkdir -p /var/lock/nova
            chown nova:root /var/lock/nova/
    end script

    exec start-stop-daemon --start --chuid nova --exec /usr/local/bin/nova-conductor -- --config-file=/etc/nova/nova.conf
    EOF

Nova scheduler:

    cat > /etc/init/nova-scheduler.conf << EOF
    description "Nova scheduler"
    author "Soren Hansen <soren@linux2go.dk>"

    start on runlevel [2345]
    stop on runlevel [!2345]

    chdir /var/run

    pre-start script
            mkdir -p /var/run/nova
            chown nova:root /var/run/nova/
            mkdir -p /var/lock/nova
            chown nova:root /var/lock/nova/
    end script

    exec start-stop-daemon --start --chuid nova --exec /usr/local/bin/nova-scheduler -- --config-file=/etc/nova/nova.conf
    EOF

Now, lets start the nova services and verify that everything is running:

    start nova-api
    start nova-cert
    start nova-consoleauth
    start nova-conductor
    start nova-scheduler

Check to see if the nova processes are running:

    ps aux|grep nova

There should be at least one line of output for each nova process. Rerun this, after 30 seconds or so, to verify that the processes stay running and that there are not problems.

If one or more of the nova services does not start (or stay) running, use the appropriate command below to test and get output that can be used to debug problems with the service that is not starting.

    sudo -u nova nova-api --config-file=/etc/nova/nova.conf
    sudo -u nova nova-cert --config-file=/etc/nova/nova.conf
    sudo -u nova nova-consoleauth --config-file=/etc/nova/nova.conf
    sudo -u nova nova-conductor --config-file=/etc/nova/nova.conf
    sudo -u nova nova-scheduler --config-file=/etc/nova/nova.conf

We now have the major OpenStack processes running on the controller node, and in the next article, our focus moves to the network node. We will install various neutron pieces that need to be running there, then move to the compute node and finally back to the controller node to install the Volume service (cinder) and the dashboard (horizon).

