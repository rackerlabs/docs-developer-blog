---
layout: post
title: "A First Look at RBAC in the Liberty Release of Neutron"
date: 2015-12-03 08:00:00
comments: true
author: James Denton
published: true
categories:
    - neutron
    - rpc
    - openstack
---

Over the last couple of years, we've seen OpenStack deployments shift from a public cloud model, where no one is trusted, to a private cloud model, where collaboration and shared resources between projects is required. As enterprises adopt OpenStack and integrate it into their infrastructure, new use cases continue to multiply, and existing limitations in APIs and data models have been brought to the forefront. One of the more exciting features to come out of Neutron development in the Liberty cycle that addresses a shortcoming is a framework for Role Based Access Control (RBAC). 

<!-- more -->

RBAC aims to solve the inability to share certain Neutron resources with a subset of projects or tenants. Neutron has supported shared resources in the past, but until now, it's been all-or-nothing. If a network or other resource is marked as `shared`, it is shared with *all* tenants with no ability to specify otherwise. RBAC policies allow administrators and users to share resources with one or more tenants using a granular, rather than a shotgun, approach.

# Introducing the commands

Within the Neutron client, there are some new commands for managing RBAC policies:
 
```
rbac-create
rbac-delete
rbac-list
rbac-show
rbac-update
```

The workflow for managing RBAC policies follows the standard CRUD (Create, Read, Update, Delete) model that we're all used to with other Neutron resources. As it stands right now, users are limited to creating policies that allow for networks to be shared amongst a subset of tenants rather than the all-or-none approach taken in previous releases. Don't worry though, the Neutron team has developed the API and data model so that access control can be extended to other resources relatively easily in the future.  

# Satisfying some prerequisites

Before you can create an RBAC policy, you need to have a network that you want to share among tenants or projects. Let's start with creating a few projects so we can demonstrate this policy in action.

## Creating projects and users

In this example, let's create three projects using the OpenStack client:

```
racker@controller01:~$ openstack project create --description "Tenant A" TenantA
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Tenant A                         |
| domain_id   | default                          |
| enabled     | True                             |
| id          | fccad6ad6d0343f7ba7c5a84c01304a4 |
| is_domain   | False                            |
| name        | TenantA                          |
| parent_id   | None                             |
+-------------+----------------------------------+
racker@controller01:~$ openstack project create --description "Tenant B" TenantB
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Tenant B                         |
| domain_id   | default                          |
| enabled     | True                             |
| id          | 861a353bcb1f419e93dc1506e92859d2 |
| is_domain   | False                            |
| name        | TenantB                          |
| parent_id   | None                             |
+-------------+----------------------------------+
racker@controller01:~$ openstack project create --description "Tenant C" TenantC
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Tenant C                         |
| domain_id   | default                          |
| enabled     | True                             |
| id          | 9b466d5121704360891428d0c2edf11e |
| is_domain   | False                            |
| name        | TenantC                          |
| parent_id   | None                             |
+-------------+----------------------------------+
```

A project isn't really useful without users, so let's create a user in each project and assign them to a new role:

```
racker@controller01:~$ openstack role create demo
+-------+----------------------------------+
| Field | Value                            |
+-------+----------------------------------+
| id    | c986181da1504607ba0e9e997b616a23 |
| name  | demo                             |
+-------+----------------------------------+

racker@controller01:~$ openstack user create UserA --password secrete
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | default                          |
| enabled   | True                             |
| id        | dda2414d5471414db8226fda3f80779e |
| name      | UserA                            |
+-----------+----------------------------------+
racker@controller01:~$ openstack role add --project TenantA --user UserA demo
racker@controller01:~$ openstack user create UserB --password secrete
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | default                          |
| enabled   | True                             |
| id        | 4469a7746d8a4f65b874e141250a7f6d |
| name      | UserB                            |
+-----------+----------------------------------+
racker@controller01:~$ openstack role add --project TenantB --user UserB demo
racker@controller01:~$
racker@controller01:~$ openstack user create UserC --password secrete
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | default                          |
| enabled   | True                             |
| id        | c63665269e2a40ecbe700ece5f38a574 |
| name      | UserC                            |
+-----------+----------------------------------+
racker@controller01:~$ openstack role add --project TenantC --user UserC demo
```

## Creating a network

In this example, I will create a network and corresponding subnet as the `admin` user:

```
racker@controller01:~$ neutron net-create MySemiSharedNetwork
Created a new network:
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| id                        | c4471d6a-ab58-4ea3-971d-39104a5ad509 |
| mtu                       | 0                                    |
| name                      | MySemiSharedNetwork                  |
| provider:network_type     | vxlan                                |
| provider:physical_network |                                      |
| provider:segmentation_id  | 81                                   |
| router:external           | False                                |
| shared                    | False                                |
| status                    | ACTIVE                               |
| subnets                   |                                      |
| tenant_id                 | 8b19e1abc7424157af5f65bb5bb3f421     |
+---------------------------+--------------------------------------+
racker@controller01:~$ neutron subnet-create MySemiSharedNetwork 192.168.99.0/24
Created a new subnet:
+-------------------+----------------------------------------------------+
| Field             | Value                                              |
+-------------------+----------------------------------------------------+
| allocation_pools  | {"start": "192.168.99.2", "end": "192.168.99.254"} |
| cidr              | 192.168.99.0/24                                    |
| dns_nameservers   |                                                    |
| enable_dhcp       | True                                               |
| gateway_ip        | 192.168.99.1                                       |
| host_routes       |                                                    |
| id                | cdbf0f5a-3fec-416c-b2e3-060f8103604f               |
| ip_version        | 4                                                  |
| ipv6_address_mode |                                                    |
| ipv6_ra_mode      |                                                    |
| name              |                                                    |
| network_id        | c4471d6a-ab58-4ea3-971d-39104a5ad509               |
| subnetpool_id     |                                                    |
| tenant_id         | 8b19e1abc7424157af5f65bb5bb3f421                   |
+-------------------+----------------------------------------------------+
```

Notice that the `shared` attribute is set to `false`. In this state, the network can only be used by users in the `admin` project the network was created in. Setting it to `true` would make the network useable by *all* projects, which is something we'd like to avoid.

# Creating a policy

Now that we have the hard stuff out of the way, let's get down to business. 

Creating an RBAC policy requires four pieces of information:

- Policy type
- Target tenant
- Action to perform
- Resource ID

Let's take a look at the command to create the policy:

```
usage: rbac-create [-h] [-f {html,json,shell,table,value,yaml}] [-c COLUMN]
                   [--max-width <integer>] [--prefix PREFIX]
                   [--request-format {json,xml}] [--tenant-id TENANT_ID]
                   --type {network} [--target-tenant TARGET_TENANT] --action
                   {access_as_external,access_as_shared}
                   RBAC_OBJECT
```


At this time, the only type of policy that can be created is a network policy, and the only action is to share the network with the specified target tenant. The `RBAC_OBJECT` key word represents the ID of the network we want to share. Although the Neutron client hints towards the ability to limit external networks to a subset of tenants, that feature has not yet been implemented. In the future, policies may be created for different networking resources and shouldn't be limited just to networks.

In this example, the following command creates an RBAC policy that extends the network `MySemiSharedNetwork` to TenantA:

```
racker@controller01:~$ neutron rbac-create --type network --target-tenant fccad6ad6d0343f7ba7c5a84c01304a4 \
--action access_as_shared c4471d6a-ab58-4ea3-971d-39104a5ad509 

Created a new rbac_policy:
+---------------+--------------------------------------+
| Field         | Value                                |
+---------------+--------------------------------------+
| action        | access_as_shared                     |
| id            | 5d6a25ae-2491-4198-8a32-b73c3889f93b |
| object_id     | c4471d6a-ab58-4ea3-971d-39104a5ad509 |
| object_type   | network                              |
| target_tenant | fccad6ad6d0343f7ba7c5a84c01304a4     |
| tenant_id     | 8b19e1abc7424157af5f65bb5bb3f421     |
+---------------+--------------------------------------+

```
A `neutron rbac-list` shows the policy in all its glory:

```
racker@controller01:~$ neutron rbac-list
+--------------------------------------+--------------------------------------+
| id                                   | object_id                            |
+--------------------------------------+--------------------------------------+
| 5d6a25ae-2491-4198-8a32-b73c3889f93b | c4471d6a-ab58-4ea3-971d-39104a5ad509 |
+--------------------------------------+--------------------------------------+
```

As UserA in TenantA, you can see the network returned in a `neutron net-list`:

```
racker@controller01:~$ neutron --os-project-name TenantA --os-username UserA --os-password secrete net-list
+--------------------------------------+---------------------+------------------------------------------------------+
| id                                   | name                | subnets                                              |
+--------------------------------------+---------------------+------------------------------------------------------+
| c4471d6a-ab58-4ea3-971d-39104a5ad509 | MySemiSharedNetwork | cdbf0f5a-3fec-416c-b2e3-060f8103604f 192.168.99.0/24 |
+--------------------------------------+---------------------+------------------------------------------------------+
```

Users B and C, however, return no available networks:

```
racker@controller01:~$ neutron --os-project-name TenantB --os-username UserB --os-password secrete net-list
racker@controller01:~$ neutron --os-project-name TenantC --os-username UserC --os-password secrete net-list

(No networks returned)
```

Now, let's create an additional policy that extends the network `MySemiSharedNetwork` to TenantB:

