---
layout: post
title: Clustered storage on Rackspace open cloud using Cloud Networks and Cloud Block Storage
date: '2013-03-06 12:00'
comments: true
author: Niko Gonzales
categories:
  - OpenStack
  - Cloud Networks
---
Rackspace has rolled out quite a few new products in the past 6 months - most notable among them are Cloud Block Storage and Cloud Networks. These technologies provide the power and flexibility that was previously non-existent in Rackspace Cloud. Administrators are now able to have private networks, attach and detach custom-sized storage volumes to their servers, and much more. In this post we'll talk about using Cloud Networks and Cloud Block Storage to build scalable, resilient application environments.

<!-- more -->

### DRBD and GFS2 or GlusterFS on Rackspace Public Cloud using Cloud Block Storage and Cloud Networks

If you are unfamiliar with Cloud Servers, Cloud Block Storage, or Cloud Networks, see the documentation provided below to become acquainted.

  - [Cloud Servers](http://www.rackspace.com/cloud/servers/)
  - [Cloud Block Storage(CBS)](http://www.rackspace.com/cloud/block-storage/)
  - [Cloud Networks](https://support.rackspace.com/how-to/cloud-networks/)

If you aren't familiar with the API or `python-novaclient`, see [Getting started on NextGen Cloud Servers](http://docs.rackspace.com/servers/api/v2/cs-gettingstarted/content/ch_gs_getting_started_with_nova.html). You can also do this tutorial from the web interface, but it will likely take three times as long.

In this tutorial, we're going to start off by building two servers with an interface on each of them being connected to a "Cloud Network". This network is essentially a layer 2 domain created by using a protocol called Stateles Transport Tunneling [(STT)](http://tools.ietf.org/html/draft-davie-stt-01) between hypervisors. If you have ever heard of "software defined networking", this is it as real at it gets. As a customer, you get an interface on your instance that, for all you know, is connected to its own switch fabric with your own private VLAN.

After creating the cloud network and putting two instances on it, we'll create and attach two Cloud Block Storage volumes - one to each server. These are Luns exported directly to hypervisors and attached to instances as block devices. The highlights of CBS are that they're mobile (you can attach/detach these volumes to various servers), customizable (it's now possible to have 100GB of storage on an instance with 512MB of RAM), and relatively inexpensive.

After attaching these CBS volumes to their servers, we'll use DRBD to create a replicated storage volume. If you haven't used DRBD yet, you probably have a use-case so check out their project at [drbd.org](http://www.drbd.org/). Basically it is block-level replication between servers. This technology is useful for making nearly any technology redundant. Traditionally we only see DRBD over a dedicated physical ethernet interface or bond on physical servers, but this is the cloud and we have a different model.

We initially create a DRBD volume in a Primary/Secondary configuration, then move on to a dual-primary setup and use a distributed filesystem technology called [GFS2](http://en.wikipedia.org/wiki/GFS2). Through clever locking this will allow us to have both of our servers mount the DRBD volume at the same time with read/write access.

After GFS2 we will look at building a highly scalable GlusterFS environment on CentOS, with 4 Gluster servers in distributed replica-2 configuration, and 2 web servers accessing a Gluster volume hosted on the 4-node cluster.

#### A quick overview of the steps

  * Creating a Cloud Network
  * Creating two Cloud Block Storage volumes
  * Creating two Ubuntu 12.04 instances with an interface on the private cloud networks.
  * Attaching Cloud Block Storage volumes - one to each of the servers
  * Formatting the volumes
  * Installing DRBD and other necessary packages
  * Configuring DRBD for Primary/Secondary
  * Testing Primary/Secondary
  * Configuring DRBD for dual-primary
  * Installing gfs2 and cluster packages
  * Formatting the DRBD volume as a GFS2 volume
  * Mounting the volume on both servers

The following steps you'll complete on your local machine. (or wherever you have `python-novaclient` installed)

#### Build your networks

To create a network, use the `nova network-create` command - for example:

    > nova network-create drbd0 172.16.16.0/24

#### Build your CBS Volumes

To create CBS volumes, run the `nova volume-create` command in a for-loop. For example:

    > for i in 0 1; do nova volume-create --display-name drbd${i} 100; done

#### Build your servers

After building the volumes, create two servers using the `nova boot` command in a for-loop:

    > for i in 0 1; do nova boot --image 5cebb13a-f783-4f8c-8058-c4182c724ccd \
    --nic net-id=35bf07d5-f4df-4d68-9082-83f9802648b8 \
    --flavor 2 \
    --file /root/.ssh/authorized_keys=/home/niko5420/.ssh/id_rsa.pub \
    drbd${i}; sleep 30; done

A simple breakdown (in case you're confused by this command) would look like the following:

  * `--image <uuid>` - this is the official Rackspace Ubuntu 12.04 image returned by the `nova image-list` command
  * `--nic net-id=<uuid>` - this is the uuid returned from the private network I created above. If you don't have it in your terminal buffer, you can find it with `nova network-list`
  * `--flavor 2` - this is the flavor for the 512MB instance, while I don't recommend running DRBD on this flavor, it's possible. You can learn more about the flavors with `nova flavor-list`
  * `--file /root/.ssh/authorized_keys=/home/niko5420/.ssh/id_rsa.pub` - this is the flag I use to inject my `id_rsa.pub` into the server's `/root/.ssh/authorized_keys` - allowing me public key authentication as soon as the server is built
  * `drbd${i}` - this is the display-name of my server. When I run a `nova list`, this name will show up there
  * `sleep 30` - this is to completely avoid the unlikely scenario that the scheduler sticks both of my instances on the same hypervisor.

### Attach the block devices to your servers

After the servers are created, find the UUID of the servers and volumes (first column seen below) and attach the volumes using the `nova volume-attach <server> <volume> /dev/devicename` command

     > nova list | egrep "drbd|^\+"
    +--------------------------------------+----------------+--------+-----------------------------------------------------------------------------------------------------------+
    | f91ffd0e-5894-4ab6-a8e7-17c50c45ef54 | drbd0          | ACTIVE | drbd0=172.16.16.4; public=166.78.129.153, 2001:4800:7811:0513:bd86:1d06:ff04:ca0f; private=10.181.144.112 |
    | 391b340d-da5c-4c5c-9708-72e0e2d72c3c | drbd1          | ACTIVE | drbd0=172.16.16.3; public=2001:4800:7811:0513:bd86:1d06:ff04:3cbf, 166.78.129.254; private=10.181.145.199 |
    +--------------------------------------+----------------+--------+-----------------------------------------------------------------------------------------------------------+
     > nova volume-list | egrep "drbd|^\+"
    +--------------------------------------+-----------+--------------+------+-------------+--------------------------------------+
    | 00e03044-9a3b-4c53-a558-bf8f0cd560f4 | available | drbd1        | 100  | SATA        |                                      |
    | cf5e1aae-3e96-4aa1-a69b-412c9339fac8 | available | drbd0        | 100  | SATA        |                                      |
    +--------------------------------------+-----------+--------------+------+-------------+--------------------------------------+
     > nova volume-attach f91ffd0e-5894-4ab6-a8e7-17c50c45ef54 f91ffd0e-5894-4ab6-a8e7-17c50c45ef54 /dev/xvdb
     > nova volume-attach 391b340d-da5c-4c5c-9708-72e0e2d72c3c 00e03044-9a3b-4c53-a558-bf8f0cd560f4 /dev/xvdf

#### Update and upgrade your server first

Now that your servers are created - make sure they're fully patched. `update` , `upgrade` and `reboot` on both servers

    # apt-get update && apt-get upgrade -y && reboot

#### Verify connectivity on the private network

Make sure you can communicate with the other instance on the "cloud network" - if you need to know its address, see the `nova list` command

    # ping 172.16.16.4
    PING 172.16.16.4 (172.16.16.4) 56(84) bytes of data.
    64 bytes from 172.16.16.4: icmp_req=1 ttl=64 time=413 ms
    64 bytes from 172.16.16.4: icmp_req=2 ttl=64 time=1.77 ms
    64 bytes from 172.16.16.4: icmp_req=3 ttl=64 time=3.86 ms
    ^C
    --- 172.16.16.4 ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2003ms
    rtt min/avg/max/mdev = 1.774/139.643/413.297/193.504 ms

#### Install the drbd8-utils and linux-image-extra-virtual packages

Install the following packages on both servers:

    # apt-get install drbd8-utils linux-image-extra-virtual -y && reboot

We reboot again because `-extra-virtual` gives us a new kernel - it's required to have drbd.ko unless you want to build from source

#### Make a single 1GB partition on the CBS device (XVDB for server drbd0, XVDF for server drbd1)

On both servers, make a single 1GB partition on the CBS device - we do this because we're impatient and don't want to wait too long for the initial sync - you'll probably want a bigger replicated disk than 1GB, but for testing, this will do

    # fdisk /dev/xvdb

    Command (m for help): p

    Disk /dev/xvdb: 107.4 GB, 107374182400 bytes
    255 heads, 63 sectors/track, 13054 cylinders, total 209715200 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x000deb40

        Device Boot      Start         End      Blocks   Id  System

    Make a new partition: `Command (m for help): n`

    Partition type:
       p   primary (0 primary, 0 extended, 4 free)
       e   extended

It is a primary partition: `Select (default p): p`

Select the defaults:

    Partition number (1-4, default 1):
    Using default value 1
    First sector (2048-209715199, default 2048):
    Using default value 2048

Make it 1GB: `Last sector, +sectors or +size{K,M,G} (2048-209715199, default 209715199): +1GB`

You should have the following partition set up now:

    Command (m for help): p

    Disk /dev/xvdb: 107.4 GB, 107374182400 bytes
    255 heads, 63 sectors/track, 13054 cylinders, total 209715200 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x000deb40

        Device Boot      Start         End      Blocks   Id  System
    /dev/xvdb1            2048   209715199   104856576   83  Linux

Write the config: `Command (m for help): w`

    The partition table has been altered!

    Calling ioctl() to re-read partition table.
    Syncing disks.

#### Edit /etc/hosts for the private network

Put whatever ip addresses you were given for your nodes in both of the server's `/etc/hosts`. This is good form an can save you in the event of a DNS outage.

    # cat << EOT >> /etc/hosts
    172.168.16.4 drbd0
    172.168.16.3 drbd1
    EOT

#### Edit DRBD configuration

First off, **these configurations must be identical on each of your servers.** I recommend using a terminal multiplexer or writing them locally/uploading them to each server.

Edit `/etc/drbd.d/global_common` - in the `syncer{}` section add `rate 30M;` to it.

for testing purposes we can deal with the defaults.

Now let's create a resource called `r0`, give it some liberal settings in `net{}` to allow for any weirdness/latency/packet loss; this is the cloud, not a private physical bonded interface - in my testing drbd will not stay connected unless you have 30GB instances.

```bash
# cat << EOT >> /etc/drbd.d/r0.res
    resource r0 {
      protocol C;
        net {
            cram-hmac-alg sha1;
            shared-secret "dupersupersecret";
            timeout 180;
            ping-int 3;
            ping-timeout 9;
        }
        on drbd0 {
            device /dev/drbd0;
            disk /dev/xvdb1;
            address 172.16.16.4:7788;
            meta-disk internal;
        }
        on drbd1 {
            device /dev/drbd0;
            disk /dev/xvdf1;
            address 172.16.16.3:7788;
            meta-disk internal;
        }
}
EOT
```

DRBD is pretty self explanatory - see the manpage for drbd.conf if you are curious about the parameters I use.

#### Create the r0 md on BOTH servers

Make DRBD aware of the `r0` resource on both servers

    # drbdadm create-md r0
    Writing meta data...
    initializing activity log
    NOT initialized bitmap
    New drbd meta data block successfully created.
    success

#### Start the DRBD service and sync on BOTH servers

If the drbd service is not already started, you may start it with

    # service drbd start

Once DRBD is started, Look at the status from one of the servers

    # cat /proc/drbd
    version: 8.3.11 (api:88/proto:86-96)
    srcversion: 71955441799F513ACA6DA60
     0: cs:SyncSource ro:Primary/Secondary ds:UpToDate/Inconsistent C r-----
        ns:20736 nr:0 dw:0 dr:21400 al:0 bm:1 lo:0 pe:0 ua:0 ap:0 ep:1 wo:f oos:104832604
    	[>....................] sync'ed:  0.1% (102372/102392)Mfinish: 22:24:00 speed: 1,296 (1,296) K/sec

**On DRBD0** , ensure it is master by reading `/proc/drbd` - if you do not see `ro:Primary/Secondary` then issue

    # drbdadm -- --overwrite-data-of-peer primary all

Make sure you only do this from the node you intend to be `Primary`

#### Make a filesystem on /dev/drbd0 from the Primary node

    # mkfs.ext4 /dev/drbd0

#### Mount drbd0 on the primary node

    # mkdir /drbd
    # mount /dev/drbd0 /drbd
    # touch /drbd/.woot.$RANDOM

Now you have a redundant block device on both servers! With this configuration, only one can mount it at a time, and only the Primary can have it mounted rw. You can swap it between drbd0 and drbd1 by doing the following

    drbd0# umount /drbd && drbdadm secondary r0
    drbd1# drbdadm primary r0 && mount /dev/drbd0 /drbd

Most production DRBD deployments do not have this done manually - they have some sort of cluster manager do this when it detects the Primary has a fault. That configuration is a little beyond the scope of this document though. If you are interested in having GFS2 on top of DRBD so that you can have the volume mounted and replicated on both servers at the same time, read on!

### Testing dual-primary mode with gfs2

GFS2 offers some pretty interesting functionality - in the most basic sense it will provide you with shared, redundant storage that multiple nodes can write to at the same time. This is useful for making quite a few applications redundant - from webservers to fileservers. This example is very basic but can be tweaked into very powerful environments with ease.

Umount all drbd resourcse and Install all the packages on both nodes

    umount /drbd
    apt-get install apt-get install gfs2-utils gfs2-cluster cman pacemaker fence-agents resource-agents openais

Modify the drbd resource on both servers to look something like this

    resource r0 {
            protocol C;
            startup{ become-primary-on both; }
            net {
                    cram-hmac-alg sha1;
                    shared-secret "dupersupersecret";
                    timeout 180;
                    ping-int 3;
                    ping-timeout 9;
                    allow-two-primaries;
                    after-sb-0pri discard-zero-changes;
                    after-sb-1pri discard-secondary;
                    after-sb-2pri disconnect;
            }
            on drbd0 {
                    device /dev/drbd0;
                    disk /dev/xvdb1;
                    address 172.16.16.4:7788;
                    meta-disk internal;
            }
            on drbd1 {
                    device /dev/drbd0;
                    disk /dev/xvdf1;
                    address 172.16.16.3:7788;
                    meta-disk internal;
            }
    }

    drbdadm adjust r0
    drbdadm primary r0

your `/proc/drbd` should look like

    # cat /proc/drbd
    version: 8.3.11 (api:88/proto:86-96)
    srcversion: 71955441799F513ACA6DA60
     0: cs:Connected ro:Primary/Primary ds:UpToDate/UpToDate C r-----
        ns:12 nr:0 dw:0 dr:676 al:0 bm:2 lo:0 pe:0 ua:0 ap:0 ep:1 wo:f oos:0

#### Configure cluster.conf and corosync.conf as such on both nodes

Edit **/etc/cluster/cluster.conf** to resemble the following example:

    <?xml version="1.0"?>
    <cluster config_version="4" name="pacemaker">
     <fence_daemon clean_start="0" post_fail_delay="0" post_join_delay="3"/>
      <clusternodes>
       <clusternode name="drbd0" nodeid="1" votes="1">
        <fence>
         <method name="pcmk-redirect">
          <device name="pcmk" port="drbd0"/>
         </method>
        </fence>
       </clusternode>
       <clusternode name="drbd1" nodeid="2" votes="1">
        <fence>
         <method name="pcmk-redirect">
          <device name="pcmk" port="drbd1"/>
         </method>
        </fence>
       </clusternode>
      </clusternodes>
      <fencedevices>
       <fencedevice name="pcmk" agent="fence_pcmk"/>
      </fencedevices>
     <cman/>
    </cluster>

Edit **/etc/corosync/corosync.conf** to resemble the following example:

    totem {
        version: 2
        token: 3000
        token_retransmits_before_loss_const: 10
        join: 60
        consensus: 3600
        vsftype: none
        max_messages: 20
        clear_node_high_bit: yes
        secauth: off
        threads: 0
        rrp_mode: none
        interface {
            ringnumber: 0
            bindnetaddr: 172.16.16.0
            mcastaddr: 226.94.1.1
            mcastport: 5405
        }
    }
    amf {
        mode: disabled
    }
    service {
        ver:       1
        name:      pacemaker
    }
    aisexec {
            user:   root
            group:  root
    }
    logging {
            fileline: off
            to_stderr: yes
            to_logfile: no
            to_syslog: yes
        syslog_facility: daemon
            debug: off
            timestamp: on
            logger_subsys {
                    subsys: AMF
                    debug: off
                    tags: enter|leave|trace1|trace2|trace3|trace4|trace6
            }
    }

For more information about these config files, see `man 5 corosync.conf`, and `man 5 cluster.conf`.

Start the services and configure them to run on boot for both servers

    # service cman start
    # service pacemaker start
    # update-rc.d cman enable
    # update-rc.d pacemaker enable

Configure some resources and a dummy stonith - we don't want stonith to do anything we aren't expecting it to. Since this is a cluster, we only need to do this on one node.

    drbd0# crm configure edit
    node drbd0
    node drbd1
    primitive rdlm_controld ocf:pacemaker:controld \
        params daemon="dlm_controld" \
        op monitor interval="55s"
    primitive rgfs2_controld ocf:pacemaker:controld \
        params daemon="gfs_controld" args="" \
        op monitor interval="55s"
    primitive st-null stonith:null \
        params hostlist="drbd0 drbd1"
    clone cdlm rdlm_controld \
        meta globally-unique="false" interleave="true"
    clone cgfsd rgfs2_controld \
        meta globally-unique="false" interleave="true" target-role="Started"
    clone fencing st-null
    colocation col_gfsd_dlm inf: cgfsd cdlm
    order ordDLMGFSD 0: cdlm cgfsd
    property $id="cib-bootstrap-options" \
        dc-version="1.1.6-9971ebba4494012a93c03b40a2c58ec0eb60f50c" \
        cluster-infrastructure="cman" \
        no-quorum-policy="ignore"

pacemaker configuration is a little beyond the scope of this post. If you have any questions about any of the above, I recommend [some clusterlabs documentation](http://clusterlabs.org/doc/en-US/Pacemaker/1.1-plugin/html-single/Clusters_from_Scratch/index.html)

This may take a while for crm to actuall do its thing; verify that your `crm status` looks like this before moving on

    drbd0# crm status
    ============
    Last updated: Wed Feb  6 06:53:11 2013
    Last change: Wed Feb  6 06:35:37 2013 via cibadmin on drbd1
    Stack: cman
    Current DC: drbd0 - partition with quorum
    Version: 1.1.6-9971ebba4494012a93c03b40a2c58ec0eb60f50c
    2 Nodes configured, unknown expected votes
    6 Resources configured.
    ============

    Online: [ drbd0 drbd1 ]

     Clone Set: cdlm [rdlm_controld]
         Started: [ drbd0 drbd1 ]
     Clone Set: cgfsd [rgfs2_controld]
         Started: [ drbd0 drbd1 ]
     Clone Set: fencing [st-null]
         Started: [ drbd0 drbd1 ]

Make sure `/dev/drbd0` **isn't mounted on either node**, and mkfs.gfs2 on the Primary node

    drbd0# mkfs.gfs2 -t pacemaker:pcmk -p lock_dlm -j 2 /dev/drbd0

Mount `/dev/drbd0` on both nodes

    # mkdir /clustered
    # cat << EOT >> /etc/fstab
    /dev/drbd0  /clustered  gfs2    noatime 0   0
    EOT
    # mount /clustered

Enjoy your dual-primary gfs2 backed volume on CBS over Cloud Networks! Now you can have both servers configured to have their webroot in `/clustered` (or wherever you want) and retain uptime when one of the web servers becomes unavailable.

---

### GlusterFS instead of drbd+gfs2

Suppose you don't need cheap, redundant performance; instead you need a highly scalable, reasonably performant storage environment - we can use Cloud Block Storage and Cloud Networks to create such an environment in a secure and relatively inexpensive way. Since this is "the cloud," we'll take advantage of Cloud Block storage to proivde us with re-mappable disks, growable via LVM, and use Cloud Networks to keep our critical data away from prying eyes. The below architecture consists of four type 4 Cloud Servers acting as Gluster endpoints, and two type 3 cloud servers acting as web servers. The Gluster servers will host a distributed replicated (2 mirrors) volume to any servers in the Gluster Client network. The Gluster endpoints themselves will replicate data over their own private network.



                 ************        ************
                 * Internet *        * Internet *
                 ************        ************
                       ^                   ^
                       |                   |
                   .------.            .------.
                   | eth0 |            | eth0 |
                   '------'---------.  '------'---------.
                   |    Web Head    |  |   Web Head n   |
                   .------.--.------.  .------.--.------.
                   | eth1 |  | eth2 |  | eth1 |  | eth2 |
                   '------'  '------'  '------'  '------'
                       |         |         |         |
                       |         |         |         |
                       |         v         |         v
                   .---|-------------------|--------------------------------------------.---.
                   |   |            Virtual|Private Switch (Gluster Clients)            |   |
                   '---|-------------------|--------------------------------------------|   |
                       v                   v                                            |   |
                  .---------------------------------------------------------------.     |   |
                  |                          Service Net                          |     |   |
                  '---------------------------------------------------------------'     |   |
                    ^                   ^                   ^                   ^       |   |
                    |                   |                   |                   |       |   |
    ************    |   ************    |   ************    |   ************    |       |   |
    * Internet *    |   * Internet *    |   * Internet *    |   * Internet *    |       |   |
    ************    |   ************    |   ************    |   ************    |       |   |
          ^         |         ^         |         ^         |         ^         |       |   |
          |         |         |         |         |         |         |         |       |   |
      .------.  .------.  .------.  .------.  .------.  .------.  .------.  .------.    |   |
      | eth0 |  | eth1 |  | eth0 |  | eth1 |  | eth0 |  | eth1 |  | eth0 |  | eth1 |    |   |
      '------'--'------'  '------'--'------'  '------'--'------'  '------'--'------'    |   |
      | Storage Server |  | Storage Server |  | Storage Server |  | Storage Server |    |   |
      .------.--.------.  .------.--.------.  .------.--.------.  .------.--.------.    |   |
      | eth3 |  | eth2 |  | eth3 |  | eth2 |  | eth3 |  | eth2 |  | eth3 |  | eth2 |    |   |
      '------'  '------'  '------'  '------'  '------'  '------'  '------'  '------'    |   |
          |         |         |         |         |         |         |         |       |   |
          |         |         |         |         |         |         |         |       |   |
          |         |         |         |         |         |         |         |       |   |
          v         |         v         |         v         |         v         |       |   |
         .----------|-------------------|-------------------|------------.      |       |   |
         |          |    Virtual Private|Switch (storage)   |            |      |       |   |
         '----------|-------------------|-------------------|------------'      |       |   |
                    |                   |                   |                   |       |   |
                    |                   |                   |                   |       |   |
                    v                   v                   v                   v       |   |
                   .--------------------------------------------------------------------|   |
                   |                Virtual Private Switch (Gluster Clients)            |   |
                   '--------------------------------------------------------------------'---'

### Quick overview of the steps

#### Create two private networks

Create two networks that your instances will be attached to - the gluster servers will be attached to both of the following networks, while the web heads will only be attached to one of them

    > nova network-create storageManagement 192.168.25.0/24
    > nova network-create storageClients 192.168.50.0/24

#### Create some volumes

Create four Cloud Block Storage volumes - one for each Gluster server. We'll create them as SSD volumes to get slightly better read-performance out of them.

    > for i in 0 1 2 3; do
        nova volume-create --display-name glusterbrick${i} --volume-type SSD 100
    done

#### Create four type 4 servers that are attached to your private nets

Create 4 servers - the Gluster servers - we'll use CentOS6.3 (found from `nova image-list`) in this case. Below I use the `--file=` option to put my public key in root's authorized_keys file so I don't have to use the passwords returned to me above. I also specify the NICs that should be attached to each instance (found via `nova network-list`). I also specify `--flavor 4` to take advantage of more RAM and CPU. The reason I specify a sleep value is to make sure the nova scheduler has some time to put my instances on very different hypervisors.

    > for i in 0 1 2 3; do
        nova boot --image c195ef3b-9195-4474-b6f7-16e5bd86acd0 \
        --file /root/.ssh/authorized_keys=/home/niko5420/.ssh/id_rsa.pub \
        --nic net-id=f1331532-12e5-41e6-9bb5-df31758c8bf2 \
        --nic net-id=7e9fcfa0-b3f6-40e2-91ef-8aa720d4f29a \
        --flavor 4 \
        gluster-0${i};
        sleep 30
    done

#### Log in to all servers, fix sshd so it doesn't take ages to log in, and update/upgrade && reboot

Do some initial configuration - the following commands should be run on all the servers you created above (I recommend using a terminal multiplexer like terminator, or cssh)

    # sed -i.orig 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
    # service sshd restart
    # cat << EOT >> /etc/hosts
    192.168.50.3 gluster-00-clients
    192.168.25.3 gluster-00-servers
    192.168.25.2 gluster-01-servers
    192.168.50.2 gluster-01-clients
    192.168.50.6 gluster-02-clients
    192.168.25.6 gluster-02-servers
    192.168.25.5 gluster-03-servers
    192.168.50.5 gluster-03-clients
    EOT
    # yum update -y && reboot

#### Install epel and glusterfs from packages

After rebooting, install epel, update and install some necessary packages on all of the Gluster servers you created

    # rpm -Uvh http://mirror.nexcess.net/epel/6/i386/epel-release-6-8.noarch.rpm
    # yum update -y
    # yum install glusterfs-server lvm2

#### Attach the CBS devices to their relevant hosts

Now that you have everything installed, attach the volumes to their instances. You'll need to use the relevant uuids returned for you from `nova volume-list` and `nova list`

the format to attach a volume is `nova volume-attach <server> <volume> <device>` . In this case, we'll use `/dev/xvdg` - just because.

    > for m in "e3d92b9b-e2a3-44ea-8c64-624ccfc6b742 5f7b6b37-7ba3-43a7-89cc-7c66ca2bc57b" \
    "6ba95162-b788-44ce-9067-f203f89b9fdf ea0c5eb1-b2fc-466a-b42e-aaabe4cb7d3e" \
    "6aabc9e8-2e1b-4160-a28a-c180ccaf3843 235736b1-077a-4dc5-af49-820529f5b31d" \
    "5bbbe71a-b34c-4c51-b324-ed4220163681 f1ce079b-6108-4024-9b24-542ebdd0c9ab"; do \
    nova volume-attach $m /dev/xvdg; done

#### Once the devices are attached, format them to a single partition and align them

It may take a minute or two for the devices to be added in CentOS - once they are create a single partition on the device and align it to the 2048th sector if it isn't already. Do this on all of the Gluster servers.

    fdisk /dev/xvdg
    Device contains neither a valid DOS partition table, nor Sun, SGI or OSF disklabel
    Building a new DOS disklabel with disk identifier 0xf83dadfd.
    Changes will remain in memory only, until you decide to write them.
    After that, of course, the previous content won't be recoverable.

    Warning: invalid flag 0x0000 of partition table 4 will be corrected by w(rite)

    WARNING: DOS-compatible mode is deprecated. It's strongly recommended to
             switch off the mode (command 'c') and change display units to
             sectors (command 'u').

Create a new partition: `Command (m for help): n`

    Command action
       e   extended
       p   primary partition (1-4)

A Primary partition: `p`

Partition 1: `Partition number (1-4): 1`

Default first cylinder: `First cylinder (1-13054, default 1):`

    Using default value 1

Default last cylinder: `Last cylinder, +cylinders or +size{K,M,G} (1-13054, default 13054):`

    Using default value 13054

Drop into expert mode: `Command (m for help): x`

Set the beginning of the disk: `Expert command (m for help): b`

Select partition 1: `Partition number (1-4): 1`

Align to 2048: `New beginning of data (1-209712509, default 63): 2048`

Return to regular mode: `Expert command (m for help): r`

Write the configuration: `Command (m for help): w`

    The partition table has been altered!

    Calling ioctl() to re-read partition table.
    Syncing disks.

#### Add the partition to LVM, make a filesystem on it and mount it

Since we're using CBS, we want to take advantage of the fact that we can willy-nilly add volumes to our server and increase/decrease our storage. Put the new partition into lvm and format it. We'll make it 50GB just because, and make it ext4. Do this on all of the Gluster servers.

    # pvcreate /dev/xvdg1
    # vgcreate glusterpool /dev/xvdg1
    # lvcreate --size 50G --name glusterlv00 glusterpool
    # mkfs.ext4 /dev/glusterpool/glusterlv00
    # echo "/dev/glusterpool/glusterlv00 /exports/glusterlv00 ext4 defaults,noatime 0 0" >> /etc/fstab
    # mkdir -p /exports/glusterlv00
    # mount /exports/glusterlv00

#### Start glusterd on all servers, set it to start on boot, and modify iptables to allow the glusterd traffic

Now we're ready to start gluster - run the following commands on all of the Gluster servers you created.

    # service glusterd start
    # chkconfig glusterd on

In /etc/sysconfig/iptables, add some lines in to allow glusterd communication. For this example I am simply allowing all traffic to flow on eth2 and eth3 while leaving eth1 and eth0 filtered. In the real world, you should really fix this so that gluster can communicate without giving free range to anyone on those interfaces.

    # Firewall configuration written by system-config-firewall
    # Manual customization of this file is not recommended.
    *filter
    :INPUT ACCEPT [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    -A INPUT -p icmp -j ACCEPT
    -A INPUT -i lo -j ACCEPT
    -A INPUT -i eth2 -j ACCEPT
    -A INPUT -i eth3 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
    -A INPUT -j REJECT --reject-with icmp-host-prohibited
    -A FORWARD -j REJECT --reject-with icmp-host-prohibited
    COMMIT

    # service iptables restart

#### From a single node probe the rest of the gluster servers

Now that `glusterd` is staretd, run the following commands from only one of the Gluster servers - in the example I use `gluster-00` to probe the other members, omitting `gluster-00` itself.

    [root@gluster-00 etc]# gluster peer probe gluster-01-servers
    Probe successful
    [root@gluster-00 etc]# gluster peer probe gluster-02-servers
    Probe successful
    [root@gluster-00 etc]# gluster peer probe gluster-03-servers
    Probe successful
    [root@gluster-00 etc]# gluster peer status
    Number of Peers: 3

    Hostname: gluster-01-servers
    Uuid: 1c8d258b-22de-4a5b-bb6a-8b458e5a7115
    State: Peer in Cluster (Connected)

    Hostname: gluster-02-servers
    Uuid: ee151a51-6aa8-4e3b-ba80-6131b05e40ca
    State: Peer in Cluster (Connected)

    Hostname: gluster-03-servers
    Uuid: 050d0e4f-961e-44d1-9db9-1597723aaa45
    State: Peer in Cluster (Connected)

Keep in mind that because we probed the name `gluster-[0-9][0-9]-servers`, that **name** will be returned to clients when they attempt to mount - make sure the clients have the correct IP address/name set for the name in `/etc/hosts` (done below, but just in case you find yourself reviewing this document trying to figure out why your clients cant mount the gluster volume)

#### Create a distributed replica-2 volume - do this from only one of the servers

Now we're ready to create and start a volume. Below is the standard way to create a distributed replicated volume using 2 mirrors . Essentially this means that your data is mirrored on at least 1 other node - you can lose 3 of your gluster servers and still serve data. Do this from one node only, it doesn't matter which since they're all members of the clutser.

    [root@gluster-00 etc]# gluster volume create webData replica 2 transport tcp \
    gluster-00-servers:/exports/glusterlv00 \
    gluster-01-servers:/exports/glusterlv00 \
    gluster-02-servers:/exports/glusterlv00 \
    gluster-03-servers:/exports/glusterlv00
    Creation of volume webData has been successful. Please start the volume to access data.
    [root@gluster-00 etc]# gluster volume set webData auth.allow 192.168.50.*
    Set volume successful
    [root@gluster-00 etc]# gluster volume start webData
    Starting volume webData has been successful

You can verify that things are groovy by running `gluster volume info all` from another one of the nodes

    [root@gluster-03 etc]# gluster volume info all

    Volume Name: webData
    Type: Distributed-Replicate
    Status: Started
    Number of Bricks: 2 x 2 = 4
    Transport-type: tcp
    Bricks:
    Brick1: gluster-00-servers:/exports/glusterlv00
    Brick2: gluster-01-servers:/exports/glusterlv00
    Brick3: gluster-02-servers:/exports/glusterlv00
    Brick4: gluster-03-servers:/exports/glusterlv00
    Options Reconfigured:
    auth.allow: 192.168.50.*

#### Creating some webheads

Now that the storage cluster is configured, let's build the clients

Build two servers, type 3 (we don't need as much ram and want to keep costs down) - attach them to the `glusterClients` network (uuid found in `nova network-list`).

    for i in 0 1; do nova boot --image c195ef3b-9195-4474-b6f7-16e5bd86acd0 \
    --file /root/.ssh/authorized_keys=/home/niko5420/.ssh/id_rsa.pub \
    --nic net-id=7e9fcfa0-b3f6-40e2-91ef-8aa720d4f29a \
    --flavor 3 webHead${i}; sleep 30; done

Once they're booted, do the same steps as above to get them updated and using proper packages. Do this on both web heads.

    # sed -i.orig 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
    # service sshd restart
    # yum update -y && reboot
    # rpm -Uvh http://mirror.nexcess.net/epel/6/i386/epel-release-6-8.noarch.rpm
    # yum update
    # yum install -y glusterfs-fuse nginx
    # cat << EOT >> /etc/hosts
    192.168.50.3 gluster-00-servers
    192.168.50.2 gluster-01-servers
    192.168.50.6 gluster-02-servers
    192.168.50.5 gluster-03-servers
    EOT
    # mkdir /webData
    # echo "gluster-00-servers:/webData	/webData glusterfs defaults,_netdev 0 0" >> /etc/fstab
    # mount /webData
    # sed -i.orig 's#/usr/share/nginx/html#/webData#g' /etc/nginx/conf.d/default.conf
    # service nginx restart
    # cp /usr/share/nginx/html/* /webData/

Now go to the ips of one of the webheads and enjoy your new highly scalable web environment! For more information on GlusterFS see [their documentation](http://gluster.org/community/documentation/index.php/). For proper load balancing, see [Rackspace's Cloud Load Balancers offering](http://www.rackspace.com/cloud/load-balancing/). Otherwise you can always just use DNS.

#### Quick benchmarks

Here are the results from some benchmarks I took before destroying the environment

    # dd if=/dev/urandom of=/webData/2mbR bs=1M count=2

Then from another server at rackspace (in DFW instead of ORD) I ran siege against the big file with not-totally-disappointing results

    $ sudo siege -c30 http://g.niko.im/2mbR -i --time=30S
    ** SIEGE 2.70
    ** Preparing 30 concurrent users for battle.
    The server is now under siege...

I got the following results the first time

    Lifting the server siege...      done.
    Transactions:                 89 hits
    Availability:             100.00 %
    Elapsed time:              29.05 secs
    Data transferred:         178.00 MB
    Response time:              7.38 secs
    Transaction rate:           3.06 trans/sec
    Throughput:             6.13 MB/sec
    Concurrency:               22.60
    Successful transactions:          89
    Failed transactions:               0
    Longest transaction:           20.67
    Shortest transaction:           3.80

Second test results

    Lifting the server siege...      done.
    Transactions:                 90 hits
    Availability:             100.00 %
    Elapsed time:              29.29 secs
    Data transferred:         180.00 MB
    Response time:              7.40 secs
    Transaction rate:           3.07 trans/sec
    Throughput:             6.15 MB/sec
    Concurrency:               22.73
    Successful transactions:          90
    Failed transactions:               0
    Longest transaction:           15.90
    Shortest transaction:           2.70

The third time I let the test run for `--time=1M` instead of 30 seconds

    Lifting the server siege...      done.
    Transactions:                190 hits
    Availability:             100.00 %
    Elapsed time:              59.14 secs
    Data transferred:         380.00 MB
    Response time:              7.82 secs
    Transaction rate:           3.21 trans/sec
    Throughput:             6.43 MB/sec
    Concurrency:               25.13
    Successful transactions:         190
    Failed transactions:               0
    Longest transaction:           23.30
    Shortest transaction:           1.65

The final test I turned the concurrency up to `-c 50` instead of 30 and let it run for 1 minute

    Lifting the server siege...      done.
    Transactions:                182 hits
    Availability:             100.00 %
    Elapsed time:              59.10 secs
    Data transferred:         364.00 MB
    Response time:             13.07 secs
    Transaction rate:           3.08 trans/sec
    Throughput:             6.16 MB/sec
    Concurrency:               40.24
    Successful transactions:         182
    Failed transactions:               0
    Longest transaction:           26.12
    Shortest transaction:           2.85

Since this particular instance type is limited to 30Mb/s on its public interface, the throughput results of 60Mb/s suggest that I can scale this horizontally to meet demands without taking a moment of downtime.
