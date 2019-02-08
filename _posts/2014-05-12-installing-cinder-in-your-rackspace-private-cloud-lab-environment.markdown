---
layout: post
title: Installing Cinder in Your Rackspace Private Cloud lab environment
date: '2014-05-12 10:21'
comments: true
author: Jason Grimm
published: true
categories:
  - OpenStack
  - Private Cloud
---

This is the first installment of installing and using OpenStack Cinder in your private cloud.

<!-- more -->

### Environment preparation – Operating System

The following configuration tasks in this section are to be completed on both
chef-1 and controller-1 unless otherwise indicated.

#### Install the OS

Install the operating system (manually or with an image, snapshot, template, etc.)

Accept all of the installation defaults and once complete run update / upgrade
and reboot on both hosts. The git package (required for the initial cookbook and
package downloads) should be the only additional package that needs to be
installed by hand; the remaining dependencies are installed automatically by
the deployment process.

```sh
# apt-get update
# apt-get upgrade
# apt-get -y install git
# reboot
```

#### SSH keys

Chef is capable of handling the ssh key distribution for us; however, as a
personal preference, I typically perform this step manually and ensure it's all
working before I install chef. The only requirement is for chef-1 to have ssh
pass-thru authentication to controller-1 but there is no harm in having
bi-directional pass-thru authentication if that's preferable.

1. The commands (from the chef server) to accomplish this are:

```sh
# ssh-keygen
# ssh-copy-id -i ~/.ssh/id\_rsa.pub root@controller-1
```

_TIP: Accept the defaults unless you want to specify different key types or key strength, e.g. ssh-keygen -t rsa or dsa, -b 1024 or 4096, etc.)._

Some distributions or packaging of openssh do not include the ssh-copy-id command.
In this case it's likely faster and easier to copy the keys by hand vs. installing
a modified or recompiled version of openssh. To accomplish this manually you can
use these example steps:

```sh
# ssh-keygen
# cat ~/.ssh/id\_rsa.pub > ~/.ssh/authorized\_keys
# chmod 400 ~/.ssh/authorized\_keys
# ssh root@controller-1 "mkdir /root/.ssh; chmod –R 400 /root/.ssh"
# scp ~/.ssh/authorized\_keys root@controller-1:/root/.ssh/
```

If everything worked correctly you should now be able to ssh, as root, from
chef-1 to controller-1 without any authentication prompts.

#### Other settings

Also be sure to setup all of your other basic services and settings. Some of
your considerations may include:

1. Configuring (or disabling) iptables
  1. If leaving iptables enabled you'll need to open several ports for RPC to function properly. You can find most of these ports listed in the "api settings" tab for the "security and access" menu on the project tab. They are also listed in the /root/openrc file automatically created during the installation process.

_TIP: I recommend installing with iptables off to ensure you have a good working deployment and then going back afterwards to lock the ports down._

1. Ensure name resolution works correctly for both long (FQDN) and short name (hostname -s) references
  1. /etc/hosts file tends to be the fastest / easiest
  2. Place the long host names first then any aliases, for example 10.0.20.51 chef-1.yourdomain.local chef-1

3. Ensure time zones are set correctly and NTP is synchronized on both hosts (particularly important when deploying on top of virtual machines due to hardware clock drift)
4. Ensure Internet connectivity and necessary repository access is present

### Environment preparation – cinder-volumes

The following configuration tasks are to be completed on controller-1.

1. We'll be using the native Linux Volume Manager to provide block storage backing for our environment.
2. Likewise the cinder LVM driver will be used to connect to this storage.
3. By design, and due to the custom storage configuration nature – the "cinder-volumes" volume group is not setup by the chef cinder-volume role and must be completed beforehand.
4. Here are a couple of convenient tips I've found for setting up this volume group.
  1. You may have noticed that the default behavior of the Ubuntu server installation (as well as most templates) is to use LVM; however, it typically creates only a single physical volume, a single volume group and also consumes all space on the device.
  2. You can still create the cinder-volumes volume group but you'll need to either:
    1. Add another disk (which may not be readily available) to be used by cinder-volumes, or:
    2.  Reconfigure LVM (which can be tedious):
      1. Resize the logical volumes (typically root and swap) in the existing volume group
      2. Resize the volume group itself
      3. Resize the underlying physical volume
      4. Create a new partition in the newly available space on the disk
      5. Run pvcreate to create a new physical volume for LVM to manage
      6. Run vgcreate cinder-volumes on this newly available physical volume

