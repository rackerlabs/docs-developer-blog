---
layout: post
title: Software-defined networks in the Havana release of Openstack – Part 2
date: '2014-02-24 09:30'
comments: true
author: Phil Hopkins
published: true
categories:
  - OpenStack
  - Neutron
---

Software Defined Networks in the Havana release of Openstack – Part 2

In the [first article](https://developer.rackspace.com/blog/software-defined-networks-in-the-havana-release-of-openstack.html)
in this series, we looked at a simple OpenStack setup with one controller node,
one compute node, and one network node. Two tenants had been created with two
simple networks. In this article we will turn our attention to the network paths
for each of the three VMs that were created. The diagrams in the first article
are useful in understanding this discussion.

Discussion hen continues with the first half of the iptables chains that are
interjected between the VM and the Open vSwitch process (OVS) on the compute
node. In order to keep these articles in bite sized chunks, we will end this s
ection after looking at the first two iptables chains, those starting with
neutron – which manage the security group rules, the next article continue s
through the iptables chains looking at those starting with nova and concludes by
reviewing how two different types of packets progress through these chains.

<!-- more -->

In order to apply the Neutron security group rules that are be created for each
VM, iptables are used on the compute node to filter traffic going to and from
the VMs. This changed from the Grizzly release where security group rules were
managed by the Neutron network processes rather than that of the Nova processes.
This change implemented improved security filtering, providing both ingress and
egress filters on each VM.  In order to allow iptables to filter traffic to and
from the VMs, the network path out of the VMs has changed. Using Neutron security
groups causes the nova-compute service to build the path from the VM to the OVS
process as shown in the following diagram:

{% img center software-defined-networks-in-the-havana-release-of-openstack-part-2/computenode1.png 744 504 %}

Looking at VM1, when it is created the VM's eth0 interface is connected to a
Linux tap device tapxxx which is plugged into a newly created Linux bridge,
qbrxxx. Into this bridge, one end of a virtual Ethernet pair (qvbxxx) is attached,
and the other half of the veth pair (qvoxxx) is placed into the OVS process. The
setup is more complicated than the older Nova security group configuration, which
plugged the tap interface directly into the OVS process. This  setup has the
advantage that packets can be filtered when passing into or out of the Linux
bridge. The packets now transverse the iptables FORWARD chain on the compute node
and filters can be applied into this chain. This is a big improvement to Nova
security group rules since this technique will filter any packets passing into
or out of a specific VM. Formerly using Nova security group rules, iptables
filtering occurred within the network namespace on the network node. Traffic
going between VMs on the same subnet would not pass through the network node or
be filtered which could potentially allow a compromised VM to attack other VMs
on the same subnet.

Please note that although most packets passing through the Linux bridge to or
from the VMs principally pass through the FORWARD chain, packets can occur that
get directed to the INPUT or OUTPUT chains. These chains have rules that use the
same sub-chains that the FORWARD table uses, resulting in the same filters being
used regardless of a packet's flow through the iptables processing.

Starting with VM1, which resides within the test tenant which has two VMs on this
[pik kl0,.-network, we first find the port UUID for VM1:

```bash
root@controller:~# neutron port-list
+--------------------------------------+------+-------------------+---------------------------------------------------------------------------------+
| id                                   | name | mac_address       | fixed_ips                                                                       |
+--------------------------------------+------+-------------------+---------------------------------------------------------------------------------+
| 67c49753-bf85-4eae-a5a3-faa48fdab983 |      | fa:16:3e:dc:be:eb | {"subnet_id": "fc54a4af-450d-405e-9337-fbdb7e94e008", "ip_address": "10.1.0.2"} |
```

The `xxx` used in the above drawing is the first 10 characters of the UUID,
or `67c49753-bf`, for this VM. This information is needed when looking at the
packet flow through the iptables rules created on the compute node. As we will
see, some of the chains are named by this VM's port identifier so having this
information enables us to identify which rules apply the which VM.

The complete iptables rules on the compute node with these three VMs are very
long, in order to simplify this discussion only the FORWARD chain is reviewed
and is limited to the rules for the above mentioned VM. The various iptables
chains shown have been edited to show only the rules that apply to this VM.

Iptables rules are composed of a series of chains through which a packet progresses.
There are four possibilities that can happen to a packet in these rules. First,
a packet might match a rule that has a -j `ACCEPT` or `DROP` target. A packet
matching this rule is either accepted, exits the iptables processing and continues
through the Linux network stack, or is dropped depending on the target. A packet
might match a rule and be directed to another chain for processing. A packet
might match a rule with a `RETURN` target and be returned to the calling chain
to continue processing. Finally, the packet might reach the end of a the `FORWARD`
chain. In this case, the target specified by the chain policy determines the
fate of the packet.

Consider the trimmed output of the `iptables -L -n -v --line-numbers` command
run on the compute node:


```bash
root@openstack-ubu-compute:~# iptables -L -n -v --line-numbers

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target                    prot opt in     out     source               destination
1    12489 1110K neutron-filter-top        all  --  *      *       0.0.0.0/0            0.0.0.0/0
2    12489 1110K neutron-openvswi-FORWARD  all  --  *      *       0.0.0.0/0            0.0.0.0/0
3        2   616 nova-filter-top           all  --  *      *       0.0.0.0/0            0.0.0.0/0
4        0     0 nova-compute-FORWARD      all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

The `FORWARD` chain has a default policy of `ACCEPT` and references four chains.
The match conditions for each of these rules are source **0.0.0.0/0** and
destination **0.0.0.0/0**, all IP protocols, and any TCP or UDP ports, if
specified. These conditions will match any packet. As such packets entering the
`FORWARD` chain are processed by each successive chain until an `ACCEPT` or `DROP`
target is encountered. If not, the default policy of `ACCEPT` is applied. Notice
that at the time the iptables were examined from the information given in the
pkts statistics column that no packets had made it through to the point of being
directed to the nova-compute-FORWARD chain.

There are four chains referenced in the rules for the FORWARD chain. The two that
start with Neutron are managed by the neutron security group rules process.
Default security group rules allow all outgoing traffic, VMs on the network can
communicate with each other (i.e. VM1 And VM2 can communicate without restrictions),
all inbound traffic is blocked and ARP and DHCP request/reply packets between
devices on this network are allowed. Additionally two security group rules have
been added to allow inbound ICMP traffic and tcp traffic on port 22.

The neutron-filter-top chain:

```bash
Chain neutron-filter-top (2 references)
num   pkts bytes target     prot opt in     out     source               destination
1    3534K  668M neutron-openvswi-local  all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

sends all packets to the neutron-openvswi-local chain. However the neutron-openvswi-local
does not have any rules so the packet will return back to the FORWARD chain. In
this situation this set of chains does not affect any packets.

In the chain neutron-openvswi-FORWARD the real work starts. Looking at this chain we see:

```bash
Chain neutron-openvswi-FORWARD (1 references)
num   pkts bytes target                        prot opt in     out     source               destination
1     3598  283K neutron-openvswi-sg-chain  all  --  *      *       0.0.0.0/0            0.0.0.0/0            PHYSDEV match --physdev-out tap67c49753-bf --physdev-is-bridged
2     3615  394K neutron-openvswi-sg-chain  all  --  *      *       0.0.0.0/0            0.0.0.0/0            PHYSDEV match --physdev-in tap67c49753-bf --physdev-is-bridged
```

Rules one and two in this chain send packets that match the conditions
`--physdev-out tap67c49753-bf --physdev-is-bridged` or
`--physdev-in tap67c49753-bf --physdev-is-bridged`, these rules send the packets
passing through a Linux bridge coming from or going to the device – tap67c49753-bf,
to the chain neutron-openvswi-sg-chain. The interface tap67c49753-bf  is the
interface attached to VM1, which we are considering in this example.

Continuing with the chain neutron-openvswi-sg-chain, which is called by the
previous chain:

```bash
Chain neutron-openvswi-sg-chain (6 references)
num   pkts bytes target                        prot opt in     out     source               destination
1     3598  283K neutron-openvswi-i67c49753-b  all  --  *      *       0.0.0.0/0            0.0.0.0/0            PHYSDEV match --physdev-out tap67c49753-bf --physdev-is-bridged
2     3615  394K neutron-openvswi-o67c49753-b  all  --  *      *       0.0.0.0/0            0.0.0.0/0            PHYSDEV match --physdev-in tap67c49753-bf --physdev-is-bridged
3    11069 1012K ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Rule one sends packets coming out of the bridge going to the interface
tap67c49753-bf (the VM) to the chain neutron-openvswi-i67c49753-b. The next rule
matches packets going into the bridge, coming from the VM, sending them into the
chain neutron-openvswi-o67c49753-b which cover the two cases of packets sent to
this chain going to and from the VM. As we will see next, these two chains drop
any packets that don't fit the security group rules and return all packets
passing the rules back to this chain. Rule 3 will apply the -j ACCEPT target to
any packets making it through rules 1 and 2 or packets not matching the conditions
on these two rules, i.e. packets in the FORWARD chian but not passing through
the Linux bridge. These packets are accepted and will exit the FORWARD iptables
chain.

Now the chain  neutron-openvswi-i67c49753-b which processes the packets coming
out of the bridge passing into the tap interface for the VM:

```bash
Chain neutron-openvswi-i67c49753-b (1 references)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            state INVALID
2     3586  280K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
3        2   168 RETURN     icmp --  *      *       0.0.0.0/0            0.0.0.0/0
4        0     0 RETURN     all  --  *      *       10.1.0.4             0.0.0.0/0
5        4   240 RETURN     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22
6        2   702 RETURN     udp  --  *      *       10.1.0.3             0.0.0.0/0            udp spt:67 dpt:68
7        4  1256 neutron-openvswi-sg-fallback  all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

This chain performs the checks for the security group rules. All packets in the
invalid state are dropped (rule 1). Packets in the related or established state,
packets related to an established flow are returned back to the previous chain
(rule 2). ICMP packets are returned (rule 3). Rule 3 was created by the addition
to the default security group to allow ICMP packets. All packets from VM2
(IP 10.1.0.4) are returned (rule4). This rule allows communication between the
other VM on this network and VM1. There is a corresponding rule in the chain for
VM2. Continuing with rule 5 which allows communication on port 22, which is here
because of the addition to the security group to allow port 22 (SSH) communication.
Rule 6 allows DHCP responses from the DHCP server. Lastly any packets not matching
the rules in this chain will be sent to the chain neutron-openvswi-sg-fallback.
In summary incoming packets to VM1 that are ICMP packets, packets from the other
VM on the network (IP – 10.1.0.4), port 22 (ssh) packets and packets in the
related or established state are allowed, everything else is sent to the chain
neutron-openvswi-sg-fallback.

The chain neutron-openvswi-sg-fallback has one rule that will drop any packets
entering this chain:

```bash
Chain neutron-openvswi-sg-fallback (6 references)
num   pkts bytes target                        prot opt in     out     source               destination
1     1227 70668 DROP
```

So for a packet to continue to this VM, it must have matched one of the rules
in the chain neutron-openvswi-i67c49753-b, or it is dropped.

Remember from the above that packets coming out of VM1 were directed to the chain
neutron-openvswi-o67c49753-b:

```bash
Chain neutron-openvswi-o67c49753-b (2 references)
num   pkts bytes target     prot opt in     out     source               destination
1        3   936 RETURN     udp  --  *      *       0.0.0.0/0            0.0.0.0/0            udp spt:68 dpt:67
2     3612  393K neutron-openvswi-s67c49753-b  all  --  *      *       0.0.0.0/0            0.0.0.0/0
3        0     0 DROP       udp  --  *      *       0.0.0.0/0            0.0.0.0/0            udp spt:67 dpt:68
4        0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            state INVALID
5     3536  388K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
6       76  4842 RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
7        0     0 neutron-openvswi-sg-fallback  all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Looking at this chain rule by rule, first rule 1 allows DHCP request packets
coming from the VM. Rule 2 sends all packets to the chain neutron-openvswi-s67c49753-b.
Rule 3 prevents a VM from acting as a DHCP server because it drops any packets
coming from UDP source port 67 and going to UDP port 68 (usually a response to
a DHCP request). Rule 4 drops packets coming from the VM in an invalid state.
Rule 5 returns packets that are in a related/established state to the calling
chain. Rule 6 returns any packets coming out of the VM to this point. Finally,
rule 7 sends any packets that might have escaped the other rules to the chain
neutron-openvswi-s67c49753-b which will drop those packets. In summary, packets
coming out of the VM that are responding to DHCP requests are dropped. All packets
are then sent to the chain neutron-openvswi-s67c49753-b, which is considered next.
Packets in the invalid state are dropped. Packets that are DHCP requests, packets
in the related or established state, and all other packets are returned to the
calling chain.

The chain neutron-openvswi-s67c49753-b:

```bash
Chain neutron-openvswi-s67c49753-b (1 references)
num   pkts bytes target     prot opt in     out     source               destination
1     3239  362K RETURN     all  --  *      *       10.1.0.2             0.0.0.0/0            MAC FA:16:3E:DC:BE:EB
2        0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0                         all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Rule one returns all packets coming out of the VM with IP, 10.1.0.2 (the IP
assigned to the VM) and with MAC address, FA:16:3E:DC:BE:EB, the MAC address
that OpenStack assigned to the VM are returned to the calling chain. Any packets
coming out of the VM that don't match the proper MAC and IP addresses are dropped.
It is this rule that prevents a VM from changing its IP or spoofing its MAC address.

The next article will carry through the remainder of the iptables rules on the
compute node and progress to the point of data exiting/entering the OVS process
on this node. The flow of two different types of packets through the iptables
chains will be reviewed. Subsequent articles continue through the rest of the
virtual/physical network structure.

