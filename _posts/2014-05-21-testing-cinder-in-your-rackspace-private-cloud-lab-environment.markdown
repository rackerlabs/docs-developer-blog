---
layout: post
title: Testing Cinder in your Rackspace Private Cloud lab environment
date: '2014-05-21 10:22'
comments: true
author: Jason Grimm
published: true
categories:
  - OpenStack
  - Private Cloud
---

This post covers testing the cinder service and provides a few
informal tips and recommendations outside of strictly procedural steps.

<!-- more -->

This is specifically for sandbox and testing / development environments –
configurations described here, such as: compute and cinder running on the
controller, using a loopback device for cinder-volumes and so on are not
supported and should not be used in production.

### Testing cinder

Finally we're ready to test our cinder service and configuration.

#### Basic volume creation

1) First let's test the creation of a basic volume and verify.

```
root@controller-1:~# cinder create --display-name 1gb-basicvol-1 1

+---------------------+--------------------------------------+

|    Property   |        Value         |

+---------------------+--------------------------------------+

|   attachments   |         []         |

| availability\_zone |         nova         |

|    bootable   |        false         |

|   created\_at   |   2014-02-17T13:32:50.524045   |

| display\_description |         None         |

|   display\_name  |      1gb-basicvol-1      |

|     id     | c164f8ea-e228-4c2b-9f71-d8c0832d38e2 |

|    metadata   |         {}         |

|     size    |         1          |

|   snapshot\_id   |         None         |

|   source\_volid  |         None         |

|    status    |        creating        |

|   volume\_type   |         None         |

+---------------------+--------------------------------------+

root@controller-1:~# cinder list

+--------------------------------------+-----------+----------------+------+-------------+--------+

|         ID         |  Status | Display Name | Size | Volume Type | Boot.. |

+--------------------------------------+-----------+----------------+------+-------------+--------+

| c164f8ea-e228-4c2b-9f71-d8c0832d38e2 | available | 1gb-basicvol-1 | 1  |   None  | false |

+--------------------------------------+-----------+----------------+------+-------------+--------+

1. Optionally you can view the volume from the operating systems as well.

root@controller-1:~# lvs

 LV                     VG       Attr  LSize Origin Snap% Move Log Copy% Convert

 volume-c164f8ea-e228-4c2b-9f71-d8c0832d38e2 cinder-volumes -wi-ao 1.00g

 root                    rackspace1   -wi-ao 15.74g

 swap\_1                   rackspace1   -wi-ao 4.00g

root@controller-1:~# lvdisplay

 --- Logical volume ---

 LV Name        /dev/cinder-volumes/volume-c164f8ea-e228-4c2b-9f71-d8c0832d38e2

 VG Name        cinder-volumes

 LV UUID        S19Jzu-HruZ-TOK8-OCqf-TJuz-Gpqc-IewVM3

 LV Write Access    read/write

 LV Status       available

 # open         1

 LV Size        1.00 GiB

 Current LE       256

 Segments        1

 Allocation       inherit

 Read ahead sectors   auto

 - currently set to   256

 Block device      252:2
```
#### Creating bootable volumes

2) Next let's test creating a volume from a bootable image.
  a) First, let's make sure we have an image present

```
root@controller-1:~# glance image-list

+--------------------------------------+------------------------------------+-------------+

| ID                  | Name                | Disk Format |

| 9f8aa2db-6984-4dec-8a36-95a7188a5308 | cirros-0.3.1-x86\_64-image     | qcow2    |

| 9cfdd395-b18d-4de0-b87d-b268a545d209 | ubuntu-server-12.04.3-x86\_64-image | qcow2    |

+--------------------------------------+------------------------------------+-------------+

root@controller-1:~# glance image-show cirros-0.3.1-x86\_64-image

+------------------+--------------------------------------+

| Property     | Value                |

+------------------+--------------------------------------+

| container\_format | bare                 |

| created\_at    | 2014-02-16T05:12:45         |

| deleted     | False                |

| disk\_format   | qcow2                |

| id        | 9f8aa2db-6984-4dec-8a36-95a7188a5308 |

| is\_public    | True                 |

| min\_disk     | 0                  |

| min\_ram     | 0                  |

| name       | cirros-0.3.1-x86\_64-image      |

| owner      | fb89fe32204f4f438810d4d12b400a52   |

| protected    | False                |

| size       | 13147648               |

| status      | active                |

| updated\_at    | 2014-02-16T05:12:45         |

+------------------+--------------------------------------+
```

  b) Now let's create a bootable volume using this image and verify that it is set to bootable.

