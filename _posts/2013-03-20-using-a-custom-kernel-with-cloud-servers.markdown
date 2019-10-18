---
layout: post
title: Using a custom kernel with the Ubuntu Installer
date: '2013-03-20 8:00'
comments: true
author: Jordan Evans
categories:
  - Cloud Servers
---
EDIT: This blog post has been edited! As it turns out, the preseed was stored in a location that didn't always work. Instead, we now decompress the initrd.gz, and add a preseed there. This is a better location, because the Ubuntu installer always looks for it there, even if not told to. We also moved installing the new kernel to the end of the preseed, to be sure it runs all the postinstall scripts. We changed how we remove the 2.6 kernel to specifically catch the version before removing it.

Here at Rackspace on the Cloud Monitoring team, we use Ubuntu 10.04 LTS. We recently purchased some new Dell Poweredge R720 (our older standard hardware wasn't offered anymore) and we found out the new hardware is not supported by the 10.04 default kernel!

Our original workaround was to build the new drivers against the 10.04 2.6 kernel, and load them at install time. At the end of the install, we would then manually install the new kernel, remove the 2.6 kernel, and then reboot. This worked, but it took an awful lot of time.

Therefore we set out to build an Ubuntu 10.04 installer that runs on, and installs, a more recent kernel.<!-- more -->

We chose to use the linux-image-server-lts-backport-oneiric image, which currently installs the linux-image-3.0.0-30-server package (and sets up the grub config, etc).
 
## Prerequisites

This needs to be done on Ubuntu 10.04, so spin up a vm or Cloud Server, and do the following.

Lets start by installing some required packages

```bash
$ sudo apt-get install build-essential pbuilder bc debiandoc-sgml libbogl-dev glibc-pic libslang2-pic libnewt-pic genext2fs mklibs genisoimage dosfstools syslinux tofrodos mtools po4a bf-utf-source fakeroot crash kexec-tools makedumpfile kernel-wedge
``` 

We will also need to add the following lines to `/etc/apt/sources.list`

```
deb https://archive.ubuntu.com/ubuntu/ lucid main/debian-installer
deb https://archive.ubuntu.com/ubuntu/ lucid-updates main/debian-installer
deb https://archive.ubuntu.com/ubuntu/ lucid-backports main/debian-installer
deb https://archive.ubuntu.com/ubuntu/ lucid-security main/debian-installer
```

After which you will need to run

```bash
$ sudo apt-get update
```

Now that we have the pre-requisites out of the way, we can pull in the source for debian-installer. The following pulls in the source, untars it, changes to the build directory in the source, and makes the destination directory (where the completed iso will go)

```bash
$ mkdir build && cd build
$ apt-get source debian-installer
$ tar zxvf debian-installer*.tar.gz
$ cd debian-installer/build
$ mkdir dest
```

# Building the Image

Next we need to modify a config file, config/amd64.cfg. We need to change the KERNELVERSION and KERNELMAJOR to reflect our wish for a 3.0 kernel. Change it from

```
# The version of the kernel to use.
#KERNELVERSION = 2.6.32-41-generic
#KERNELMAJOR = 2.6
KERNELVERSION = 3.0.0-30-server
KERNELMAJOR = 3.0
```

If you wish to use something other than 3.0.0-30, (or something other than the server kernel), you will need to make sure that a package exists in the repository that matches `linux-image-$KERNELVERSION`. For example, `3.0.0-30-generic` is also a valid $KERNELVERSION.

Now lets build us a new netboot image!

```
# you can see a list of all available choices by running
# make list
# We will just be building a netboot image in this case though, so all we need is
$ make build_netboot
```

Finally, lets make sure it built our mini.iso

```bash
$ ls dest/netboot/mini.iso
```

# Adding the Preseed
Unfortunately, we aren't yet done. We have created an iso that runs off this newer kernel, but it won't install the kernel when used. Lets add a preseed that installs the right kernel (and, remove the old kernel).

```bash
$ mkdir -p tmp/iso tmp/initrd.d
$ mount -o loop -t iso9660 dest/netboot/mini.iso tmp/iso
$ cp tmp/iso/initrd.gz tmp/
$ gunzip tmp/initrd.gz
$ cd tmp/initrd.d
$ cpio -i --make-directories < ../initrd
$ vim preseed.cfg
```

The preseed file should look something like the following. Everything that is not adding our kernel or removing the 2.6 kernel is from a standard preseed most installers use, and can be customized as much as you like. In the form below, it closely resembles a regular alternate install.

```bash
# Suggest LVM by default.
d-i partman-auto/init_automatically_partition string some_device_lvm
d-i partman-auto/init_automatically_partition seen false
# Always install the server kernel.
d-i base-installer/kernel/override-image string linux-server
# Only install basic language packs. Let tasksel ask about tasks.
d-i pkgsel/language-pack-patterns string
# No language support packages.
d-i pkgsel/install-language-support boolean false
# Only ask the UTC question if there are other operating systems installed.
d-i clock-setup/utc-auto boolean true
# No boot splash screen.
d-i debian-installer/splash boolean false
# Install the debconf oem-config frontend (if in OEM mode).
d-i oem-config-udeb/frontend string debconf
# Add the network and tasks oem-config steps by default.
oem-config oem-config/steps multiselect language, timezone, keyboard, user, network, tasks
# Remove 2.6 kernel 
d-i preseed/late_command string \
in-target apt-get install -y linux-image-server-lts-backport-oneiric && in-target apt-get remove -y $(echo `expr match "$(in-target dpkg --get-selections | grep linux-image-2.6)" '\(linux-image-2\.6\...-..-server\)'`)
```

Lastly, we need to package up our initrd and rebuild the iso so we can use it!

```bash
$ find ./ | cpio -H newc -o > ../initrd.gz
$ cd ..
# We mounted the iso read only, so make a copy to add the new initrd.gz to
$ mkdir new_iso
$ cp -r iso/ new_iso/
$ cp initrd.gz  new_iso/
$ mkisofs -o dest/netboot/10.04_custom_kernel.iso -r -J -no-emul-boot -boot-load-size 4 -boot-info-table -b isolinux.bin -c isolinux.cat tmp/new_iso/
``` 

And we're done! `dest/netboot/10.04_custom_kernel.iso` contains your new iso that runs off, and installs, a 3.0 kernel.

## Conclusion

Building our own installer provides several advantages over the old method of doing it all manually:

* There is no manual intervention during the install, either for loading drivers or installing the kernel
* Installs therefore go much faster
* The installer runs on the same kernel it installs, which helps minimize or identify potential bugs
* We can choose what kernel we want, and if we needed to, could build our own custom kernel image as well.

You can find an iso built with the exact steps above [here](https://86fbf08e343b5d5dc177-be6096dd7b17231f28632d8c229287b5.ssl.cf2.rackcdn.com/rax_mini_10.04.iso).

The instructions were based on [Debian documentation](https://wiki.debian.org/DebianInstaller/Modify/CustomKernel), modified slightly for use on Ubuntu. If you need to run on your own custom kernel image (we used kernel images in the Ubuntu repo) then those instructions are likely to be more helpful.

## Notes on choice of netboot image

The mini netboot image was chosen to be built because of the following reasons:

* It is small, <30 MB.
* Datacenters almost always have better networking than developers do.
* It is easily changeable on the fly.

However, the primary con is that all installs will have to download all of the packages they are installing. We decided we were okay with our installs taking a bit longer. If you are not okay, the debian-installer will build many other packages. You can take a look at the list by running `make list`. If you are building a 10.04 image, you need to choose one of the `build_$type` choices, the `build_$codename_type` choices will build an installer for that codename (10.10 for maverick, 11.04 for natty, 11.10 for oneiric).
