---
layout: post
title: Configuring Your Rackspace Private Cloud lab environment for Cinder testing
date: '2014-05-16 15:13'
comments: true
author: Jason Grimm
published: true
categories:
  - OpenStack
---

This post covers environment pre-configuration tasks for testing of the cinder
service and provides a few more informal tips and recommendations outside of
strictly the procedural steps.

This is specifically for sandbox and testing / development environments –
configurations described here, such as: compute and cinder running on the
controller, using a loopback device for cinder-volumes and so on are not
supported and should not be used in production.

<!-- more -->

If your cinder node deployment went according to plan you should be able to
login to your newly deployed node and check to make sure everything is running okay.

### Check Cinder services

1) SSH into the controller / compute node

2) Check the cinder services from the operating system

```
  root@controller-1:~# service cinder-volume status

  cinder-volume start/running, process 27061

  root@controller-1:~# service cinder-api status

  cinder-api start/running, process 26974

  root@controller-1:~# service cinder-scheduler status

  cinder-scheduler start/running, process 27019
```

3) Source the credentials file

```
  # cd /root

  # . openrc
```

4) Check the cinder services from the cinder CLI

```
  root@controller-1:~# cinder service-list


  +------------------+----------------------+------+---------+-------+----------------------------+

  |   Binary   |     Host     | Zone | Status | State |     Updated\_at     |

  +------------------+----------------------+------+---------+-------+----------------------------+

  | cinder-scheduler | controller-1.lab.net | nova | enabled |  up | 2014-02-17T13:29:48.000000 |

  | cinder-volume  | controller-1.lab.net | nova | enabled |  up | 2014-02-17T13:29:45.000000 |

  +------------------+----------------------+------+---------+-------+----------------------------+
```

### Post installation setup

Before we get to work on verifying cinder, let's setup a few other components for our instances.

1) Create a keypair.

```
  # If you haven't already created ssh keys on this controller node, do so now

  # cd /root

  # ssh-keygen

  # cd .ssh

  root@controller-1:~/.ssh# nova keypair-add --pub\_key id\_rsa.pub mykey

  root@controller-1:~/.ssh# nova keypair-list

  +-------+-------------------------------------------------+

  | Name | Fingerprint                   |

  +-------+-------------------------------------------------+

  | mykey | xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx |

  +-------+-------------------------------------------------+
```

2) Create a security group to allow ping and ssh , verify results.

```
root@controller-1:~/.ssh# nova secgroup-create mysecuritygroup "My Security Group"

+--------------------------------------+-----------------+-------------------+

| Id                  | Name      | Description    |

+--------------------------------------+-----------------+-------------------+

| e1ca5db8-b47b-4849-94ea-9bd0eadee3c9 | mysecuritygroup | My Security Group |

+--------------------------------------+-----------------+-------------------+

root@controller-1:~/.ssh# nova secgroup-add-rule mysecuritygroup tcp 22 22 0.0.0.0/0

+-------------+-----------+---------+-----------+--------------+

| IP Protocol | From Port | To Port | IP Range | Source Group |

+-------------+-----------+---------+-----------+--------------+

| tcp     | 22    | 22   | 0.0.0.0/0 |       |

+-------------+-----------+---------+-----------+--------------+

root@controller-1:~/.ssh# nova secgroup-add-rule mysecuritygroup icmp -1 -1 0.0.0.0/0

+-------------+-----------+---------+-----------+--------------+

| IP Protocol | From Port | To Port | IP Range | Source Group |

+-------------+-----------+---------+-----------+--------------+

| icmp    | -1    | -1   | 0.0.0.0/0 |       |

+-------------+-----------+---------+-----------+--------------+

root@controller-1:~/.ssh# nova secgroup-list

+--------------------------------------+-----------------+-------------------+

| Id                  | Name      | Description    |

+--------------------------------------+-----------------+-------------------+

| df4ebc27-5d40-4005-a57a-0d2aab642694 | default     | default      |

| e1ca5db8-b47b-4849-94ea-9bd0eadee3c9 | mysecuritygroup | My Security Group |

+--------------------------------------+-----------------+-------------------+

root@controller-1:~/.ssh# nova secgroup-list-rules mysecuritygroup

+-------------+-----------+---------+-----------+--------------+

| IP Protocol | From Port | To Port | IP Range | Source Group |

+-------------+-----------+---------+-----------+--------------+

| icmp    | -1    | -1   | 0.0.0.0/0 |       |

| tcp     | 22    | 22   | 0.0.0.0/0 |       |

+-------------+-----------+---------+-----------+--------------+
```