_TIP: It will show bootable "false" at first, but after creation it will show as "true"._

```
root@controller-1:~# cinder create --image-id 9f8aa2db-6984-4dec-8a36-95a7188a5308 --display-name 1gb-bootvol-1 1

+---------------------+--------------------------------------+

|    Property   |        Value         |

+---------------------+--------------------------------------+

|   attachments   |         []         |

| availability\_zone |         nova         |

|    bootable   |        false         |

|   created\_at   |   2014-02-17T18:25:36.882570   |

| display\_description |         None         |

|   display\_name  |      1gb-bootvol-1       |

|     id     | 59ccacc7-c195-44a1-9354-5e48c8406683 |

|    image\_id   | 9f8aa2db-6984-4dec-8a36-95a7188a5308 |

|    metadata   |         {}         |

|     size    |         1          |

|   snapshot\_id   |         None         |

|   source\_volid  |         None         |

|    status    |        creating        |

|   volume\_type   |         None         |

+---------------------+--------------------------------------+

root@controller-1:~# cinder list

+--------------------------------------+-----------+----------------+------+-------------+--------+

|         ID         |  Status | Display Name | Size | Volume Type | Boot.. |

+--------------------------------------+-----------+----------------+------+-------------+--------+

| 59ccacc7-c195-44a1-9354-5e48c8406683 | available | 1gb-bootvol-1 | 1  |   None  |  true |

| c164f8ea-e228-4c2b-9f71-d8c0832d38e2 | available | 1gb-basicvol-1 | 1  |   None  | false |

+--------------------------------------+-----------+----------------+------+-------------+--------+
```

#### Boot an instance

3) Once created let's boot an instance using this newly created bootable volume.