Optionally I have found that a third method for creating the cinder-volumes group using a loopback device is much faster and easier.

This is not optimal for performance but is perfectly suitable for basic, functional testing.

You can accomplish this quickly and easily with the following commands which creates a 5 GB cinder-volumes volume group (adjust block size, count, etc. to suit your needs).

_TIP: Ensure you have sufficient free space on your /root mount before running this command; accidentally filling up the /root mount will certainly cause issues._

```sh
# Create image

# dd if=/dev/zero of=/root/pv1.img bs=2M count=2500

# Setup the loopback device

# losetup /dev/loop0 pv1.img

# Partition the loopback device

# sfdisk /dev/loop0 << EOF

#,,8e,,

# EOF

# Scan devices and volume groups to detect the device changes

# pvscan

# vgscan

# Create physical volume and volume group

# pvcreate /dev/loop0

# vgcreate cinder-volumes /dev/loop0

# Display results

# vgs

```

_TIP: If creating larger volumes you may want to use the seek option with dd or the fallocate command vs. waiting for each block of data to write out. The cinder service zeros out all blocks regardless when it initializes so there should be no security or stale data concerns._

If everything executed correctly your final output should look similar to this:

```sh
root@controller-1:~# vgs

 VG       #PV #LV #SN Attr  VSize VFree

 cinder-volumes  1  0  0 wz--n- 4.88g 4.88g

 rackspace1    1  2  0 wz--n- 19.76g 20.00m
```

This concludes the operating system and storage configuration tasks, move on to the chef and environment installation processes.

### Environment Creation – Installing Chef, cookbooks, and creating the environment file

In this section we will cover installing chef and configuring your environment file.

As mentioned, a complete installation procedure is not detailed here but the high level steps are outlined below.

#### Install Chef

The basic commands to install chef-server on chef-1 are as follows:

```sh
# Download the installation script

# curl -s -O https://raw.github.com/rcbops/support-tools/master/chef-install/install-chef-server.sh

# Run the installer

# bash install-chef-server.sh

# Source the modified .bash\_profile to declare the necessary knife environment variables

# . /root/.bash\_profile

# Test the knife command

# knife client list
```

#### Install cookbooks

In this section we'll download and install the RPC cookbooks. To download the installation script run the following command.

```sh
# curl -s -O https://raw.github.com/rcbops/support-tools/master/chef-install/install-cookbooks.sh
```

Before running the shell script to install the cookbooks, use an editor to check and or edit the install-cookbooks.sh script and set the branch parameter according to your needs.

In this exercise we'll be using 4.2.2rc; the current default stable branch is 4.2.1.

```sh
# Check the current RPC version declared in the script

# grep –m1 BRANCH /root/install-cookbooks.sh

COOKBOOK\_BRANCH=${COOKBOOK\_BRANCH:-v4.2.1}

# Modify the script to set your desired branch

# vi install-cookbooks.sh
```
or

```sh
# Use an in-line sed

# sed -i -e 's/v4.2.1/v4.2.2rc/g' install-cookbooks.sh


# Verify that your edits were added properly

# grep –m1 BRANCH /root/install-cookbooks.sh

COOKBOOK\_BRANCH=${COOKBOOK\_BRANCH:-v4.2.2rc}

# Execute the install script

# bash /root/install-cookbooks.sh
```

Now that our ssh keys are in place, chef server is installed and our cookbooks
are downloaded and installed it is time to create an environment file.

#### Create the environment file

Your specific environment file will vary but there are a few sections of interest to our installation. The entire environment file is shown in pieces below for your reference; the relevant sections are highlighted.

1. Create / edit the environment file.

```sh
# Open / create the environment file in a text editor, for example

# vi rpc422rc.json
```

2. Change the header to match what you want the name of the environment to be, for convenience I match the environment name and the file name to the version number. Basic glance settings are also shown here.

