---
layout: post
date: '2015-08-20 23:59'
title: Install OpenStack from source - part 6
comments: true
author: Phil Hopkins
published: true
categories:
  - OpenStack
  - OSAD
---

This is the sixth and final installment in a series demonstrating how to install OpenStack from source. The five previous articles:

* [Install Keystone](https://developer.rackspace.com/blog/install-openstack-from-source/)
* [Install Glance and Neutron](https://developer.rackspace.com/blog/install-openstack-from-source2/)
* [Install Nova](https://developer.rackspace.com/blog/install-openstack-from-source3/)
* [Install Neutron on the Network node](https://developer.rackspace.com/blog/install-openstack-from-source4/)
* [Install the Compute node](https://developer.rackspace.com/blog/install-openstack-from-source5/)

Previously we installed the Identity service (keystone), Image service (glance), Networking service (neutron), and the Compute service (nova) onto the controller node. We also installed neutron onto the network node and nova and neutron onto the compute node. In this section, we turn our attention to finishing up by installing the Volume service (cinder) and dashboard (horizon) onto the controller node.

<!-- more -->

As we finish up our OpenStack intallation, we turn our attention to both cinder and horizon. First, we start with cinder, and, like we have done before, we create the cinder user and the directories that the cinder user needs:

    mkdir /var/cache/cinder
    chown cinder:cinder /var/cache/cinder/
    chmod 700 /var/cache/cinder

Now clone the cinder repo and install cinder:

    git clone https://github.com/openstack/cinder.git -b stable/kilo
    cd cinder
    pip install --requirement requirements.txt
    python setup.py install
    cd ~

Copy the cinder configuration files to the `etc` directory:

    cp -R cinder/etc/cinder/* /etc/cinder
    mv /etc/cinder/cinder.conf.sample /etc/cinder/cinder.conf

Set up sudo access for the newly created cinder user, again using the rootwrap sudo wrapper help to control sudo access:

    cat > /etc/sudoers.d/cinder_sudoers << EOF
    Defaults:cinder !requiretty

    cinder ALL = (root) NOPASSWD: /usr/local/bin/cinder-rootwrap  /etc/cinder/rootwrap.conf *
    EOF

    chmod 440 /etc/sudoers.d/cinder_sudoers

Create the cinder configuration file

    cat > /etc/cinder/cinder.conf << EOF
    [DEFAULT]
    rpc_backend=rabbit
    osapi_volume_listen=$MY_PRIVATE_IP
    api_paste_config = /etc/cinder/api-paste.ini
    rootwrap_config=/etc/cinder/rootwrap.conf/rootwrap.conf
    auth_strategy = keystone

    [DATABASE]
    connection = mysql://cinder:cinder@$MY_PRIVATE_IP/cinder?charset=utf8

    [keystone_authtoken]
    auth_uri = http://$MY_PRIVATE_IP:5000/v2.0
    identity_uri = http://$MY_PRIVATE_IP:35357/
    admin_user = cinder
    admin_password = cinder
    admin_tenant_name = service
    signing_dir = /var/cache/cinder

    [oslo_messaging_rabbit]
    rabbit_host=$MY_PRIVATE_IP

    EOF

Set proper ownership for the cinder configuration files:

    chown cinder:cinder /etc/cinder/*.{conf,json,ini}

Create the database that cinder uses:

    mysql -u root -pmysql -e 'CREATE DATABASE cinder;'
    mysql -u root -pmysql -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'cinder';"
    mysql -u root -pmysql -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'cinder';"

Create the cinder database structure:

    cinder-manage db sync

The sample data script that we used to populate data into keystone does not insert data for the cinder user, so we do that here. Create the cinder service user in keystone:

    keystone user-create --tenant service --name cinder --pass cinder

Grant the 'admin' role to the cinder service user:

    keystone user-role-add --user cinder --tenant service --role admin

Add a cinder service and a v2 endpoint in keystone:

    openstack service create --type volumev2 \
      --description "OpenStack Block Storage" cinderv2

    openstack endpoint create \
      --publicurl http://10.0.1.4:8776/v2/%\(tenant_id\)s \
      --internalurl http://10.0.1.4:8776/v2/%\(tenant_id\)s \
      --adminurl http://10.0.1.4:8776/v2/%\(tenant_id\)s \
      --region RegionOne \
      volumev2

The back-end store for cinder, that we use in this example, is iSCSI. This installation assumes that the iSCSI has a volume group named cinder-volumes created on the controller node to use as actual store for cinder. Cinder then creates logical volumes for the various cinder volumes that are created. Install the open-iscsi and tgt packages:


    apt-get install -y open-iscsi tgt

Configure tgt so that cinder can add volumes when they are requested to be created:

    cat >> /etc/tgt/conf.d/cinder_tgt.conf << EOF
    include /var/lib/cinder/volumes/*
    EOF

Restart the open-iscsi and tgt service so that they see the configuration file changes:

    service tgt restart
    service open-iscsi restart

Create the cinder upstart scripts. First for the API service:

    cat > /etc/init/cinder-api.conf << EOF
    description "Cinder API"

    start on runlevel [2345]
    stop on runlevel [!2345]


    chdir /var/run

    pre-start script
            mkdir -p /var/run/cinder
            chown nova:root /var/run/cinder/

            mkdir -p /var/lock/cinder
            chown nova:root /var/lock/cinder/

    end script

    exec start-stop-daemon --start --chuid cinder --exec /usr/local/bin/cinder-api -- --config-file=/etc/cinder/cinder.conf --log-file=/var/log/cinder/api.log
    EOF

Next for the cinder scheduler service:

    cat > /etc/init/cinder-scheduler.conf << EOF
    description "Cinder Scheduler"

    start on runlevel [2345]
    stop on runlevel [!2345]


    chdir /var/run

    pre-start script
            mkdir -p /var/run/cinder
            chown nova:root /var/run/cinder/

            mkdir -p /var/lock/cinder
            chown nova:root /var/lock/cinder/

    end script

    exec start-stop-daemon --start --chuid cinder --exec /usr/local/bin/cinder-scheduler -- --config-file=/etc/cinder/cinder.conf --log-file=/var/log/cinder/scheduler.log
    EOF

And lastly for the cinder volume service:

    cat > /etc/init/cinder-volume.conf << EOF
    description "Cinder Volume"

    start on runlevel [2345]
    stop on runlevel [!2345]


    chdir /var/run

    pre-start script
            mkdir -p /var/run/cinder
            chown nova:root /var/run/cinder/

            mkdir -p /var/lock/cinder
            chown nova:root /var/lock/cinder/

    end script

    exec start-stop-daemon --start --chuid cinder --exec /usr/local/bin/cinder-volume -- --config-file=/etc/cinder/cinder.conf --log-file=/var/log/cinder/volume.log
    EOF

At this point, we can start all the cinder services:

    start cinder-api
    start cinder-volume
    start cinder-scheduler

Wait 20 to 30 seconds and verify that everything started:

    ps aux|grep cinder

You should see something like:

    root@controller:~# ps aux|grep cinder
    cinder   14633  0.5  2.6 243092 55244 ?        Ss   Aug17 823:42 /usr/bin/python /usr/local/bin/cinder-api --config-file=/etc/cinder/cinder.conf --log-file=/var/log/cinder/api.log
    cinder   14652  0.0  3.3 256064 69176 ?        S    Aug17   0:10 /usr/bin/python /usr/local/bin/cinder-api --config-file=/etc/cinder/cinder.conf --log-file=/var/log/cinder/api.log
    cinder   14664  0.5  2.4 216680 49456 ?        Ss   Aug17 835:51 /usr/bin/python /usr/local/bin/cinder-volume --config-file=/etc/cinder/cinder.conf --log-file=/var/log/cinder/volume.log
    cinder   14671  0.1  2.5 219392 52968 ?        S    Aug17 165:47 /usr/bin/python /usr/local/bin/cinder-volume --config-file=/etc/cinder/cinder.conf --log-file=/var/log/cinder/volume.log
    cinder   14684  0.1  2.7 225120 56544 ?        Ss   Aug17 151:50 /usr/bin/python /usr/local/bin/cinder-scheduler --config-file=/etc/cinder/cinder.conf --log-file=/var/log/cinder/scheduler.log

If you don't see all the services started, use the following commands to determine why it didn't start.

    sudo -u cinder cinder-api --config-file=/etc/cinder/cinder.conf --log-file=/var/log/cinder/cinder-api.log
    sudo -u cinder cinder-scheduler --config-file=/etc/cinder/cinder.conf --log-file=/var/log/cinder/cinder-scheduler.log
    sudo -u cinder cinder-volume --config-file=/etc/cinder/cinder.conf --log-file=/var/log/cinder/cinder-volume.log

Even though cinder is running you won't be able to create cinder volumes without a volume group named cinder-volumes. If you want to use cinder you need to manually create that volume group on the controller node. If you don't have an existing volume group with free space, you need to add a new disk partition to the controller node. Use the `pvcreate` and `vgcreate` commands to create a volume group with the correct name.

Start the horizon install by installing the package prerequisites for horizon:

    apt-get install -y apache2 libapache2-mod-wsgi memcached python-memcache gettext

Add a horizon user to use for the Apache server:

    useradd --home-dir "/usr/local/lib/python2.7/dist-packages/openstack_dashboard" \
            --create-home \
            --system \
            --shell /bin/false \
            horizon

Clone the horizon git repo:

    git clone https://github.com/openstack/horizon.git -b stable/kilo
    cd horizon

Now, use the python installer to install horizon:

    python setup.py install

Create a directory where horizon can store lock files:

    mkdir /var/lib/openstack-dashboard
    chown horizon:horizon /var/lib/openstack-dashboard/

Make the openstack_dashboard configuration directory and copy the configuration file there:

    mkdir /etc/openstack_dashboard
    cp ~/horizon/openstack_dashboard/local/local_settings.py.example /etc/openstack_dashboard/local_settings.py
    chown -R horizon:horizon /etc/openstack_dashboard/local_settings.py

Remove the Openstack dashboard Python files that were installed earlier (they will be copied back in the next step):

    rm -rf /usr/local/lib/python2.7/dist-packages/openstack_dashboard/*

Due to the way the Django WSGI file is written, create a openstack_dashboard subdirectory and copy the dashboard files there:

    cp -r openstack_dashboard/ /usr/local/lib/python2.7/dist-packages/openstack_dashboard/
    chown -R horizon:horizon /usr/local/lib/python2.7/dist-packages/openstack_dashboard/openstack_dashboard/static
    ln -s /usr/local/lib/python2.7/dist-packages/openstack_dashboard/openstack_dashboard/static /usr/local/lib/python2.7/dist-packages/openstack_dashboard/static
    ln -s /etc/openstack_dashboard/local_settings.py /usr/local/lib/python2.7/dist-packages/openstack_dashboard/openstack_dashboard/local/local_settings.py

Create the Apache configuration files for horizon:

    cat >> /etc/apache2/sites-available/openstack.conf << EOF
    <VirtualHost *:80>
        WSGIScriptAlias / /usr/local/lib/python2.7/dist-packages/openstack_dashboard/openstack_dashboard/wsgi/django.wsgi
        WSGIDaemonProcess horizon user=horizon group=horizon processes=3 threads=10 home=/usr/local/lib/python2.7/dist-packages/openstack_dashboard/openstack_dashboard display-name=%{GROUP}
        WSGIApplicationGroup %{GLOBAL}

        SetEnv APACHE_RUN_USER horizon
        SetEnv APACHE_RUN_GROUP horizon
        WSGIProcessGroup horizon

        DocumentRoot /usr/local/lib/python2.7/dist-packages/openstack_dashboard/openstack_dashboard/.blackhole/
        Alias /media /usr/local/lib/python2.7/dist-packages/openstack_dashboard/openstack_dashboard/static

        <Directory />
            Options FollowSymLinks
            AllowOverride None
        </Directory>

        <Directory /usr/local/lib/python2.7/dist-packages/openstack_dashboard/openstack_dashboard/>
            Options Indexes FollowSymLinks MultiViews
            AllowOverride None
            # Apache 2.4 uses mod_authz_host for access control now (instead of
            #  "Allow")
            <IfVersion < 2.4>
                Order allow,deny
                Allow from all
            </IfVersion>
            <IfVersion >= 2.4>
                Require all granted
            </IfVersion>
        </Directory>

        ErrorLog /var/log/apache2/horizon_error.log
        LogLevel warn
        CustomLog /var/log/apache2/horizon_access.log combined
    </VirtualHost>
    WSGISocketPrefix /var/run/apache2
    EOF

Enable the newly created Openstack horizon web virtual server and disable the default Apache server:

    a2ensite openstack
    a2dissite 00-default

Set Apache to run as the newly created horizon user:

    sed -i 's/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=horizon/g' /etc/apache2/envvars
    sed -i 's/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=horizon/g' /etc/apache2/envvars

Make some configuration setings to **local_settings.py**:

    sed -e 's/DEBUG = True/DEBUG = False/g' /etc/openstack_dashboard/local_settings.py
    sed -i "s/#ALLOWED_HOSTS = \['horizon.example.com', \]/#ALLOWED_HOSTS = \['horizon.example.com', \]\nALLOWED_HOSTS = \['*' \]/g" /etc/openstack_dashboard/local_settings.py

Look for the following lines in **/etc/openstack_dashboard/local_settings.py** and change them from:

    SECRET_KEY = secret_key.generate_or_read_from_file(
    os.path.join(LOCAL_PATH, '.secret_key_store'))

to:

    SECRET_KEY = secret_key.generate_or_read_from_file('/var/lib/openstack-dashboard/secret_key')

Change the CACHES section to:

    CACHES = {
        'default': {
            'BACKEND' : 'django.core.cache.backends.memcached.MemcachedCache',
            'LOCATION' : '127.0.0.1:11211',
        }
    }

    #CACHES = {
    #    'default': {
    #        'BACKEND' : 'django.core.cache.backends.locmem.LocMemCache'
    #    }
    #}

The default Ubuntu Apache configuration uses /horizon as the application root, but we will use `/`
Configure auth redirects:

    sed -i "s|# LOGIN_URL = WEBROOT + 'auth/login/'|LOGIN_URL='/auth/login/|g" /etc/openstack_dashboard/local_settings.py
    sed -i "s|# LOGOUT_URL = WEBROOT + 'auth/logout/'|LOGOUT_URL='/auth/logout/'|g" /etc/openstack_dashboard/local_settings.py
    sed -i "s|# LOGIN_REDIRECT_URL = WEBROOT|LOGIN_REDIRECT_URL='/'|g" /etc/openstack_dashboard/local_settings.py

Download the novnc software so that we can use the dashboard to access the console for each VM:

    git clone git://github.com/kanaka/noVNC

Now move the novnc files to a location where horizon expects them:

    mkdir /usr/share/novnc
    cp -r noVNC/* /usr/share/novnc

Install novnc prerequisites:

    apt-get install libjs-jquery libjs-sphinxdoc libjs-swfobject libjs-underscore

Generate the `nova-novncproxy` upstart script:

    cat >> /etc/init/nova-novncproxy.conf << EOF
    description "Nova novnc proxy worker"

    start on runlevel [2345]
    stop on runlevel [!2345]

    chdir /var/run

    pre-start script
            mkdir -p /var/run/nova
            chown nova:root /var/run/nova/

            mkdir -p /var/lock/nova
            chown nova:root /var/lock/nova/

            modprobe nbd
    end script
    EOF

Start the `nova-novncproxy` service and restart Apache to read the configuration changes:

    start nova-novncproxy
    service apache2 restart

Verify that the `nova-novncproxy` service is running:

    ps aux|grep nova-novncproxy

You should see output similar to:

    root@controller:~# ps aux|grep nova-novncproxy
    nova      2764  0.0  1.8 144432 37288 ?        Ss   Aug17   0:35 /usr/bin/python /usr/local/bin/nova-novncproxy --config-file=/etc/nova/nova.conf --log-file=/var/log/nova/nova-novnc.log


If the service didn't start, use the following command to test nova-novncproxy and get log output:

    sudo -u nova nova-novncproxy --config-file=/etc/nova/nova.conf

That finishes up the OpenStack install. You can point your browser to the outside interface on the controller node and access the OpenStack dashboard. The login credentials are in the openrc file in the `/root` directory on the controller node. Good luck with your newly created OpenStack setup.