3) Create a new router and verify.

_TIP: Neutron uses net namespaces, if this is not preferred you can remove neutron and put in nova-network. Everything in this article works the same except for the sections on setting up networking and SSH'ing to your instances ._

```
root@controller-1:~/.ssh# neutron router-create router-1

Created a new router:

+-----------------------+--------------------------------------+

| Field         | Value                |

+-----------------------+--------------------------------------+

| admin\_state\_up    | True                 |

| external\_gateway\_info |                   |

| id          | 3488e9b9-d03f-4e07-85ee-268d688d6a92 |

| name         | router-1               |

| status        | ACTIVE                |

| tenant\_id       | fb89fe32204f4f438810d4d12b400a52   |

+-----------------------+--------------------------------------+

root@controller-1:~/.ssh# neutron router-list

+--------------------------------------+----------+-----------------------+

| id                  | name   | external\_gateway\_info |

+--------------------------------------+----------+-----------------------+

| 3488e9b9-d03f-4e07-85ee-268d688d6a92 | router-1 | null         |

+--------------------------------------+----------+-----------------------+
```

4) Create the public network and verify.

```
root@controller-1:~/.ssh# neutron net-create publicnet-1 --provider:network\_type flat --provider:physical\_network ph-eth0 --router:external=True

Created a new network:

+---------------------------+--------------------------------------+

| Field           | Value                |

+---------------------------+--------------------------------------+

| admin\_state\_up      | True                 |

| id            | 82a7ac1e-ac91-4b70-9d74-3c1e2a71a5f8 |

| name           | publicnet-1             |

| provider:network\_type   | flat                 |

| provider:physical\_network | ph-eth0               |

| provider:segmentation\_id |                   |

| router:external      | True                 |

| shared          | False                |

| status          | ACTIVE                |

| subnets          |                   |

| tenant\_id         | fb89fe32204f4f438810d4d12b400a52   |

+---------------------------+--------------------------------------+

root@controller-1:~/.ssh# neutron net-list

+--------------------------------------+-------------+---------+

| id                  | name    | subnets |

+--------------------------------------+-------------+---------+

| 82a7ac1e-ac91-4b70-9d74-3c1e2a71a5f8 | publicnet-1 |     |

+--------------------------------------+-------------+---------+
```

5) Create a subnet and verify.

```
root@controller-1:~/.ssh# neutron subnet-create --name publicnet-1\_subnet-1 --gateway 10.0.20.1 publicnet-1 10.0.20.0/24 --disable-dhcp

Created a new subnet:

+------------------+----------------------------------------------+

| Field      | Value                    |

+------------------+----------------------------------------------+

| allocation\_pools | {"start": "10.0.20.2", "end": "10.0.20.254"} |

| cidr       | 10.0.20.0/24                 |

| dns\_nameservers |                       |

| enable\_dhcp   | False                    |

| gateway\_ip    | 10.0.20.1                  |

| host\_routes   |                       |

| id        | bc172bcf-5b53-4b54-963c-4e36695e6aa1     |

| ip\_version    | 4                      |

| name       | publicnet-1\_subnet-1             |

| network\_id    | 82a7ac1e-ac91-4b70-9d74-3c1e2a71a5f8     |

| tenant\_id    | fb89fe32204f4f438810d4d12b400a52       |

+------------------+----------------------------------------------+

root@controller-1:~/.ssh# neutron subnet-list

+--------------------------------------+----------------------+--------------+-------------------+

| id                  | name         | cidr     | allocation\_pools |

+--------------------------------------+----------------------+--------------+-------------------+

| bc172bcf-5b53-4b54-963c-4e36695e6aa1 | publicnet-1\_subnet-1 | 10.0.20.0/24 | {"start": "10.... |

+--------------------------------------+----------------------+--------------+-------------------+
```

