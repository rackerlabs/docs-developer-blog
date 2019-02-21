---
layout: post
title: Install OpenStack from source - part 2
date: '2015-08-03 23:59'
comments: true
author: Phil Hopkins
published: true
categories:
  - OpenStack
  - OSAD
  - database
---

In the [first article of this series](https://developer.rackspace.com/blog/install-openstack-from-source/), we started installing OpenStack from source. We installed keystone and populated it with some basic information including a Services project and an admin user for our new OpenStack install. Additionally, in an initial script we setup users and directories for the upcoming installs of the Image service (glance), Networking service (neutron), Compute service (nova) and Volume service (cinder). Now, let's continue and install and start the glance process on the controller node.

<!-- more -->

In the first article, we added some information into our bashrc file to set a couple of shell variables to use in the remaining sets.. Verify that at least one of these variables are set:

    echo $MY_IP

To start installing the Image service (glance), we need to make a few additional glance sub-directories and ensure that they have the proper permissions (the basic glance directories were created by a script in the previous article):

    mkdir -p /var/lib/glance/images
    mkdir -p /var/lib/glance/scrubber
    mkdir -p /var/lib/glance/image-cache

Next, download (clone the repo) and install glance:

    git clone https://github.com/openstack/glance.git -b stable/kilo

Note: Remember that we can change to install from trunk by eliminating the -b stable/kilo from the above command.

    cp -R glance/etc/* /etc/glance/
    cd glance
    python setup.py install

Configure glance by setting some basic information like database connection information, message queue info and keystone connection information:

    sed -i "s|#connection = <None>|connection = mysql://glance:glance@$MY_PRIVATE_IP/glance|g" /etc/glance/glance-api.conf
    sed -i "s/rabbit_host = localhost/rabbit_host = $MY_PRIVATE_IP/g" /etc/glance/glance-api.conf
    sed -i "s/auth_host = 127.0.0.1/auth_host = $MY_PRIVATE_IP/g" /etc/glance/glance-api.conf
    sed -i 's/%SERVICE_TENANT_NAME%/service/g' /etc/glance/glance-api.conf
    sed -i 's/%SERVICE_USER%/glance/g' /etc/glance/glance-api.conf
    sed -i 's/%SERVICE_PASSWORD%/glance/g' /etc/glance/glance-api.conf
    sed -i 's/#flavor=/flavor = keystone/g' /etc/glance/glance-api.conf
    sed -i 's/#show_image_direct_url = False/show_image_direct_url = True/g' /etc/glance/glance-api.conf

Configure the Glance-Registry with the same information as above:

    sed -i "s|#connection = <None>|connection = mysql://glance:glance@$MY_PRIVATE_IP/glance|g" /etc/glance/glance-registry.conf
    sed -i "s/auth_host = 127.0.0.1/auth_host = $MY_PRIVATE_IP/g" /etc/glance/glance-registry.conf
    sed -i 's/%SERVICE_TENANT_NAME%/service/g' /etc/glance/glance-registry.conf
    sed -i 's/%SERVICE_USER%/glance/g' /etc/glance/glance-registry.conf
    sed -i 's/%SERVICE_PASSWORD%/glance/g' /etc/glance/glance-registry.conf
    sed -i 's/#flavor=/flavor = keystone/g' /etc/glance/glance-registry.conf
    sed -i 's|#connection = <None>|connection = mysql://glance:glance@$MY_IP|g' /etc/glance/glance-api.conf
    sed -i 's|#connection = <None>|connection = mysql://glance:glance@$MY_IP|g' /etc/glance/glance-registry.conf

Create the MySQL database for glance and populate the newly created database with the glance tables:

    mysql -u root -pmysql -e 'CREATE DATABASE glance;'
    mysql -u root -pmysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'glance';"
    mysql -u root -pmysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'glance';"
    glance-manage db_sync

Although not needed in this environment, we will install glance-image-sync and set it to run on a regular basis. If we had multiple glance API nodes this would sync the glance images between the nodes:

    git clone https://github.com/rcbops/glance-image-sync
    pushd glance-image-sync
    mv glance-image-sync.py /usr/local/bin/glance-image-sync
    chmod +x /usr/local/bin/glance-image-sync
    popd

    cat >> /etc/glance/glance-image-sync << EOF
    [DEFAULT]
    api_nodes = $MY_IP
    rsync_user = glance
    lock_file = /var/run/glance-image-sync
    EOF

    cat >>  /etc/cron.d/glance-image-syn << EOF
    */5 * * * * glance /usr/local/bin/glance-image-sync
    EOF

We must remember to rotate the glance log files:

    cat >> /etc/logrotate.d/glance << EOF
    /var/log/glance/*.log {
            daily
            missingok
            rotate 7
            compress
            notifempty
            nocreate
    }
    EOF

If you do not get the Identity service signing certificates for the Image service, the Image API requests fail. Prevent this by getting the keystone signing certs for glance:

    cp /etc/keystone/ssl/certs/ca.pem /var/lib/glance/cacert.pem
    cp /etc/keystone/ssl/certs/signing_cert.pem /var/lib/glance/
    chown glance:glance /var/lib/glance/*
    chmod 600 /var/lib/glance/cacert.pem
    chmod 600 /var/lib/glance/signing_cert.pem

We are almost ready to start glance, but we must first create the glance upstart scripts:

Note: These scripts are just copied from the scripts that the Ubuntu packaged version of glance installs.

    cat >> /etc/init/glance-api.conf << EOF
    description "Glance API server"
    author "Soren Hansen <soren@linux2go.dk>"

    start on runlevel [2345]
    stop on runlevel [!2345]

    respawn

    exec start-stop-daemon --start --chuid glance --exec /usr/local/bin/glance-api -- --config-file=/etc/glance/glance-api.conf --config-file=/etc/glance/glance-api-paste.ini
    EOF

    cat >> /etc/init/glance-registry.conf << EOF
    description "Glance registry server"
    author "Soren Hansen <soren@linux2go.dk>"

    start on runlevel [2345]
    stop on runlevel [!2345]

    respawn

    exec start-stop-daemon --start --chuid glance --exec /usr/local/bin/glance-registry -- --config-file=/etc/glance/glance-registry.conf --config-file=/etc/glance/glance-registry-paste.ini

    EOF

Start glance and verify that is is running:

    start glance
    start glance-registry

Wait about 15 seconds and run the following to verify that glance is running:

    ps aux|grep glance

If glance started, we should see a line from the last command showing information about the running process. If that didn't happen and glance didn't start or stay running use the following to manually start glance for troubleshooting:

    sudo -u glance glance-api --config-file=/etc/glance/glance-api.conf --config-file=/etc/glance/glance-api-paste.ini > /dev/null 2>&1 &

    sudo -u glance glance-registry --config-file=/etc/glance/glance-registry.conf --config-file=/etc/glance/glance-registry-paste.ini > /dev/null 2>&1 &

**Note:** Setting the value `debug = True` in the file `/etc/glance/glance.conf` will increade the logging output, for help in debugging failures.

Next, install an image into glance for use once we have OpenStack fully installed as a basis for VMs. There is a small cloud image based on Ubuntu that is available, named cirros. With glance running download the cirros image and load it into glance:

    wget http://cdn.download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img

    glance image-create --name=cirros-qcow2 \
                        --disk-format=qcow2 \
                        --container-format=bare \
                        --is-public=true < cirros-0.3.3-x86_64-disk.img

Our second process is now running and we can now turn our attention to installing the Networking service (neutron). This is the first of three neutron installs that we will have to do, the neutron server on the controller node and the neutron agents on the network and compute nodes.

Since the nova, neutron and glance processes need root or sudo privileges to accomplish various tasks, we need to create special sudo permissions for these process users. OpenStack also limits the extent of these privileges through use of a rootwrap configuration. Run the following script to set up the sudo permissions:

    for SERVICE in neutron nova cinder
    do
    echo $SERVICE
    cat > '/etc/sudoers.d/'$SERVICE'_sudoers' << EOF
    Defaults:$SERVICE !requiretty

    $SERVICE ALL = (root) NOPASSWD: /usr/local/bin/$SERVICE-rootwrap  /etc/$SERVICE/rootwrap.conf *
    EOF

    chmod 440 /etc/sudoers.d/$SERVICE_sudoers
    done
    chmod 750 /etc/sudoers.d

Some of the pip prerequisites have a couple of the package prerequisites, that aren't automatically installed. Install these packages now:

    apt-get -y install git mysql-client python-dev libxml2-dev libffi-dev

Clone the neutron repon:

    git clone https://github.com/openstack/neutron.git -b stable/kilo

Copy the provided configuration files:

    cp neutron/etc/* /etc/neutron/

Copy some needed configuration subdirectories:

    cp -R neutron/etc/neutron/plugins/ml2/* /etc/neutron/plugins/ml2
    cp -R neutron/etc/neutron/rootwrap.d/* /etc/neutron/rootwrap.d

Now install neutron:

    cd neutron
    python setup.py install
    cd ~

Create the MySQL database for neutron:

    mysql -u root -pmysql -e 'CREATE DATABASE neutron;'
    mysql -u root -pmysql -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'neutron';"
    mysql -u root -pmysql -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'neutron';"

The sample data script that was run in the previous article does not insert data for the neutron service. Create Neutron service user in keystone:

    keystone user-create --tenant service --name neutron --pass neutron

Grant the 'admin' role to the newly created Neutron service user:

    keystone user-role-add --user neutron --tenant service --role admin

And verify that the user creation worked. List the service users and roles and verify that the neutron user exists and has the admin role:

    keystone user-list --tenant Services
    keystone user-role-list --tenant service --user neutron

You should see in the output of the two previous commands that the neutron user was created and has the proper permissions. Now populate a neutron service into the keystone service catalog:

    keystone service-create --name=neutron --type=network --description="Neutron Network Service"

Place the neutron endpoint information into the keystone service catalog:

    keystone endpoint-create --region RegionOne --service neutron --publicurl=http://$MY_PUBLIC_IP:9696 --internalurl=http://$MY_PRIVATE_IP:9696 --adminurl=http://$MY_PRIVATE_IP:9696

    SERVICE_TENANT_ID=`keystone tenant-get service | awk '/ id / { print $4 }'`

Finally, we must configure neutron. If the basic configuration file is supplied in the package close process, remove it, because it is very long and difficult to edit. Next, the following sequence will replace it with a simpler one (the original is still in the cloned neutron directory if we ever need to look at it in the future):

    rm /etc/neutron/neutron.conf

    cat > /etc/neutron/neutron.conf << EOF
    [DEFAULT]
    verbose = True
    debug = True
    core_plugin = ml2
    service_plugins = router
    auth_strategy = keystone
    allow_overlapping_ips = True
    dhcp_agents_per_network = 1
    notify_nova_on_port_status_changes = True
    notify_nova_on_port_data_changes = True
    nova_url = http://$MY_PRIVATE_IP:8774/v2
    nova_admin_username = nova
    nova_admin_tenant_id = $SERVICE_TENANT_ID
    #nova_admin_tenant_name = service
    nova_admin_password = nova
    nova_admin_auth_url = http://$MY_PRIVATE_IP:35357/v2.0

    [agent]
    root_helper=sudo /usr/local/bin/neutron-rootwrap /etc/neutron/rootwrap.conf
    [keystone_authtoken]
    auth_uri = http://$MY_PRIVATE_IP:35357/v2.0/
    identity_uri = http://$MY_PRIVATE_IP:5000
    admin_tenant_name = service
    admin_user = neutron
    admin_password = neutron
    [database]
    connection = mysql://neutron:neutron@$MY_PRIVATE_IP/neutron

    [oslo_concurrency]
    lock_path = /var/lock/neutron

    [oslo_messaging_rabbit]
    rabbit_host = $MY_PRIVATE_IP
    EOF

Rotate the neutron log files:

    cat >> /etc/logrotate.d/neutron << EOF
    /var/log/neutron/*.log {
            daily
            missingok
            rotate 7
            compress
            notifempty
            nocreate
    }
    EOF

Neutron supports multiple networking layer 2 technologies through the ML2 plugin. Configure the neutron ML2 plugin agent to use GRE tunnels for project network isolation. Although this agent doesn't run on the controller node, the neutron server needs to know about the plugin:

    rm /etc/neutron/plugins/ml2/ml2_conf.ini
    cat > /etc/neutron/plugins/ml2/ml2_conf.ini  << EOF

    [ml2]
    type_drivers = gre
    tenant_network_types = gre
    mechanism_drivers = openvswitch

    [ml2_type_gre]
    tunnel_id_ranges = 1:1000

    [securitygroup]
    enable_security_group = True
    enable_ipset = True
    firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
    EOF

    chown neutron:neutron /etc/neutron/*.{conf,json,ini}
    chown -R neutron:neutron /etc/neutron/plugins

    cat > /etc/default/neutron << EOF
    --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini
    EOF

As we did for glance, build the neutron database tables:

    neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head


Before we start the neutron process, we need to give the startup script some options information so it will read the ml2 configuration file:

    cat > /etc/default/neutron-server << EOF
    NEUTRON_PLUGIN_CONFIG="/etc/neutron/plugins/ml2/ml2_conf.ini"
    EOF

And, finally, create the upstart scripts that are used to start the neutron server process:

    cat > /etc/init/neutron-server.conf << EOF
    # vim:set ft=upstart ts=2 et:

    start on runlevel [2345]
    stop on runlevel [!2345]

    script
      [ -r /etc/default/neutron-server ] && . /etc/default/neutron-server
      [ -r "\$NEUTRON_PLUGIN_CONFIG" ] && CONF_ARG="--config-file \$NEUTRON_PLUGIN_CONFIG"
      exec start-stop-daemon --start --chuid neutron --exec /usr/local/bin/neutron-server -- \
        --config-file /etc/neutron/neutron.conf \
        --log-file /var/log/neutron/server.log \$CONF_ARG
    end script

    EOF

Start neutron server running and verify that it stays running. The second line gives information about the running neutron process (again wait for about 15 seconds before running the second command):

    start neutron
    ps aux|grep neutron

If neutron will not start, use the following line to manually start neutron. If the neutron process has errors in starting, it gives you output to aid in debugging the problem.

    sudo -u neutron neutron-server --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini --log-file /var/log/neutron/server.log

In the next article of this series, we install several nova processes onto the controller node.