```javascript
{

 "name": "rpcv422rc",

 "description": "Rackspace Private Cloud v4.2.2rc",

 "cookbook\_versions": {},

 "json\_class": "Chef::Environment",

 "chef\_type": "environment",

 "default\_attributes": {

 },

 "override\_attributes": {

  "glance": {

      "images": [

        "cirros-0.3.1-x86\_64",

        "ubuntu-server-12.04.3-x86\_64"

      ],

      "image": {

        "cirros-0.3.1-x86\_64": "http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86\_64-disk.img",

        "ubuntu-server-12.04.3-x86\_64": "http://cloud-images.ubuntu.com/releases/12.04.3/release/ubuntu-12.04-server-cloudimg-amd64-disk1.img"

      },

      "image\_upload": true

    },
```

Because I'm installing OpenStack on top of a hypervisor that doesn't support VT
acceleration, I have to set my virtualization type to qemu; also not suitable
for production but sufficient for functional testing. If you have a hypervisor
that supports VT acceleration you can leave this stanza out altogether as the
cookbook defaults to kvm or you can manually specify it if you like.

```javascript
  "nova": {
   "libvirt": {
   "vncserver\_listen": "0.0.0.0",
   "virt\_type": "qemu"
   },
```

Additionally, you may opt to specify your cinder configuration options. The
parameters listed here are actually the default settings in the cookbook, which
works well for this environment; however, I generally specify them regardless
in case the defaults change. It is also handy as a placeholder if I reuse the
environment file or need to make modifications to the settings later on.

```javascript
"cinder" : {

"storage" : {

"provider" : "lvm",

"enable\_multipath" : false,

"lvm" : {

"volume\_group" : "cinder-volumes",

"volume\_clear" : "zero",

"config" : "/etc/lvm/lvm.conf"

}

},

"services" : {

"volume" : {

"network" : "cinder"

}

}

},
```

Lastly, if you're not accustom to running a single NIC / single subnet environment,
then you may want to review the network settings as well. Also shown here are
basic neutron configuration directives.

```javascript
   "network": {

    "provider": "neutron"

   }

  },

  "neutron": {

   "ovs": {

    "provider\_networks": [

     {

      "label": "ph-eth0",

      "bridge": "br-eth0",

      "vlans": "1:1"

     }

    ],

    "network\_type": "gre"

   }

  },

  "mysql": {

    "allow\_remote\_root": true,

    "root\_network\_acl": "%"

  },

  "osops\_networks": {

   "nova": "10.0.20.0/24",

   "public": "10.0.20.0/24",

   "management": "10.0.20.0/24",

   "cinder" : "10.0.20.0/24"

  }

}
```

Once complete you are ready to create your environment.

### knife environment from file rpcv422rc.json

_TIP: JSON is very sensitive to white space in formatting so I would recommend pasting this into a text editor first and removing any special characters or, better yet, just type it in manually to avoid parsing errors due to formatting._

_TIP: I usually create this file with a text editor and when complete use the "knife environment from file" creation process vs. the "knife environment edit" command (as some documentation refers to). The "knife environment edit" approach will not retain your environment edits if there are issues with syntax or definitions. Instead your edits are lost each time it fails and there is no debug information displayed either._

#### Environment Deployment

All the tedious work is over, now we push our roles to our controller / compute node with the following command.

```sh
# knife bootstrap controller-1. -E  -r 'role[single-controller],role[single-compute],role[heat-all],role[ceilometer-all],role[cinder-all],role[neutron-network-manager]'
```

### Conclusion

In this article we covered the basics of a cinder-enabled environment creation and deployment.

Look for future cinder related posts with more advanced topics such as using NetApp, EMC or SolidFire cinder drivers, providing Cinder HA to your instances and using multiple cinder devices to provide workload separation and performance tiering for your instances.

## Reference Material

You may also find the following references helpful as you explore cinder functionality further.

- [RPC How-to documentation](https://support.rackspace.com/how-to/rpc-openstack/)
- [How-to Block Storage documentation](https://support.rackspace.com/how-to/cloud-block-storage-all-articles/)
