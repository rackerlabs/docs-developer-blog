---
comments: true
date: 2012-10-09T08:00:51.000Z
layout: post
title: 'OpenStack for Windows Users: Installing Linux'
author: Duan van der Westhuizen
categories:
  - OpenStack
---

_This is a guest post by Duan van der Westhuizen. Duan works at Rackspace in Enterprise Product Development and has been a Racker for almost 6 years. Duan started in our EMEA office where he also had roles in Business Intelligence and Customer Support. He has over 15 years of technology experience across various fields from technology strategy, engineering, development and database design. Duan is a tech at heart who is passionate about leading edge technologies and finding ways to solve market problems through new and innovative solutions._

In this second post of my blog series about learning to deploy my own OpenStack private cloud, I tackle the installation of the operating system I will use to run OpenStack. I had to do quite a bit of groundwork to understand the basic installation and configurations to ensure I ended up with a running system. Below I document my steps, as well as outline the similarities with Windows Server and other Microsoft technologies.

<!-- more -->

## Step 1: Find a server


I struggled to find and provision a physical server that I could use until I realized I could just run this from within a Virtual Machine on my laptop. This epiphany saved me tons of time, effort and cost. Luckily, to run an OpenStack cloud for testing purposes you don’t need a physical machine. You can use tools like VirtualBox to run the Linux OS that will be used to run the OpenStack cloud.