```
# List flavors

root@controller-1:~# nova flavor-list

+----+-----------+-----------+------+-----------+------+-------+-------------+----------+

| ID | Name   | Memory\_MB | Disk | Ephemeral | Swap | VCPUs | RXTX\_Factor | Is\_Public|

+----+-----------+-----------+------+-----------+------+-------+-------------+----------+

| 1 | m1.tiny  | 512    | 1  | 0     |   | 1   | 1.0     | True   |

| 2 | m1.small | 2048   | 20  | 0     |   | 1   | 1.0     | True   |

| 3 | m1.medium | 4096   | 40  | 0     |   | 2   | 1.0     | True   |

| 4 | m1.large | 8192   | 80  | 0     |   | 4   | 1.0     | True   |

| 5 | m1.xlarge | 16384   | 160 | 0     |   | 8   | 1.0     | True   |

+----+-----------+-----------+------+-----------+------+-------+-------------+----------+

# Boot from volume

root@controller-1:~/.ssh# nova boot --flavor m1.tiny --boot-volume 59ccacc7-c195-44a1-9354-5e48c8406683 --key-name mykey --security-groups mysecuritygroup --nic net-id=4ed006c3-fade-429b-ab3f-f156f17c2a9c vm-1

+--------------------------------------+----------------------------------------------------+

| Property               | Value                       |

+--------------------------------------+----------------------------------------------------+

| OS-EXT-STS:task\_state        | scheduling                     |

| image                | Attempt to boot from volume - no image supplied  |

| OS-EXT-STS:vm\_state         | building                      |

| OS-EXT-SRV-ATTR:instance\_name    | instance-00000003                 |

| OS-SRV-USG:launched\_at        | None                        |

| flavor                | m1.tiny                      |

| id                  | 6d96a99f-dd44-41f5-96d7-35a7e830c174        |

| security\_groups           | [{u'name': u'mysecuritygroup'}]          |

| user\_id               | bb2948138ae04677927933a9ae352ecc          |

| OS-DCF:diskConfig          | MANUAL                       |

| accessIPv4              |                          |

| accessIPv6              |                          |

| progress               | 0                         |

| OS-EXT-STS:power\_state        | 0                         |

| OS-EXT-AZ:availability\_zone     | nova                        |

| config\_drive             |                          |

| status                | BUILD                       |

| updated               | 2014-02-17T23:19:52Z                |

| hostId                |                          |

| OS-EXT-SRV-ATTR:host         | None                        |

| OS-SRV-USG:terminated\_at       | None                        |

| key\_name               | mykey                       |

| OS-EXT-SRV-ATTR:hypervisor\_hostname | None                        |

| name                 | vm-1                        |

| adminPass              | 3wjBvH3npKpj                    |

| tenant\_id              | fb89fe32204f4f438810d4d12b400a52          |

| created               | 2014-02-17T23:19:51Z                |

| os-extended-volumes:volumes\_attached | [{u'id': u'59ccacc7-c195-44a1-9354-5e48c8406683'}] |

| metadata               | {}                         |

+--------------------------------------+----------------------------------------------------+

root@controller-1:~/.ssh# nova list

+--------------------------------------+------+--------+------------+-------------+---------------------------+

| ID                  | Name | Status | Task State | Power State | Networks         |

+--------------------------------------+------+--------+------------+-------------+---------------------------+

| 6d96a99f-dd44-41f5-96d7-35a7e830c174 | vm-1 | ACTIVE | None    | Running   | privatenet-1=192.168.20.2 |

+--------------------------------------+------+--------+------------+-------------+---------------------------+

1. Check again to verify that the build is complete

root@controller-1:~/.ssh# nova show 6d96a99f-dd44-41f5-96d7-35a7e830c174

+--------------------------------------+----------------------------------------------------------+

| Property               | Value                          |

+--------------------------------------+----------------------------------------------------------+

| status                | ACTIVE                          |

| updated               | 2014-02-17T23:20:01Z                   |

| OS-EXT-STS:task\_state        | None                           |

| OS-EXT-SRV-ATTR:host         | controller-1.lab.net                   |

| key\_name               | mykey                          |

| image                | Attempt to boot from volume - no image supplied     |

| hostId                | 8f19bbc5e451b2a9ab8483d2f751b24366621f5ed8f7b6a95486e5a6 |

| OS-EXT-STS:vm\_state         | active                          |

| OS-EXT-SRV-ATTR:instance\_name    | instance-00000003                    |

| OS-SRV-USG:launched\_at        | 2014-02-17T23:20:01.000000                |

| OS-EXT-SRV-ATTR:hypervisor\_hostname | controller-1.lab.net                   |

| flavor                | m1.tiny (1)                       |

| id                  | 6d96a99f-dd44-41f5-96d7-35a7e830c174           |

| security\_groups           | [{u'name': u'mysecuritygroup'}]             |

| OS-SRV-USG:terminated\_at       | None                           |

| user\_id               | bb2948138ae04677927933a9ae352ecc             |

| name                 | vm-1                           |

| created               | 2014-02-17T23:19:51Z                   |

| tenant\_id              | fb89fe32204f4f438810d4d12b400a52             |

| OS-DCF:diskConfig          | MANUAL                          |

| metadata               | {}                            |

| os-extended-volumes:volumes\_attached | [{u'id': u'59ccacc7-c195-44a1-9354-5e48c8406683'}]    |

| accessIPv4              |                             |

| accessIPv6              |                             |

| progress               | 0                            |

| OS-EXT-STS:power\_state        | 1                            |

| OS-EXT-AZ:availability\_zone     | nova                           |

| privatenet-1 network         | 192.168.20.2                       |

| config\_drive             |                             |

+--------------------------------------+----------------------------------------------------------+
```

#### Verify instance

4) SSH to the instance to verify that it is up and running.

```
root@controller-1:~/.ssh# ip netns list

qdhcp-4ed006c3-fade-429b-ab3f-f156f17c2a9c

qrouter-3488e9b9-d03f-4e07-85ee-268d688d6a92

root@controller-1:~/.ssh# ip netns exec qrouter-3488e9b9-d03f-4e07-85ee-268d688d6a92 ssh cirros@192.168.20.2

The authenticity of host '192.168.20.2 (192.168.20.2)' can't be established.

RSA key fingerprint is 1a:5b:23:f3:43:44:bd:e0:1d:fa:93:b8:36:18:71:fe.

Are you sure you want to continue connecting (yes/no)? yes

Warning: Permanently added '192.168.20.2' (RSA) to the list of known hosts.

cirros@192.168.20.2's password:

$ ifconfig eth0

eth0   Link encap:Ethernet HWaddr FA:16:3E:85:16:59

     inet addr:192.168.20.2 Bcast:192.168.20.255 Mask:255.255.255.0

     inet6 addr: fe80::f816:3eff:fe85:1659/64 Scope:Link

     UP BROADCAST RUNNING MULTICAST MTU:1500 Metric:1

     RX packets:293 errors:0 dropped:0 overruns:0 frame:0

     TX packets:403 errors:0 dropped:0 overruns:0 carrier:0

     collisions:0 txqueuelen:1000

     RX bytes:40193 (39.2 KiB) TX bytes:40421 (39.4 KiB)

     Interrupt:11 Base address:0xc000
```

