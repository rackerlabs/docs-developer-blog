---
layout: post
title: Install OpenStack from source - part 5
date: '2015-08-13 06:59'
comments: true
author: Phil Hopkins
published: true
categories:
  - OpenStack
  - OSAD
---

This is the fifth installment in a series of installing OpenStack from source. The four previous articles can be found here:

* [Install Keystone,](https://developer.rackspace.com/blog/install-openstack-from-source/)
* [Install Glance and Neutron](https://developer.rackspace.com/blog/install-openstack-from-source2/)
* [Install Nova](https://developer.rackspace.com/blog/install-openstack-from-source3/)
* [Install Neutron on the Network node](https://developer.rackspace.com/blog/install-openstack-from-source4/)

We installed the Identity service (keystone), Image service (glance), Networking service (neutron) and the Compute service (nova) onto the controller node, and then we turned our attention to the network node to install the neutron agents to support the network layers two and three. Now, we turn our attention to the compute node to install both neutron and nova.

<!-- more -->

We are close to finishing our install of OpenStack - this section finishes the basic OpenStack install. We will be able to create networks and start VMs with this article, leaving only cinder and horizon for the last artice.

Install the following packages, which are prerequisites for some of the pip packages installed next.

    apt-get install -y git ipset keepalived conntrack conntrackd arping openvswitch-switch dnsmasq-utils dnsmasq libxml2-dev libxslt1-dev libmysqlclient-dev libffi-dev libssl-dev
    apt-get install -y libvirt-bin qemu-kvm libpq-dev python-libvirt genisoimage kpartx parted vlan multipath-tools sg3-utils libguestfs0 python-guestfs python-dev sysfsutils pkg-config
    pip install pbr

Set some shell variables that we use:

    cat >> .bashrc << EOF
    MY_IP=10.0.1.6
    MY_PRIVATE_IP=10.0.1.4
    MY_PUBLIC_IP=10.0.0.4
    LOCAL_DATA_IP=10.0.2.6
    EOF

Note: if your networking environment is different from this one, the IPs used above may have to be adjusted. The variables `MY_PRIVATE_IP` and `MY_PUBLIC_IP` refer to the interface with the API access on the controller node. The variable `MY_IP`is the interface on the compute node that is connected to the API interface on the controller node. The variable `LOCAL_DATA_IP` is the IP of the interface on the compute node over which tenant network traffic travels and is connected to the corresponding interface on the network node. Refer to the graphic in the first article in the series.

Run the following command to set the variables in the current shell session:

    source .bashrc

Like we have done on the controller and network nodes, we need to create users under which the associated services run. The following script creates these services, along with the directories that they need and provides the configuration file to rotate the log files.

    for SERVICE in neutron nova
    do

    useradd --home-dir "/var/lib/$SERVICE" \
            --create-home \
            --system \
            --shell /bin/false \
            $SERVICE
    if [ "$SERVICE" == 'nova' ]
      then
        usermod -G libvirtd $SERVICE
    fi

    mkdir -p /var/log/$SERVICE
    mkdir -p /var/lib/$SERVICE
    mkdir -p /etc/$SERVICE

    chown -R $SERVICE:$SERVICE /var/log/$SERVICE
    chown -R $SERVICE:$SERVICE /var/lib/$SERVICE
    chown $SERVICE:$SERVICE /etc/$SERVICE

    if [ "$SERVICE" == 'neutron' ]
      then
        mkdir -p /etc/neutron/plugins/ml2
        mkdir -p /etc/neutron/rootwrap.d
    fi

    cat >> /etc/logrotate.d/$SERVICE << EOF
    /var/log/$SERVICE/*.log {
            daily
            missingok
            rotate 7
            compress
            notifempty
            nocreate
    }
    EOF

    done

Set Ubuntu defaults to use a config option, when using the upstart scripts, to start the neutron processes:

    cat > /etc/default/neutron << EOF
    --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini
    EOF

Create some additional needed directories for nova and set the proper permissions:

    mkdir /var/lib/nova/keys
    mkdir /var/lib/nova/locks
    mkdir /var/lib/nova/instances
    chown -R nova:nova /var/lib/nova

Now clone the neutron repo:

    git clone https://github.com/openstack/neutron.git -b stable/kilo

Copy the downloaded configuration files from the cloned repo:

    cp neutron/etc/* /etc/neutron/
    cp -R neutron/etc/neutron/plugins/ml2/* /etc/neutron/plugins/ml2
    cp -R neutron/etc/neutron/rootwrap.d/* /etc/neutron/rootwrap.d

Install the neutron Python scripts:

    cd neutron
    python setup.py install
    cd ~

Give the neutron sudo access, limited by rootwrap, to the commands for which neutron needs root privileges to execute:

    cat > /etc/sudoers.d/neutron_sudoers << EOF
    Defaults:neutron !requiretty

    neutron ALL = (root) NOPASSWD: /usr/local/bin/neutron-rootwrap  /etc/neutron/rootwrap.conf *
    EOF
    chmod 440 /etc/sudoers.d/neutron_sudoers

Now build the **neutron.conf** file. Like we did on the controller and network nodes, we are not going to use the **neutron.conf** file that came when we cloned the neutron repo. Instead, it is built from scratch (this one is much shorter that the ones on the controller and network nodes):

    rm /etc/neutron/neutron.conf
    cat > /etc/neutron/neutron.conf << EOF
    [DEFAULT]
    verbose = True
    core_plugin = ml2
    service_plugins = router
    allow_overlapping_ips = True

    [oslo_messaging_rabbit]
    rabbit_host = $MY_PRIVATE_IP

    [oslo_concurrency]
    lock_path = /var/lock/neutron

    [agent]
    root_helper=sudo /usr/local/bin/neutron-rootwrap /etc/neutron/rootwrap.conf
    EOF

Like we have done on the previous nodes, we configure the neutron ML2 plugin agent to use GRE tunnels for project network isolation. The ml2 plugin configuration file:

    rm /etc/neutron/plugins/ml2/ml2_conf.ini
    cat > /etc/neutron/plugins/ml2/ml2_conf.ini << EOF
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

    [ovs]
    local_ip = $LOCAL_DATA_IP
    enable_tunneling = True

    [agent]
    tunnel_types = gre
    EOF

    chown neutron:neutron /etc/neutron/*.{conf,json,ini}
    chown -R neutron:neutron /etc/neutron/plugins

Lastly, for the network node we create the neutron upstart script files, for only the Open vSwitch agent:

    cat > /etc/init/neutron-openvswitch.conf << EOF
    # vim:set ft=upstart ts=2 et:

    #start on runlevel [2345]
    #stop on runlevel [!2345]

    script
      [ -r /etc/default/neutron-server ] && . /etc/default/neutron-server
      [ -r "\$NEUTRON_PLUGIN_CONFIG" ] && CONF_ARG="--config-file \$NEUTRON_PLUGIN_CONFIG"
    exec start-stop-daemon --start --chuid neutron --exec /usr/local/bin/neutron-openvswitch-agent -- --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini --log-file=/var/log/neutron/openvswitch-agent.log \$CONF_ARG
    end script
    EOF

With the agents configured and the startup scripts in place, let's start everything up:

    start neutron-openvswitch

Wait 20 to 30 seconds and verify that everything started:

    ps aux|grep neutron

If you don't see a line of output for the `neutron-openvswitch-agent` process, use the following command to start the process. The output provides information why the `neutron-openvswitch-agent` is not running.

    sudo -u neutron neutron-openvswitch-agent --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini --log-file=/var/log/neutron/openvswitch-agent.log

Next we turn our attention to installing nova on the compute node. We have already created the nova user and the major required directories. So clone the nova repo:

    git clone https://github.com/openstack/nova.git -b stable/kilo

Copy the downloaded (cloned) configuration files to their proper location in the **etc** directory:

    cd nova
    cp -r etc/nova/* /etc/nova/

And install the nova Python scripts:

    python setup.py install
    cd ~

Give the nova sudo access, limited by rootwrap, to the commands for which nova needs root privileges to execute:

    cat > /etc/sudoers.d/nova_sudoers << EOF
    Defaults:nova !requiretty

    nova ALL = (root) NOPASSWD: /usr/local/bin/nova-rootwrap  /etc/nova/rootwrap.conf *
    EOF

    chmod 440 /etc/sudoers.d/nova_sudoers

Now create the **nova.conf** file. Use the [OpenStack Config Reference Guide](http://docs.openstack.org/kilo/config-reference/content/) to familarize yourself with each of the parameters being set:

    cat > /etc/nova/nova.conf << EOF
    [DEFAULT]
    #verbose = True
    dhcpbridge_flagfile = /etc/nova/nova.conf
    dhcpbridge = /usr/local/bin/nova-dhcpbridge
    logdir = /var/log/nova
    state_path = /var/lib/nova
    lock_path = /var/lock/nova
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
    vncserver_proxyclient_address = $MY_PRIVATE_IP
    vncserver_listen  = 0.0.0.0

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

Since this is the compute node, we need to configure the **nova-compute.conf** file and to set the proper privileges for the file:

    cat > /etc/nova/nova-compute.conf << EOF
    [DEFAULT]
    compute_driver=libvirt.LibvirtDriver
    [libvirt]
    virt_type=kvm
    EOF

    chown nova:nova /etc/nova/*.{conf,json,ini}

On compute nodes load the nbd module. The start script does this also, but we do this here to ensure that there are no problems with loading the module:

    modprobe nbd
    depmod

And lastly, create the needed nova upstart script:

    cat > /etc/init/nova-compute.conf << EOF
    description "Nova compute worker"
    author "Soren Hansen <soren@linux2go.dk>"

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

    exec start-stop-daemon --start --chuid nova --exec /usr/local/bin/nova-compute -- --config-file=/etc/nova/nova.conf --config-file=/etc/nova/nova-compute.conf
    EOF

Now start the nova-compute process and verify that it stays running:

    start nova-compute

Wait 20 to 30 seconds and verify that everything started:

    ps aux|grep nova

And you should see something like this:

    root@compute:~# ps aux|grep nova
    nova      2026  0.3 38.1 2830936 1546308 ?     Ssl  May04 525:17 /usr/bin/python /usr/local/bin/nova-compute --config-file=/etc/nova/nova.conf --config-file=/etc/nova/nova-compute.conf

If by chance the nova-compute service didn't start or stay running, use the following command to test and get log output to debug the reason for the failure:

    sudo -u nova nova-compute --config-file=/etc/nova/nova.conf --config-file=/etc/nova/nova-compute.conf

With nova-compute running, lets test everything by booting a VM. Log into the controller node and source the admin cerdentials:

    source adminrc

Create a network named private:

    root@controller:~# neutron net-create private
    Created a new network:
    +---------------------------+--------------------------------------+
    | Field                     | Value                                |
    +---------------------------+--------------------------------------+
    | admin_state_up            | True                                 |
    | id                        | 90c0dea3-425a-47f5-8df1-8d3fa57067ba |
    | name                      | private                              |
    | provider:network_type     | vxlan                                |
    | provider:physical_network |                                      |
    | provider:segmentation_id  | 100                                  |
    | router:external           | False                                |
    | shared                    | False                                |
    | status                    | ACTIVE                               |
    | subnets                   |                                      |
    | tenant_id                 | 9d314f96330a4e459420623a922e2c09     |
    +---------------------------+--------------------------------------+

On the network named private, attach a subnet named private-subnet with a CIDR 10.1.0.0/28:

    root@controller:~#     neutron subnet-create --name private-subnet private 10.1.0.0/28
    Created a new subnet:
    +-------------------+-------------------------------------------+
    | Field             | Value                                     |
    +-------------------+-------------------------------------------+
    | allocation_pools  | {"start": "10.1.0.2", "end": "10.1.0.14"} |
    | cidr              | 10.1.0.0/28                               |
    | dns_nameservers   |                                           |
    | enable_dhcp       | True                                      |
    | gateway_ip        | 10.1.0.1                                  |
    | host_routes       |                                           |
    | id                | 6f3f8445-e558-4bba-9521-90b2c0a8e850      |
    | ip_version        | 4                                         |
    | ipv6_address_mode |                                           |
    | ipv6_ra_mode      |                                           |
    | name              | private-subnet                            |
    | network_id        | 90c0dea3-425a-47f5-8df1-8d3fa57067ba      |
    | tenant_id         | 9d314f96330a4e459420623a922e2c09          |
    +-------------------+-------------------------------------------+

And boot an instance, **MyFirstInstance**, using the previously loaded image named cirros-qcow2, using a flavor with id 1:

    root@controller:~# nova boot --image cirros-qcow2 --flavor 1 MyFirstInstance
    +--------------------------------------+-----------------------------------------------------+
    | Property                             | Value                                               |
    +--------------------------------------+-----------------------------------------------------+
    | OS-DCF:diskConfig                    | MANUAL                                              |
    | OS-EXT-AZ:availability_zone          | nova                                                |
    | OS-EXT-SRV-ATTR:host                 | -                                                   |
    | OS-EXT-SRV-ATTR:hypervisor_hostname  | -                                                   |
    | OS-EXT-SRV-ATTR:instance_name        | instance-00000014                                   |
    | OS-EXT-STS:power_state               | 0                                                   |
    | OS-EXT-STS:task_state                | scheduling                                          |
    | OS-EXT-STS:vm_state                  | building                                            |
    | OS-SRV-USG:launched_at               | -                                                   |
    | OS-SRV-USG:terminated_at             | -                                                   |
    | accessIPv4                           |                                                     |
    | accessIPv6                           |                                                     |
    | adminPass                            | 3bt5L2Jr5uYv                                        |
    | config_drive                         |                                                     |
    | created                              | 2015-08-12T12:24:14Z                                |
    | flavor                               | m1.tiny (1)                                         |
    | hostId                               |                                                     |
    | id                                   | 48c0066a-f16e-414d-89ed-4b93496d0d8f                |
    | image                                | cirros-qcow2 (394aee69-53bc-4290-af3b-05fb4150023b) |
    | key_name                             | -                                                   |
    | metadata                             | {}                                                  |
    | name                                 | MyFirstInstance                                     |
    | os-extended-volumes:volumes_attached | []                                                  |
    | progress                             | 0                                                   |
    | security_groups                      | default                                             |
    | status                               | BUILD                                               |
    | tenant_id                            | 9d314f96330a4e459420623a922e2c09                    |
    | updated                              | 2015-08-12T12:24:14Z                                |
    | user_id                              | 2f9cf7c3b3674c0e9cff5143ea633a59                    |
    +--------------------------------------+-----------------------------------------------------+

Finally, use the nova list command to verify that the image booted. You may have to run this several times, or wait a few seconds, to give your newly created OpenStack system time to boot its first VM.

    root@controller:~# nova list
    +--------------------------------------+-----------------+--------+------------+-------------+------------------+
    | ID                                   | Name            | Status | Task State | Power State | Networks         |
    +--------------------------------------+-----------------+--------+------------+-------------+------------------+
    | 48c0066a-f16e-414d-89ed-4b93496d0d8f | MyFirstInstance | ACTIVE | -          | Running     | private=10.1.0.2 |
    +--------------------------------------+-----------------+--------+------------+-------------+------------------+

Congratulations, you have successfully gotten OpenStack running from a source install. Want to update a service with the latest patches? It's simple! In the following section, we update nova on the controller node.

    cd nova
    git pull

Now update the installed Python scripts:

    python setup.py install

And lastly, restart the associated services:

    restart nova-api
    restart nova-cert
    restart nova-consoleauth
    restart nova-conductor
    restart nova-scheduler

That was easy. In the next and concluding article of this series, we go to the controller node and install the Volume service (cinder) and the web based dashboard (horizon).