I downloaded and installed [VirtualBox](https://www.virtualbox.org/) to host my VM.


## Step 2 - Install Linux


I decided to install OpenStack from scratch, not using the [Rackspace Private Cloud Software](https://www.rackspace.com/cloud/private/) deployment tools that automate the installation of the Server, Hypervisor and OpenStack. I wanted to really understand the inner workings myself.

After asking some of our Rackspace technical talent I decided to go with a Linux distribution called Ubuntu 12.04 LTS (Precise Pangolin). Ubuntu also documents the [Ubuntu Cloud Infrastructure](https://help.ubuntu.com/community/UbuntuCloudInfrastructure) built on OpenStack on its wiki.  Some other distributions you could use include Suse, Debian and Fedora.

I downloaded Ubuntu Server from [here](https://www.ubuntu.com/download/server), and picked the 64-Bit version. I now had the ISO image for my VM downloaded locally to my laptop.

I created a VM in VirtualBox and assigned the VM 4 GB of RAM and gave it 8 GB of Disk space. After powering on the VM in VirtualBox for the first time it asked me for the media to install the server from. I just pointed it to the ISO image I downloaded and continued the installation.

There are various steps you have to go through when installing Ubuntu. The screenshot below shows these steps:


{% img center 2012-10-09-openstack-for-windows-users-installing-linux/ubuntu_installer.jpg %}


Most of the install options were fairly familiar. Some things that were foreign to me include:

_Users and Passwords:_ Linux uses a user called ”root.” This is the user with full admin access to the server.

This basically mirrors the ”Administrator” user for Windows. You need to create a separate user that you can use for day-to-day tasks as part of normal security best practice.

_Home Directory:_ It prompts if you want to encrypt your home directory. Linux has a very different directory (folder) structure than Windows. One of these directories is called “/home” (note the forward slash instead of the back slash, which is the way Linux directories are named). The home directory is where a user can store their personal files, and also encrypt them if needed to ensure they remain secure. Every user on the server gets a separate directory under “/home.” In my case it is “/home/duanvdw.” I left off encryption.

_Disk Partitioning: _Linux partitions your drive into various partitions. I used a guided partitioning option using LVM.

What is LVM, you may ask? Well, it stands for Logical Volume Manager. This is the tool that manages logical storage volumes across the physical disks you use in your server. For example, you could have three physical hard drives, create one Logical Volume Group across those three drives and then create additional logical volumes within that Volume group. You cannot have a logical volume that is larger than the sum of your physical drives (for obvious reasons). A quick diagram below shows what this looks like:

<table border="1" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td valign="top" width="108">Volumes</td>
<td colspan="2" valign="top" width="167"> (160 GB)</td>
<td valign="top" width="56">(40 GB)</td>
<td valign="top" width="112">(120 GB)</td>
</tr>
<tr>
<td valign="top" width="108">Volume Groups</td>
<td colspan="4" valign="top" width="335">
<p align="center">Fileserver</p>
</td>
</tr>
<tr>
<td valign="top" width="108">Physical Disks</td>
<td valign="top" width="112">
<p align="center">80 GB HDD</p>
</td>
<td colspan="3" valign="top" width="223">
<p align="center">240 GB HDD</p>
</td>
</tr>
</tbody>
</table>

On Windows this would be the equivalent of Dynamic disks that span multiple physical disks, which can be managed with the Windows Logical Disk Manager (LDM). On Windows each logical volume would have its own drive letter assigned e.g. C: Drive or D: Drive

The partitioning guide recommended the following partitioning scheme, which I accepted:

<table border="1" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td valign="top" width="122">LV root as <strong>ext4</strong></td>
<td valign="top" width="320">ext4 means that it formatted that volume with a journaling file system. This is a file system that tracks all changes in a journal before committing them to the main file system.</td>
</tr>
<tr>
<td valign="top" width="122">LV swap_1 as <strong>swap</strong></td>
<td valign="top" width="320">This is the swap partition. When the Linux server runs out of physical memory it can commit some of the files inmemory to the disk, using the swap partition.</td>
</tr>
<tr>
<td valign="top" width="122">Partition #1 as <strong>ext2</strong></td>
<td valign="top" width="320">ext2 is the standard Linux file system that stores your files in various directories.</td>
</tr>
</tbody>
</table>

ext2 and ext4 are file systems, similar to the native Windows FAT and NTFS file systems. The swap partition is similar to configuring your swap file on Windows.


#### Installing Additional Software Collections


Up to this point I only installed the core Ubuntu server. The following screen allowed me to select additional packages to install. I selected OpenSSH, Lamp Server and Virtual Machine Host.

{% img center 2012-10-09-openstack-for-windows-users-installing-linux/software_selection.jpg %}

**OpenSSH**: This component runs on the server and listens for connections over the SSH protocol. With this component running you can remotely control your server as well as transfer files to the server. Similar to Terminal Server on Windows, which is needed to accept Remote Desktop Connections.

**LAMP Server**: LAMP is an acronym for Linux, Apache, MySQL, PHP. This open source bundle contains the following functions:

_Apache_ – An open source web server similar to IIS on Windows
_MySQL_ – An open source relational database server similar to Microsoft SQL Server
_PHP_ – A programming language similar to Microsoft’s VB or C#

**Virtual Machine Host**: Selecting this option installs the KVM Hypervisor. This component allows you to run virtual servers within your Linux server, similar to running Windows Hyper-V or VMware ESX. This component is essential for running OpenStack.

GRUB Boot Loader: This component allows you to run multiple operating systems from a single server, allowing you to choose which one you’d like to boot from at startup. It provides a selection menu detailing different options for every operating system currently installed on your server when you power on your server.

The GRUB boot loader reminds me of the BOOT.INI file in Windows. Within this file you could specify a list of operating systems on your computer. This would then show a boot menu at startup, similar to GRUB.


## Step 3 – Connect to my server


This was a trickier than expected. There’s no Windows GUI anymore, so I couldn’t just fire up Remote Desktop to connect to my server. I decided to just use the actual terminal on the Ubuntu server running on the VM in VirtualBox. This is basically the same as using Command Prompt on your Windows server. If you needed to connect to the server remotely instead you could use free applications like Putty that allow you to connect to your Linux server through SSH.

I now had this screen in front of me:

{% img center 2012-10-09-openstack-for-windows-users-installing-linux/login.jpg %}

Next steps: figure out how to login, and then download and install OpenStack. No doubt there will be many more lessons to learn as I continue this project. Thanks for reading!