#### Create an image-based volume at boot time

```

You can reduce this process to a single command by combining volume creation with the instance boot as follows.

1) Boot instance with volume and image paramaters.

```
# Nova boot from volume without pre-creation of volume

root@controller-1:~/.ssh# nova boot --flavor m1.tiny --key-name mykey --security-groups mysecuritygroup --nic net-id=4ed006c3-fade-429b-ab3f-f156f17c2a9c --block-device source=image,id=9f8aa2db-6984-4dec-8a36-95a7188a5308,dest=volume,device=vda,size=1,shutdown=preserve,bootindex=0 vm-2

+--------------------------------------+-------------------------------------------------+

| Property               | Value                      |

+--------------------------------------+-------------------------------------------------+

| OS-EXT-STS:task\_state        | scheduling                   |

| image                | Attempt to boot from volume - no image supplied |

| OS-EXT-STS:vm\_state         | building                    |

| OS-EXT-SRV-ATTR:instance\_name    | instance-00000005                |

| OS-SRV-USG:launched\_at        | None                      |

| flavor                | m1.tiny                     |

| id                  | 7d10a2db-9a9b-426e-a54a-9fc0224cdf14      |

| security\_groups           | [{u'name': u'mysecuritygroup'}]         |

| user\_id               | bb2948138ae04677927933a9ae352ecc        |

| OS-DCF:diskConfig          | MANUAL                     |

| accessIPv4              |                         |

| accessIPv6              |                         |

| progress               | 0                        |

| OS-EXT-STS:power\_state        | 0                        |

| OS-EXT-AZ:availability\_zone     | nova                      |

| config\_drive             |                         |

| status                | BUILD                      |

| updated               | 2014-02-17T23:40:19Z              |

| hostId                |                         |

| OS-EXT-SRV-ATTR:host         | None                      |

| OS-SRV-USG:terminated\_at       | None                      |

| key\_name               | mykey                      |

| OS-EXT-SRV-ATTR:hypervisor\_hostname | None                      |

| name                 | vm-2                      |

| adminPass              | MhRoHYQ88R8L                  |

| tenant\_id              | fb89fe32204f4f438810d4d12b400a52        |

| created               | 2014-02-17T23:40:19Z              |

| os-extended-volumes:volumes\_attached | []                       |

| metadata               | {}                       |

+--------------------------------------+-------------------------------------------------+
```

2) Check again to verify that the build is complete

```
root@controller-1:~/.ssh# nova list

+--------------------------------------+------+---------+------------+-------------+---------------------------+

| ID                  | Name | Status | Task State | Power State | Networks         |

+--------------------------------------+------+---------+------------+-------------+---------------------------+

| 6d96a99f-dd44-41f5-96d7-35a7e830c174 | vm-1 | SHUTOFF | None    | Shutdown  | privatenet-1=192.168.20.2 |

| 7d10a2db-9a9b-426e-a54a-9fc0224cdf14 | vm-2 | ACTIVE | None    | Running   | privatenet-1=192.168.20.4 |

+--------------------------------------+------+---------+------------+-------------+---------------------------+

root@controller-1:~/.ssh# nova show 7d10a2db-9a9b-426e-a54a-9fc0224cdf14

+--------------------------------------+----------------------------------------------------------+

| Property               | Value                          |

+--------------------------------------+----------------------------------------------------------+

| status                | ACTIVE                          |

| updated               | 2014-02-17T23:40:37Z                   |

| OS-EXT-STS:task\_state        | None                           |

| OS-EXT-SRV-ATTR:host         | controller-1.lab.net                   |

| key\_name               | mykey                          |

| image                | Attempt to boot from volume - no image supplied     |

| hostId                | 8f19bbc5e451b2a9ab8483d2f751b24366621f5ed8f7b6a95486e5a6 |

| OS-EXT-STS:vm\_state         | active                          |

| OS-EXT-SRV-ATTR:instance\_name    | instance-00000005                    |

| OS-SRV-USG:launched\_at        | 2014-02-17T23:40:36.000000                |

| OS-EXT-SRV-ATTR:hypervisor\_hostname | controller-1.lab.net                   |

| flavor                | m1.tiny (1)                       |

| id                  | 7d10a2db-9a9b-426e-a54a-9fc0224cdf14           |

| security\_groups           | [{u'name': u'mysecuritygroup'}]             |

| OS-SRV-USG:terminated\_at       | None                           |

| user\_id               | bb2948138ae04677927933a9ae352ecc             |