6) Set the router gateway.

```
root@controller-1:~/.ssh# neutron router-gateway-set router-1 publicnet-1

Set gateway for router router-1

root@controller-1:~/.ssh# neutron router-port-list router-1

+--------------------------------------+------+-------------------+--------------------+

| id                  | name | mac\_address    | fixed\_ips     |

+--------------------------------------+------+-------------------+--------------------+

| 17d817db-cd56-4e9f-9b39-7a83f72e950e |   | fa:16:3e:00:23:d0 | {"subnet\_id":.... |

+--------------------------------------+------+-------------------+--------------------+
```

7) Create a private VM network, subnet and router interface.

```
root@controller-1:~/.ssh# neutron net-create privatenet-1

Created a new network:

+---------------------------+--------------------------------------+

| Field           | Value                |

+---------------------------+--------------------------------------+

| admin\_state\_up      | True                 |

| id            | 4ed006c3-fade-429b-ab3f-f156f17c2a9c |

| name           | privatenet-1             |

| provider:network\_type   | gre                 |

| provider:physical\_network |                   |

| provider:segmentation\_id | 1                  |

| shared          | False                |

| status          | ACTIVE                |

| subnets          |                   |

| tenant\_id         | fb89fe32204f4f438810d4d12b400a52   |

+---------------------------+--------------------------------------+

root@controller-1:~/.ssh# neutron subnet-create --name privatenet-1\_subnet-1 privatenet-1 192.168.20.0/24

Created a new subnet:

+------------------+----------------------------------------------------+

| Field      | Value                       |

+------------------+----------------------------------------------------+

| allocation\_pools | {"start": "192.168.20.2", "end": "192.168.20.254"} |

| cidr       | 192.168.20.0/24                  |

| dns\_nameservers |                          |

| enable\_dhcp   | True                        |

| gateway\_ip    | 192.168.20.1                    |

| host\_routes   |                          |

| id        | 9c21571e-43c7-4ffa-8e67-4135be702ce7        |

| ip\_version    | 4                         |

| name       | privatenet-1\_subnet-1               |

| network\_id    | 4ed006c3-fade-429b-ab3f-f156f17c2a9c        |

| tenant\_id    | fb89fe32204f4f438810d4d12b400a52          |

+------------------+----------------------------------------------------+

root@controller-1:~/.ssh# neutron router-interface-add router-1 privatenet-1\_subnet-1

Added interface 63391343-81f0-4338-8466-e178f837c1bb to router router-1.
```

Assuming all of this looks good we can move on to testing cinder.

### Conclusion

In this article we covered the basics of the pre-configuration tasks required to test cinder in your environment.

Please refer back to the full instructions in the knowledge center article – "KNOWLEDGE CENTER ARTICLE: INSTALLING AND TESTING CINDER IN YOUR RACKSPACE PRIVATE CLOUD LAB ENVIRONMENT" or at my other cinder related posts for additional help.

Look for future cinder related posts with more advanced topics such as using NetApp, EMC or SolidFire cinder drivers, providing Cinder HA to your instances and using multiple cinder devices to provide workload separation and performance tiering for your instances.

### Reference material

You may also find the following references helpful as you explore cinder functionality further.

- [RPC How-to documentation](https://support.rackspace.com/how-to/rpc-openstack/)
- [How-to Block Storage documentation](https://support.rackspace.com/how-to/cloud-block-storage-all-articles/)
