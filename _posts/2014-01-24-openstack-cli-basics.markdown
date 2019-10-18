---
layout: post
title: Openstack CLI Basics
date: '2014-01-24 12:00'
comments: true
author: Jonathan Kelly
published: true
categories:
  - OpenStack
---


In this blog post, we will walk through using the OpenStack CLI tools to
perform common workflows:

* Setting environment variable to use CLI tools without repeatedly specifying
username/password/tenant.
* Using the built-in CLI help
* Creating and using an SSH key-pair
* Creating and modifying Glance images
* Creating Nova flavors
* Booting and deleting images
* Creating a tenant
* Creating users for a tenant and adding roles to them
* Testing authentication using curl

<!-- more -->

# Environment Variables

The OpenStack CLI tools need quite a bit of data to function properly.  In
order to avoid repeatedly entering usernames/passwords/etc. we will set some
environment variables.  A good approach is to put them all in a file and source
that file in your bashrc.  It should look something like this:

    # COMMON OPENSTACK ENVS
    export OS_USERNAME=admin
    export OS_PASSWORD=secrete
    export OS_TENANT_NAME=admin
    export OS_AUTH_URL=https://162.242.171.36:5000/v2.0
    export OS_AUTH_STRATEGY=keystone export OS_NO_CACHE=1

    # LEGACY NOVA ENVS
    export NOVA_USERNAME=${OS_USERNAME}
    export NOVA_PROJECT_ID=${OS_TENANT_NAME}
    export NOVA_PASSWORD=${OS_PASSWORD}
    export NOVA_API_KEY=${OS_PASSWORD}
    export NOVA_URL=${OS_AUTH_URL}
    export NOVA_VERSION=1.1
    export NOVA_REGION_NAME=RegionOne

Once those are set, you should be able to run Openstack CLI commands without
supplying any extraneous data.

# Command Help, Syntax, etc.

The Openstack CLI tools have a reasonably decent built-in help system.  By
typing e.g. _nova help_ you will get a list of all possible subcommands and
optional arguments. You can get additional help on a specific subcommand with
_nova help (subcommand)_  e.g. _nova help boot_.

Note that many commands take positional arguments: in other words, the order
of the arguments is significant.  This gives you a good base to learn more
about these tools, but the number of subcommands and positional arguments can
be a bit daunting, so I'll provide some concrete examples so you can see
exactly what operating an OpenStack environment from the CLI looks like.

# Creating a Keypair

You can create a keypair using _nova keypair-add_.  You can create a
new keypair, in which case the private key will be output (you need to save
this somewhere... if you lose it, you won't be able to log in to instances
using this keypair).  You can also specify an existing public key.

Keypairs can be utilized by passing the _key-name_ flag to _nova boot_.  This
will be discussed further below.

# Creating a Glance Image

First, let's download an image.  We'll use Ubuntu 12.04 for this example.

    wget https://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img

First, we'll look at existing images with _glance image-list_.

Next, we will use the Glance client to upload this image
(Glance can use either local disk or Swift as its storage back-end), and make
it usable by Nova.

    glance image-create --name nubuntu --is-public True --disk-format qcow2 \
    --container-format bare <precise-server-cloudimg-amd64-disk1.img

If this worked, you should see some output showing the details of the newly
created image!

Let's rerun _glance image-list_ and verify we see our new image.

# Creating a Nova Flavor

Now let's create a smaller flavor for our new image! Using
_nova help flavor-create_ we can see that creating a flavor requires 5
positional arguments: NAME [ID|auto] RAM_MB DISK_GB VCPUs

With that in mind, let's run:

    nova flavor-create "384MB Tiny Instance" 2 384 5 1

You should see output containing the details for the new flavor.

# Booting an Image

Let's take a look and see what instances are currently running:

    nova list

Let's boot an ubuntu image using the admin keypair:

    nova boot ubuntutest --flavor 2 --image cirros --key-name adminKey

And take a look at our new instance:

    nova list
    nova show ubuntutest

We can also see the console log of the instance using:

    nova console-log ubuntutest

We should also be able to ssh in to the listed IP using our admin key.

# Creating a Modified Image

Our next task is to create a modified cirros image.  First, we need to mount
the image so that we can fiddle with it:

    qemu-nbd --connect=/dev/nbd0 ~/precise-server-cloudimg-amd64-disk1.img

Now we have the image connected as a block device, so let's look at the
partition table and find the root partition:

    fdisk /dev/nbd0 -l

That was easy! Let's mount the partition:

    mkdir -p /mnt/image && mount /dev/nbd0p1 /mnt/image

Let's create an MOTD file on this image:

    echo 'echo "**** HELLO CLOUD ****"' >> /mnt/image/etc/update-motd.d/00-header

Now let's unmount and disconnect the image:

    umount /mnt/image
    qemu-nbd --disconnect /dev/nbd0

And create a new image:

    glance image-create --name ubuntu_motd --is-public True --disk-format qcow2 --container-format bare <precise-server-cloudimg-amd64-disk1.img

And boot a new instance from our new image.  This time let's pass _--poll_ so we
can track build progress:

    nova boot ubuntu_motd --flavor 2 --image ubuntu_motd --key-name adminKey --poll ubuntu_motdtest

When we SSH in, we will see our MOTD modification has worked!

# SSHing into an instance

Without going into the nitty gritty of Neutron networking and network namespaces,
let's test our changes.  First we need to get the network namespace:

    ip netns

Now we can ssh in on that namespace with:

    ip netns exec (namespace) ssh ubuntu@host

# Deleting an Instance

Let's go ahead and deleting our cirros_motd instance:

    nova delete ubuntu_motd
    nova list

# Creating a Tenant

Now let's create a new tenant:

    keystone tenant-list
    keystone tenant-create --name dev
    keystone tenant-list

That was easy!

## Creating a New User

Next, let's create some users for our new tenant.

First, let's take a look at all of the existing users on all tenants

    keystone user-list

Now we can look at tenant-specific users

    keystone user-list --tenant admin
    keystone user-list --tenant dev

Ok, now let's create two users for our 'dev' tenant:

    keystone user-create --name devadmin --pass adminpass --tenant dev
    keystone user-create --name dev --pass devpass --tenant dev

So what makes an admin user an admin? The admin role! If we look at the two
users, you'll see they are both currently just members of the dev tenant:

    keystone user-role-list --user dev --tenant dev
    keystone user-role-list --user devadmin --tenant dev

Let's add the admin role to devadmin within the dev tenant:

    keystone user-role-add --user devadmin --tenant dev --role admin
    keystone user-role-list --user devadmin --tenant dev

We now have a new tenant with working admin and non-admin users!

## Testing Authentication

To test authentication, you can either log in via Horizon, use any of the CLI
tools (setting the appropriate flags and/or environment variables for your
tenant, username, and password), or you can use curl as follows:

    curl -d '{"auth":{"passwordCredentials":{"username": "dev", "password": "devpass"}}}' -H "Content-type: application/json" https://localhost:35357/v2.0/tokens 2>/dev/null|python -mjson.tool

If authentication is successful, you should see some JSON data including auth
token information.

# Screencast!

And if you want to follow along with a fully featured video tutorial, you can
do so:

<iframe width="420" height="315" src="//www.youtube.com/embed/GXXKpY5d8UY" frameborder="0" allowfullscreen></iframe>

# FIN

We have now covered a variety of common Openstack workflows using CLI tools.

If you have any questions, comments, or feedback, please feel free to email me
at: jonathan.kelly@rackspace.com