```
racker@controller01:~$ neutron rbac-create --type network --target-tenant 861a353bcb1f419e93dc1506e92859d2 \
--action access_as_shared c4471d6a-ab58-4ea3-971d-39104a5ad509 

Created a new rbac_policy:
+---------------+--------------------------------------+
| Field         | Value                                |
+---------------+--------------------------------------+
| action        | access_as_shared                     |
| id            | c6882687-6946-46b0-9bd8-591e8f34997b |
| object_id     | c4471d6a-ab58-4ea3-971d-39104a5ad509 |
| object_type   | network                              |
| target_tenant | 861a353bcb1f419e93dc1506e92859d2     |
| tenant_id     | 8b19e1abc7424157af5f65bb5bb3f421     |
+---------------+--------------------------------------+
```

As a user in TenantA or TenantB, the network is returned in the results of `neutron net-list`. TenantC, however, is still left out:

```
racker@controller01:~$ neutron --os-project-name TenantA --os-username UserA --os-password secrete net-list
+--------------------------------------+---------------------+------------------------------------------------------+
| id                                   | name                | subnets                                              |
+--------------------------------------+---------------------+------------------------------------------------------+
| c4471d6a-ab58-4ea3-971d-39104a5ad509 | MySemiSharedNetwork | cdbf0f5a-3fec-416c-b2e3-060f8103604f 192.168.99.0/24 |
+--------------------------------------+---------------------+------------------------------------------------------+
racker@controller01:~$ neutron --os-project-name TenantB --os-username UserB --os-password secrete net-list
+--------------------------------------+---------------------+------------------------------------------------------+
| id                                   | name                | subnets                                              |
+--------------------------------------+---------------------+------------------------------------------------------+
| c4471d6a-ab58-4ea3-971d-39104a5ad509 | MySemiSharedNetwork | cdbf0f5a-3fec-416c-b2e3-060f8103604f 192.168.99.0/24 |
+--------------------------------------+---------------------+------------------------------------------------------+
racker@controller01:~$ neutron --os-project-name TenantC --os-username UserC --os-password secrete net-list

(No networks returned)
```

# Attaching instances to the shared network

A `neutron net-list` is nice and all as verification of our policy in effect, but let's see how we've managed to totally box out TenantC by creating instances as TenantA and TenantB using the new semi-shared network.

With the following `nova boot` commands we can create instances as UserA and UserB in their respective projects using the shared network:

```
racker@controller01:~$  nova --os-project-name TenantA --os-user-name UserA --os-password secrete boot --flavor m1.tiny --image "cirros-0.3.4-x86_64" --nic net-id=c4471d6a-ab58-4ea3-971d-39104a5ad509 Tenant-A-Test

...

racker@controller01:~$  nova --os-project-name TenantB --os-user-name UserB --os-password secrete boot --flavor m1.tiny --image "cirros-0.3.4-x86_64" --nic net-id=c4471d6a-ab58-4ea3-971d-39104a5ad509 Tenant-B-Test

...

racker@controller01:~$  nova list --all-ten
+--------------------------------------+--------------------+----------------------------------+---------+------------+-------------+----------------------------------+
| ID                                   | Name               | Tenant ID                        | Status  | Task State | Power State | Networks                         |
+--------------------------------------+--------------------+----------------------------------+---------+------------+-------------+----------------------------------+
| 1463375b-272a-4ed1-8fe4-694f64646c5a | Tenant-A-Test      | fccad6ad6d0343f7ba7c5a84c01304a4 | ACTIVE  | -          | Running     | MySemiSharedNetwork=192.168.99.5 |
| 7ae46da3-b0b8-445b-8c2e-ef545a901f00 | Tenant-B-Test      | 861a353bcb1f419e93dc1506e92859d2 | ACTIVE  | -          | Running     | MySemiSharedNetwork=192.168.99.7 |
+--------------------------------------+--------------------+----------------------------------+---------+------------+-------------+----------------------------------+
```

UserC, as expected, is not invited to this party and is unable to boot an instance in the network:

```
racker@controller01:~$  nova --os-project-name TenantC --os-user-name UserC --os-password secrete boot --flavor m1.tiny --image "cirros-0.3.4-x86_64" --nic net-id=c4471d6a-ab58-4ea3-971d-39104a5ad509 Tenant-C-Test

ERROR (BadRequest): Network c4471d6a-ab58-4ea3-971d-39104a5ad509 could not be found. (HTTP 400) (Request-ID: req-ce3fbce5-afec-41e1-8004-a8abddfad5eb)
```

# Caveats, warranties, etc.

Neutron's RBAC functionality is undergoing active development, and you're likely to see ~~regressions~~ improvements already in the `MASTER` branch and upcoming Mitaka release. What I've demonstrated here is functionality that a lot of enterprises are asking for, and hopefully just a glimpse of what should be possible once the feature matures. 

If you'd like to learn more about Neutron's RBAC functionality, take a look at the specs and blueprints found on [specs.openstack.org](https://specs.openstack.org/openstack/neutron-specs/specs/liberty/rbac-networks.html). As always, feel free to reach out to me on Twitter @jimmdenton with any questions!


