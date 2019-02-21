---
layout: post
date: '2015-08-11 23:59'
title: Install OpenStack from source - part 4
comments: true
author: Phil Hopkins
published: true
categories:
  - OpenStack
  - OSAD
---

This is the fourth installment, in a series showing how to install OpenStack from source. In the three previous articles:

* [Install Keystone](https://developer.rackspace.com/blog/install-openstack-from-source/)
* [Install Glance and Neutron](https://developer.rackspace.com/blog/install-openstack-from-source2/)
* [Install Nova](https://developer.rackspace.com/blog/install-openstack-from-source3/)

We installed the Identity service (keystone), Image service (glance), Networking service (neutron) and the Compute service (nova) onto the controller node. In this section, we turn our attention to the network node, to install the neutron agents to support network layers two and three.

<!-- more -->

These network functions could run on the controller node. In this example, for ease of understanding the various pieces of OpenStack, the network functions that are separate from those that must run on a compute node are placed on a separate machine. This architecture also makes it simpler to examine tenant network traffic for those trying to understand how neutron functions.

Neutron supports two layer 2 technologies, Open vSwitch and Linux bridge. You want to review the OpenStack Networking guide for more information about each of these two technologies. For this installation, I have selected Open vSwitch, but Linux bridge would be an equally functional choice.

On this new machine, let's start by making sure this system is updated and ready for the neutron installation:

    apt-get update; apt-get dist-upgrade -y;reboot

Set some shell variables that we need:

    cat >> .bashrc << EOF
    MY_IP=10.0.1.5
    MY_PRIVATE_IP=10.0.1.4
    MY_PUBLIC_IP=10.0.0.4
    LOCAL_DATA_IP=10.0.2.5
    EOF

Note: the IPs used above may have to be adjusted to your environment, if different from this one. The Variables, `MY_PRIVATE_IP` and `MY_PUBLIC_IP`, refer to the interface with the API access on the controller node. The variable, `MY_IP`, the interface on the network node that is connected to the API interface on the controller node. The variable, `LOCAL_DATA_IP`, is the IP of the interface on the network node over which tenant network traffic travels and is connected to the corresponding interface on the compute node. Refer to the graphic in the first article in the series.

Run the following to set the variables in the current shell session:

    source .bashrc

Some of the pip prerequisites have a couple package prerequisites that aren't automatically installed. Also the compute and network nodes need a few additional packages. Install these packages now:

    apt-get install -y git ipset keepalived conntrack conntrackd arping openvswitch-switch dnsmasq-utils dnsmasq python-dev libffi-dev libssl-dev libmysqlclient-dev
    pip install pbr
    pip install mysql-python

Add a neutron user so that the neuron service can run under the neutron user's permissions:

    useradd --home-dir "/var/lib/neutron" \
            --create-home \
            --system \
            --shell /bin/false \
            neutron

Similar to what we did on the controller node, we need to make several directories for the neutron process and set proper ownership for those directories.

    mkdir -p /var/log/neutron
    mkdir -p /var/lib/neutron/
    mkdir -p /etc/neutron
    mkdir -p /etc/neutron/plugins/ml2
    mkdir -p /etc/neutron/rootwrap.d

    chown -R neutron:neutron /var/log/neutron
    chown -R neutron:neutron /var/lib/neutron
    chown -R neutron:neutron /etc/neutron

Set Ubuntu defaults to use a config option when using the upstart scripts, to start the neutron processes:

    cat >> /etc/default/neutron << EOF
    --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini
    EOF

We must remember to rotate the neutron log files:

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

Now, clone the neutron git repo locally:

    git clone https://github.com/openstack/neutron.git -b stable/kilo

Copy the downloaded (cloned) configuration files to their proper location in the **etc** directory:

    cp neutron/etc/* /etc/neutron/
    cp -R neutron/etc/neutron/plugins/ml2/* /etc/neutron/plugins/ml2
    cp -R neutron/etc/neutron/rootwrap.d/* /etc/neutron/rootwrap.d

Use the python installer to install the code:

    cd neutron
    python setup.py install
    cd ~

    restart openvswitch-switch

Next, build the **neutron.conf** file. Like we did on the controller node, we are not going to use the **neutron.conf** file that came when we cloned the neutron repo. Instead, it is built from scratch:

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

Again neutron supports multiple networking layer 2 technologies through the ML2 plugin. First, we configure the neutron ML2 plugin agent to use GRE tunnels for project network isolation, then configure the dhcp and l3 agent files. The ml2 plugin configuration file:

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

Now configure the **dhcp.conf** files. The neutron dhcp agent provides IPs to our VMs, network namespaces are enabled, as well as the information supporting the metadata agent:

    sed -i 's/# interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver/interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver/g' /etc/neutron/dhcp_agent.ini
    sed -i 's/# dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq/dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq/g' /etc/neutron/dhcp_agent.ini
    sed -i 's/# use_namespaces = True/use_namespaces = True/g' /etc/neutron/dhcp_agent.ini
    sed -i 's/# enable_isolated_metadata = False/enable_isolated_metadata = True/g' /etc/neutron/dhcp_agent.ini
    sed -i 's/# enable_metadata_network = False/enable_metadata_network = True/g' /etc/neutron/dhcp_agent.ini

Set the l3 agent config file to use the proper driver for Open vSwitch and to use network namespaces:

    sed -i 's/# interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver/interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver/g' /etc/neutron/l3_agent.ini
    sed -i 's/# use_namespaces = True/use_namespaces = True/g' /etc/neutron/l3_agent.ini

Lastly we configure the metadata agent config file:

    sed -i "s/# nova_metadata_ip = 127.0.0.1/nova_metadata_ip = $MY_PRIVATE_IP/g" /etc/neutron/metadata_agent.ini
    sed -i 's/# nova_metadata_port = 8775/nova_metadata_port = 8775/g' /etc/neutron/metadata_agent.ini
    sed -i 's/# metadata_proxy_shared_secret =/metadata_proxy_shared_secret = openstack/g' /etc/neutron/metadata_agent.ini
    sed -i "s|auth_url = http://localhost:5000/v2.0|auth_url = http://$MY_PRIVATE_IP:5000/v2.0|g" /etc/neutron/metadata_agent.ini
    sed -i 's/%SERVICE_TENANT_NAME%/service/g' /etc/neutron/metadata_agent.ini
    sed -i 's/%SERVICE_USER%/neutron/g' /etc/neutron/metadata_agent.ini
    sed -i 's/%SERVICE_PASSWORD%/notneutron/g' /etc/neutron/metadata_agent.ini

Set permissions on the configuration files so that the neutron agents can read them, when they run as the neutron user:

    chown neutron:neutron /etc/neutron/*.{conf,json,ini}
    chown -R neutron:neutron /etc/neutron/plugins

Many of the OpenStack services need root access to run certain commands. For security reasons, we don't want to give them full root access to a system, so OpenSack has created a wrapper used in conjuction with sudo to limit each service to only the commands that they need, using a tool called rootwrap. Give the neutron user sudo access, limited by rootwrap, to the commands that neutron needs root privileges to execute:

    cat > /etc/sudoers.d/neutron_sudoers << EOF
    Defaults:neutron !requiretty

    neutron ALL = (root) NOPASSWD: /usr/local/bin/neutron-rootwrap  /etc/neutron/rootwrap.conf *
    EOF
    chmod 440 /etc/sudoers.d/neutron_sudoers

Lastly, for the network node we create the neutron upstart script files, first for the Open vSwitch agent:

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

For the neutron l3 agent:

    cat > /etc/init/neutron-l3-agent.conf << EOF
    # vim:set ft=upstart ts=2 et:

    respawn

    start on runlevel [2345]
    stop on runlevel [!2345]

    script
      exec start-stop-daemon --start --chuid neutron --exec /usr/local/bin/neutron-l3-agent -- --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/l3_agent.ini --log-file=/var/log/neutron/l3-agent.log
    end script
    EOF

The neutron dhcp agent:

    cat > /etc/init/neutron-dhcp-agent.conf << EOF
    # vim:set ft=upstart ts=2 et:

    start on runlevel [2345]
    stop on runlevel [!2345]

    script
      exec start-stop-daemon --start --chuid neutron --exec /usr/local/bin/neutron-dhcp-agent -- --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/dhcp_agent.ini --log-file=/var/log/neutron/dhcp-agent.log
    end script
    EOF

And the neutron metadata agent:

    cat > /etc/init/neutron-metadata-agent.conf << EOF
    # vim:set ft=upstart ts=2 et:

    start on runlevel [2345]
    stop on runlevel [!2345]

    script
    exec start-stop-daemon --start --chuid neutron --exec /usr/local/bin/neutron-metadata-agent -- \
       --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/metadata_agent.ini \
       --log-file=/var/log/neutron/metadata-agent.log
    end script
    EOF

With the agents configured and the startup scripts in place, let's start everything up:

    start neutron-openvswitch
    start neutron-dhcp-agent
    start neutron-l3-agent
    start neutron-metadata-agent

Wait 20 to 30 seconds and verify that everything started:

    ps aux|grep neutron

There should be a line of output for each agent showing the agent's process information. such as:

    root@network:~# ps aux|grep neutron
    neutron   1305  0.0  2.5 110556 39336 ?        Ss   May04  24:25 /usr/bin/python /usr/local/bin/neutron-dhcp-agent --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/dhcp_agent.ini --log-file=/var/log/neutron/dhcp-agent.log
    neutron   1311  0.0  2.7 113336 42376 ?        Ss   May04  23:34 /usr/bin/python /usr/local/bin/neutron-l3-agent --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/l3_agent.ini --log-file=/var/log/neutron/l3-agent.log
    neutron   1597  0.3  2.2 105764 34552 ?        Ss   May04 432:22 /usr/bin/python /usr/local/bin/neutron-openvswitch-agent --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini --log-file=/var/log/neutron/openvswitch-agent.log
    neutron  20243 19.3  2.5 199676 39876 ?        Ss   14:00   0:00 /usr/bin/python /usr/local/bin/neutron-metadata-agent --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/metadata_agent.ini --log-file=/var/log/neutron/metadata-agent.log

If by chance one or more of the agents don't start or stay running, use the following to test and get log output to debug the reason for the failure:

    sudo -u neutron neutron-openvswitch-agent --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/plugins/ml2/ml2_conf.ini --log-file=/var/log/neutron/openvswitch-agent.log
    sudo -u neutron neutron-metadata-agent --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/metadata_agent.ini --log-file=/var/log/neutron/metadata-agent.log
    sudo -u neutron neutron-dhcp-agent --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/dhcp_agent.ini --log-file=/var/log/neutron/dhcp-agent.log
    sudo -u neutron neutron-l3-agent --config-file=/etc/neutron/neutron.conf --config-file=/etc/neutron/l3_agent.ini --config-file=/etc/neutron/fwaas_driver.ini --log-file=/var/log/neutron/l3-agent.log


To verify that the agents communicated with the controller processes, log in on the controller node as root and run the following, which should show that the controller received messages from the agents running on the network node:

    source adminrc
    neutron agent-list

You should see output similar to:

    root@controller:~# neutron agent-list
    +--------------------------------------+--------------------+----------+-------+----------------+---------------------------+
    | id                                   | agent_type         | host     | alive | admin_state_up | binary                    |
    +--------------------------------------+--------------------+----------+-------+----------------+---------------------------+
    | 7856ba29-5447-4392-b2e1-2c236bd5f479 | Metadata agent     | network  | :-)   | True           | neutron-metadata-agent    |
    | b45096a1-7bfa-4816-8b3c-900b752a9c08 | DHCP agent         | network  | :-)   | True           | neutron-dhcp-agent        |
    | e5a4e06b-dd9d-4b97-a09a-c8ba07706753 | Openvswitch agent  | network  | :-)   | True           | neutron-openvswitch-agent |
    | f9f94732-08af-4f82-8908-fdcd69ab12e8 | L3 agent           | network  | :-)   | True           | neutron-l3-agent          |
    +--------------------------------------+--------------------+----------+-------+----------------+---------------------------+

There should be a line for each of the four agents running on the network node and they should all have a "smiley face" in the alive column.

Now that the network node is up and running, in the next article of this series, we start configuring the compute node and start the nova-compute agent and neutron `openvswitch` agents there.