| name                 | vm-2                           |

| created               | 2014-02-17T23:40:19Z                   |

| tenant\_id              | fb89fe32204f4f438810d4d12b400a52             |

| OS-DCF:diskConfig          | MANUAL                          |

| metadata               | {}                            |

| os-extended-volumes:volumes\_attached | [{u'id': u'8dd33269-1ef4-4cd0-8c75-1f0749219981'}]    |

| accessIPv4              |                             |

| accessIPv6              |                             |

| progress               | 0                            |

| OS-EXT-STS:power\_state        | 1                            |

| OS-EXT-AZ:availability\_zone     | nova                           |

| privatenet-1 network         | 192.168.20.4                       |

| config\_drive             |                             |

+--------------------------------------+----------------------------------------------------------+

# Rename the newly created volume (not able to be set from boot command)

# cinder rename 8dd33269-1ef4-4cd0-8c75-1f0749219981 1gb-bootvol-2
```

2) SSH to the instance to verify that it is up and running

```
root@controller-1:~/.ssh# ip netns exec qrouter-3488e9b9-d03f-4e07-85ee-268d688d6a92 ssh cirros@192.168.20.4

The authenticity of host '192.168.20.4 (192.168.20.4)' can't be established.

RSA key fingerprint is 52:15:84:66:39:d3:5e:71:b2:08:d6:c9:7a:8c:81:95.

Are you sure you want to continue connecting (yes/no)? yes

Warning: Permanently added '192.168.20.4' (RSA) to the list of known hosts.

cirros@192.168.20.4's password:

$ ifconfig

eth0   Link encap:Ethernet HWaddr FA:16:3E:94:A0:CF

     inet addr:192.168.20.4 Bcast:192.168.20.255 Mask:255.255.255.0

     inet6 addr: fe80::f816:3eff:fe94:a0cf/64 Scope:Link

     UP BROADCAST RUNNING MULTICAST MTU:1500 Metric:1

     RX packets:302 errors:0 dropped:0 overruns:0 frame:0

     TX packets:411 errors:0 dropped:0 overruns:0 carrier:0

     collisions:0 txqueuelen:1000

     RX bytes:40757 (39.8 KiB) TX bytes:41015 (40.0 KiB)

     Interrupt:11 Base address:0xc000
```

3) Lastly check cinder and nova list to make sure both volumes are created and match the attachment shown in nova list for your new instances.

```
root@controller-1:~# cinder list

+--------------------------------------+-----------+----------------+------+-------------+----------+----------+

|         ID         |  Status | Display Name | Size | Volume Type | Bootable | Attach...|

+--------------------------------------+-----------+----------------+------+-------------+----------+----------+

| 59ccacc7-c195-44a1-9354-5e48c8406683 |  in-use | 1gb-bootvol-1 | 1  |   None  |  true  | 6d9...174|

| 8dd33269-1ef4-4cd0-8c75-1f0749219981 |  in-use | 1gb-bootvol-2 | 1  |   None  |  true  | 7d1...f14|

| c164f8ea-e228-4c2b-9f71-d8c0832d38e2 | available | 1gb-basicvol-1 | 1  |   None  | false  |     |

+--------------------------------------+-----------+----------------+------+-------------+----------+----------+

root@controller-1:~# nova list

+--------------------------------------+------+---------+------------+-------------+---------------------------+

| ID                  | Name | Status | Task State | Power State | Networks         |

+--------------------------------------+------+---------+------------+-------------+---------------------------+

| 6d96a99f-dd44-41f5-96d7-35a7e830c174 | vm-1 | SHUTOFF | None    | Shutdown  | privatenet-1=192.168.20.2 |

| 7d10a2db-9a9b-426e-a54a-9fc0224cdf14 | vm-2 | SHUTOFF | None    | Shutdown  | privatenet-1=192.168.20.4 |

+--------------------------------------+------+---------+------------+-------------+---------------------------+
```

### Conclusion

In this article we covered the basics of testing cinder in your RPC lab environment.

Look for future cinder related posts with more advanced topics such as using NetApp,
EMC or SolidFire cinder drivers, providing Cinder HA to your instances and using
multiple cinder devices to provide workload separation and performance tiering
for your instances.

### Reference Material

You may also find the following references helpful as you explore cinder functionality further.

- [RPC How-to documentation](https://support.rackspace.com/how-to/rpc-openstack/)
- [How-to Block Storage documentation](https://support.rackspace.com/how-to/cloud-block-storage-all-articles/)
