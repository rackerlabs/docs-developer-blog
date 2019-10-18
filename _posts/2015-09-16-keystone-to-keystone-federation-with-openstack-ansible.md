---
layout: post
title: Keystone-to-Keystone federation with the openstack-ansible project
date: '2015-09-16 23:59'
comments: true
author: Miguel Grinberg
published: true
categories:
  - openstack
  - osad
---

Federation support in OpenStack has been greatly improved in the Kilo release,
and, while there are still some rough edges, the feature is now usable, if you
don't mind adding a little elbow grease. This article focuses on one specific
configuration called *Keystone-to-Keystone federation* (or K2K), in which users
of an OpenStack cloud use their credentials to access services in another
OpenStack cloud, with both clouds using Keystone as their identity services.

<!-- more -->

The purpose of this article is twofold. First, I want to show you how to
configure K2K federation between two [openstack-ansible](https://github.com/openstack/openstack-ansible) clouds.
Then, I want to touch on some of those rough edges I mentioned above, so that
you have your expectations set at the right level.

### What is OpenStack federation?

In a standard, non-federated set up, users authenticate against the cloud's
own identity APIs, usually implemented by the Keystone service. With Keystone
federation, the options for authentication are expanded by creating a
separation between the entity that authenticates the user (the *identity
provider*, or IdP) and the entity that owns the cloud resources the user
wants to access (the *service provider*, or SP).

Since we are talking about OpenStack, it is obvious that the service provider
in all the federation use cases is an OpenStack cloud. But on the IdP side
things are more interesting, because it is now possible to use a variety of
external identity services, such as those based on ADFS, OpenID Connect or
SAML2. As a result, an external IdP service that has a trust
relationship with the SP cloud can offer access to resources in the SP cloud to
all of its users, without those users needing explicit SP cloud accounts.

### What is Keystone-to-Keystone federation?

When you have an OpenStack cloud acting as IdP to another OpenStack cloud, you
have K2K federation. In this situation, the Keystone service in the SP cloud
is configured to trust the Keystone service in the IdP cloud with user
authentication, so any users of the IdP cloud can access resources of the SP
cloud as if they had a local account.

There are many useful workflows that are made possible by K2K federation.
Consider a company that operates in multiple regions, each with its own
regional cloud. With K2K, the users in one region can automatically access the
clouds in the other regions when they need to. Another interesting application
is the creation of a hybrid private/public cloud. Imagine a company that has
an on-premise private cloud that can dynamically expand to a much larger public
cloud when its local resources are all in use.

### What is the openstack-ansible project?

The [openstack-ansible](https://github.com/openstack/openstack-ansible) project
is an open source initiative from Rackspace that provides
[Ansible](https://www.ansible.com/home) playbooks to deploy production-ready
OpenStack private clouds of any size, directly from the official OpenStack
repositories and without any vendor-specific additions. Note that this project
was originally hosted on stackforge with the name os-ansible-deployment.

One of the strong selling points of this project, and one that distinguishes it
from other OpenStack distributions, is that the OpenStack services are
installed in individual LXC containers, so they are isolated from each other.
Configuration options are given in [YAML](https://yaml.org/) files, which are
simple, hierarchical text files that can be edited in your favorite text
editor. The Ansible model simplifies the management of the OpenStack cluster,
so that for example, adding a new compute node to an existing cloud just
requires editing the configuration file that lists all the nodes, and then
re-running the playbooks. Each time you run the playbooks, Ansible detects what
changed in the configuration files, and invokes the appropriate tasks to
update the cluster accordingly with minimal or no disruption to the cluster.
If one of the services starts to misbehave, just delete its container and run
the Ansible playbooks to create a brand new container to take the
place of the bad one. It's that simple.

### Deploying an openstack-ansible all-in-one

Describing the openstack-ansible configuration in detail is outside the scope
of this article, but I want to quickly show you how you can do a single-node
install that is appropriate for testing and evaluation, in case you are
interested in actually playing with K2K federation instead of just reading
about it from me.

The openstack-ansible project is based on Ubuntu 14.04, so you need to install
this operating system to prepare a host for the deployment. I have found that
a host with 8GB of RAM and 60GGB of disk space is enough to host an all-in-one
installation. A very good option for a single-node deployment is to use a
public cloud server. If you have access to the Rackspace public cloud, a node
that uses the `performance1-8` flavor is a good choice.

The only package that you need to have installed in your host to be able to
launch an install is git:

    # apt-get install git

With it, you have to clone the kilo branch of the openstack-ansible repository:

    # git clone -b kilo https://github.com/openstack/openstack-ansible /opt/openstack-ansible

Luckily, the project includes scripts that simplify single-node deployments,
which we use for development work and gate checks. These scripts take care of
all the configuration and setup appropriate for an all-in-one, so all that you
need to do is run the following scripts:

    # cd /opt/openstack-ansible
    # scripts/bootstrap-aio.sh
    # scripts/bootstrap-ansible.sh
    # scripts/run-playbooks.sh

Now you can go grab a cup of coffee (or three), and let Ansible install
OpenStack for you. The process normally takes about 45 minutes to one hour to
complete.

Once the install finishes, your OpenStack cloud is ready to be used. Horizon is
accessible on the public IP address of your server. If you haven't changed the
default configuration, then the username is `admin` and the password is
randomly generated and different every time. The configuration files for the
installation can be found in the **/etc/openstack\_deploy** directory. To find
your admin password, you can run the following command:

    # grep keystone_auth_admin_password /etc/openstack_deploy/user_secrets.yml

Remember that I mentioned that the openstack services are deployed to LXC
containers? You can use the `lxc-ls` command to list the containers in your
installation:

    # lxc-ls -f
    NAME                                          STATE    IPV4                                       IPV6  AUTOSTART
    -------------------------------------------------------------------------------------------------------------------------------
    aio1_ceilometer_api_container-0156d950        RUNNING  10.0.3.129, 172.29.238.192                 -     YES (onboot, openstack)
    aio1_ceilometer_collector_container-bb0887dd  RUNNING  10.0.3.193, 172.29.239.105                 -     YES (onboot, openstack)
    aio1_cinder_api_container-6f4f639d            RUNNING  10.0.3.174, 172.29.236.216, 172.29.247.34  -     YES (onboot, openstack)
    aio1_cinder_scheduler_container-ec7a787a      RUNNING  10.0.3.108, 172.29.236.82                  -     YES (onboot, openstack)
    aio1_galera_container-752f369f                RUNNING  10.0.3.225, 172.29.237.252                 -     YES (onboot, openstack)
    aio1_galera_container-9d4079b5                RUNNING  10.0.3.114, 172.29.236.59                  -     YES (onboot, openstack)
    aio1_galera_container-f7aa239a                RUNNING  10.0.3.27, 172.29.238.87                   -     YES (onboot, openstack)
    aio1_glance_container-7da663ca                RUNNING  10.0.3.191, 172.29.236.99, 172.29.245.125  -     YES (onboot, openstack)
    aio1_heat_apis_container-6049fd20             RUNNING  10.0.3.39, 172.29.239.51                   -     YES (onboot, openstack)
    aio1_heat_engine_container-fbfba3d3           RUNNING  10.0.3.47, 172.29.239.196                  -     YES (onboot, openstack)
    aio1_horizon_container-9f338a14               RUNNING  10.0.3.96, 172.29.236.128                  -     YES (onboot, openstack)
    aio1_horizon_container-af801068               RUNNING  10.0.3.88, 172.29.238.132                  -     YES (onboot, openstack)
    aio1_keystone_container-67b7e278              RUNNING  10.0.3.82, 172.29.239.195                  -     YES (onboot, openstack)
    aio1_keystone_container-83926b44              RUNNING  10.0.3.24, 172.29.238.201                  -     YES (onboot, openstack)
    aio1_memcached_container-939aa985             RUNNING  10.0.3.34, 172.29.239.2                    -     YES (onboot, openstack)
    aio1_neutron_agents_container-41c766fa        RUNNING  10.0.3.112, 172.29.236.133, 172.29.240.93  -     YES (onboot, openstack)
    aio1_neutron_server_container-7f869c25        RUNNING  10.0.3.126, 172.29.237.173                 -     YES (onboot, openstack)
    aio1_nova_api_metadata_container-0f0c95ac     RUNNING  10.0.3.216, 172.29.236.202                 -     YES (onboot, openstack)
    aio1_nova_api_os_compute_container-10b4cc35   RUNNING  10.0.3.226, 172.29.238.198                 -     YES (onboot, openstack)
    aio1_nova_cert_container-dc9f80e1             RUNNING  10.0.3.209, 172.29.238.47                  -     YES (onboot, openstack)
    aio1_nova_conductor_container-3f4681b9        RUNNING  10.0.3.46, 172.29.238.202                  -     YES (onboot, openstack)
    aio1_nova_console_container-58618b58          RUNNING  10.0.3.246, 172.29.238.230                 -     YES (onboot, openstack)
    aio1_nova_scheduler_container-3d1b4e9d        RUNNING  10.0.3.224, 172.29.237.134                 -     YES (onboot, openstack)
    aio1_rabbit_mq_container-0f3542d2             RUNNING  10.0.3.181, 172.29.237.181                 -     YES (onboot, openstack)
    aio1_rabbit_mq_container-4dc00e4c             RUNNING  10.0.3.40, 172.29.237.51                   -     YES (onboot, openstack)
    aio1_rabbit_mq_container-cea24e2c             RUNNING  10.0.3.122, 172.29.239.7                   -     YES (onboot, openstack)
    aio1_repo_container-4cf3b996                  RUNNING  10.0.3.172, 172.29.236.175                 -     YES (onboot, openstack)
    aio1_repo_container-6511c33a                  RUNNING  10.0.3.60, 172.29.238.34                   -     YES (onboot, openstack)
    aio1_rsyslog_container-dbae4650               RUNNING  10.0.3.36, 172.29.236.207                  -     YES (onboot, openstack)
    aio1_swift_proxy_container-0f90e545           RUNNING  10.0.3.146, 172.29.238.15, 172.29.245.109  -     YES (onboot, openstack)
    aio1_utility_container-d7a0a0e0               RUNNING  10.0.3.125, 172.29.239.67                  -     YES (onboot, openstack)

The first interesting thing you may notice is that even though this is a
single-node deployment, the use of containers makes it possible to deploy
redundant services. You can see in the above listing that keystone, rabbitmq,
galera and a few others are deployed in multiple containers. The set up script
installs haproxy as a load balancer for these.

Among all the containers, you'll find one with the name `utility`, usually at
the bottom of the list. This container has all the OpenStack command
line clients installed, and is appropriate for accessing the cloud from the
command line. Below you can see an example session in which I use the
`openstack` command line utility to query the list of users:

    # ssh aio1_utility_container-d7a0a0e0
    Welcome to Ubuntu 14.04.3 LTS (GNU/Linux 3.13.0-58-generic x86_64)
    Last login: Wed Sep  2 21:31:34 2015 from 172.29.236.100
    root@aio1_utility_container-d7a0a0e0:~# source openrc
    root@aio1_utility_container-d7a0a0e0:~# openstack user list
    +----------------------------------+--------------------------------+
    | ID                               | Name                           |
    +----------------------------------+--------------------------------+
    | 0ce7c8c8d75c44c38e52fe4414482aff | cinder                         |
    | 12ca8c329fdd48f7a7fdc69ec8153962 | demo                           |
    | 28d0e28f46fd446195b9eaedbe1085aa | swift                          |
    | 346498bb40a741d48df728d6a5fd1eef | stack_domain_admin             |
    | 595b2db82173460a994d23b29967a207 | glance                         |
    | 5fa7bf9a79aa4782b5657bd23d95082c | heat                           |
    | 8eb91912e1e2466ab781b317c358c109 | neutron                        |
    | 925e531fdbf340bbbcd0825d9c6f94f1 | keystone                       |
    | af7ecc9999c44e6e8459ddc3810e128d | ceilometer                     |
    | c9c2e4e7fa264c10809121ffda2a9d14 | admin                          |
    | fedf070e403343d18fadb04dbc063048 | nova                           |
    +----------------------------------+--------------------------------+

In the following sections, I will describe how to connect two openstack-ansible
installations through K2K federation.

### K2K configuration for openstack-ansible

As an OpenStack deployer, one of the nicest aspects of the openstack-ansible
project is the ease of introducing configuration changes. In the Ansible model,
all the tasks that make up a deployment are idempotent, so that they can be
executed multiple times without causing problems. So effectively, every time
you run the playbooks, Ansible can easily apply changes given in the
configuration files, while all the things that did not change from the previous
run are unaffected.

Specifically for K2K federation, this means that connecting two existing
OpenStack clouds requires very little work, and a minimal disruption to the
Keystone services (a second or two that it takes to restart the services after
the configuration changes are applied).

If you are going to follow along and set up your own K2K federation test, then
at this point it would be a good idea that you deploy the two clouds that you
will use. You can follow the instructions from the previous section to stand up
two single-node clouds. Before you continue, verify that you can access both
clouds through their utility containers, as shown above.

#### Setting up the IdP cloud

To configure an openstack-ansible install as an identity provider for
federation, the IdP configuration must be added. A good place to write this
configuration is in the **/etc/openstack\_deploy/user\_variables.yml** file. Note
that any files in the **/etc/openstack\_deploy** directory that match the
**user\_*.yml** pattern are imported by the Ansible playbooks, so if you want, you
can also write it in a brand new file, as long as it matches the pattern.

The IdP configuration is shown below:

    keystone_idp_id: my_idp
    keystone_sp_id: my_sp
    keystone_sp_host: aa.bb.cc.dd

    keystone_idp:
      service_providers:
        - id: "{{ "{{ " }}keystone_sp_id{{ " }}" }}"
          auth_url: https://{{ "{{ " }}keystone_sp_host{{ " }}" }}:5000/v3/OS-FEDERATION/identity_providers/{{ "{{ " }}keystone_idp_id{{ " }}" }}/protocols/saml2/auth
          sp_url: https://{{ "{{ " }}keystone_sp_host{{ " }}" }}:5000/Shibboleth.sso/SAML2/ECP
      idp_entity_id: "{{ "{{ " }}keystone_service_publicurl_v3{{ " }}" }}/OS-FEDERATION/saml2/idp"
      idp_sso_endpoint: "{{ "{{ " }}keystone_service_publicurl_v3{{ " }}" }}/OS-FEDERATION/saml2/sso"
      idp_metadata_path: /etc/keystone/saml2_idp_metadata.xml
      certfile: "/etc/keystone/ssl/idp_signing_cert.pem"
      keyfile: "/etc/keystone/ssl/idp_signing_key.pem"
      self_signed_cert_subject: "/C=US/ST=Texas/L=San Antonio/O=IT/CN={{ "{{ " }}external_lb_vip_address{{ " }}" }}"
      regen_cert: false

    keystone_token_provider: "keystone.token.providers.uuid.Provider"
    keystone_token_driver: "keystone.token.persistence.backends.sql.Token"

You can see at the top of the above snippet that I have defined three top-level
variables. The first two hold user-defined unique identifiers for the IdP and
SP clouds. The third variable defines the public IP address or hostname of the
SP cloud. These are custom variables that I intend to use later. Since this is
an Ansible configuration file, these variables can be referenced in other
variables with the `{{ "{{ " }}variable_name{{ " }}" }}` syntax.

The block of variables that configure the cloud as an IdP is defined inside the
`keystone_idp` root element. The most important setting in this block is the
reference to the SP cloud, which is given in the `service_providers` variable.
For each service provider, three configuration items must be provided: the
provider's unique identifier, its `auth_url`, and its `sp_url`. Note how the
`id` is generated using the `keystone_sp_id` custom variable that I defined
above. For the other two variables Keystone has predefined URLs, so the only
thing that changes from one install to the next is the SP cloud's public IP
address or hostname, which again, I replace from one of my custom variables at
the top.

I should note that the `service_providers` variable contains a list, which
means that you can attach more than one service provider cloud. When using
multiple SPs, it is required that each SP cloud is configured with a unique
identifier.

The remaining variables under `keystone_idp` can normally be set identically in all installs. Among
these settings there are a few that configure the SSL certificate that is used
by the SAML2 protocol, which is automatically generated as part of the install.
Out of all these variables, the `regen_cert` variable deserves a mention. This
variable can be used to force Ansible to replace an existing certificate with
a new one, simply by setting the variable to `true`. If this variable is set
to `false`, then repeated runs of the playbook will leave the same certificate
installed.

The last two variables configure Keystone to use UUID tokens. At this time,
this is required in the Kilo branch. The openstack-ansible project configures
Keystone to use Fernet tokens by default, but there are currently issues with
this token provider and federation. Once the Fernet token fixes are backported
these two lines can be omitted.

Are you ready to convert one of your two test clouds to an identity provider?
Just add the above snippet to **/etc/openstack\_deploy/user\_variables.yml**, and
make sure you write the IP address or hostname of your other cloud in the
`keystone_sp_host` variable. To make this configuration change effective, you
just simply need to run the playbooks again. Since this change only affects
keystone, we will just run the keystone playbook to save a bit of time:

    # cd /opt/openstack-ansible/playbooks
    # openstack-ansible os-keystone-install.yml

Ansible will now run for a few minutes, and, when the playbook completes, your
first cloud will be configured as an identity provider. Pretty simple, right?

#### Setting up the SP cloud

The configuration of the service provider cloud is done similarly to that of
the identity provider. Below you can see the SP configuration block:

    keystone_idp_id: my_idp
    keystone_sp_id: my_sp
    keystone_idp_host: ee.ff.gg.hh

    keystone_sp:
      cert_duration_years: 5
      trusted_idp_list:
        - name: "{{ "{{ " }}keystone_idp_id{{ " }}" }}"
          entity_ids:
             - 'https://{{ "{{ " }}keystone_idp_host{{ " }}" }}:5000/v3/OS-FEDERATION/saml2/idp'
          metadata_uri: 'https://{{ "{{ " }}keystone_idp_host{{ " }}" }}:5000/v3/OS-FEDERATION/saml2/metadata'
          metadata_file: 'metadata-keystone-{{ "{{ " }}keystone_idp_id{{ " }}" }}.xml'
          metadata_reload: 1800
          federated_identities:
            - domain: Default
              project: fedproject
              group: fedgroup
              role: _member_
          protocols:
            - name: saml2
              attributes:
                - name: openstack_user
                  id: openstack_user
                - name: openstack_roles
                  id: openstack_roles
                - name: openstack_project
                  id: openstack_project
                - name: openstack_user_domain
                  id: openstack_user_domain
                - name: openstack_project_domain
                  id: openstack_project_domain
              mapping:
                name: "{{ "{{ " }}keystone_idp_id{{ " }}" }}-mapping"
                rules:
                  - remote:
                      - type: openstack_user
                    local:
                      - group:
                          name: fedgroup
                          domain:
                            name: Default
                        user:
                          name: federated_user

    keystone_token_provider: "keystone.token.providers.uuid.Provider"
    keystone_token_driver: "keystone.token.persistence.backends.sql.Token"

Here the `cert_duration_years` configures the duration of a self-signed SSL
certificate that will protect the endpoints used by the SAML2 protocol. The
`trusted_idp_list` variable is the SP counterpart of the `service_providers`
variable in the IdP configuration and defines the list of identity providers.

Like we did for SPs in the IdP side, here we have to provide a few settings for
each IdP. These include the IdP's unique identifier and its endpoints, plus
a location where metadata associated with the IdP is to be stored. These can be
set using custom variables.

The `federated_identities` defines sets of identities in the SP cloud that will
be used with remote users. These can include a domain, project, group, role,
or user. This is one part of the configuration that needs to be customized
according to the needs of each SP cloud. In the above example, remote users
will be put in the default domain, in a project called `fedproject`. The role
will be the standard `_member_` role, and users will be part of the `fedgroup`
group. Any entities declared here will be automatically created by the keystone
playbook.

The SP cloud needs to know how to map users of the IdP cloud as its own users,
and this is done in the `protocols` variable. At this time, K2K only supports
the `saml2` protocol, so that is going to be the only entry.

The `attributes` defined by a protocol are the bits of information that the IdP
shares with the SP when a user initiates an authentication request. Usually
these are tied to the type of identity provider, so for a K2K setup, the
attributes shown in the above example are the ones that will need to be
declared. As you can see, these are the basic attributes of a user, which the
SP can use to determine how to handle the user.

The protocol's `mapping` section defines how the users of the IdP are to be
mapped to local users and this is done through a list of rules. When the
Keystone service running on the SP cloud receives a remote authentication,
it will evaluate the `remote` portion of each rule until one matches the user.
The matching criteria can be pretty simple or can also be fairly complex,
involving one or more of the declared attributes. Once a matching rule has been
found, the user is mapped as a local user according to the `local` part of the
rule. In the example above, there is a single rule, which says that the remote
user must have a declared `openstack_user` value (the username). The user will
be mapped to the group `fedgroup` in the `Default` domain. I'm sure you noticed
that the user given in the local part of the rule isn't real. When remote
users are mapped, ephemeral users are created to represent them.

The rule definition language allows for rules much more complex than the one
shown above. For more information about federation mappings, you can consult the
[appropriate section of the Keystone documentation](https://docs.openstack.org/developer/keystone/mapping_combinations.html).

To configure your second cloud as a SP, add the above configuration to your
**/etc/openstack\_deploy/user\_variables.yml** file, and, like in the IdP case,
run the Keystone playbook:

    # cd /opt/openstack-ansible/playbooks
    # openstack-ansible os-keystone-install.yml

Finally, the SP configuration also needs UUID tokens to avoid issues with the
default Fernet tokens.

At this point, the K2K federation between your two clouds should be fully
configured and functional.

### The K2K federation authentication flow

If you followed the instructions above, you have one of your clouds configured
as an IdP, and the other configured as a SP. Not only that, the Keystone
playbook in openstack-ansible also set things up so that the IdP cloud knows
about the SP cloud, and the SP cloud knows about the IdP cloud.

So how does federation work? To begin, the user must authenticate against the
IdP cloud. This is the standard authentication, so, for command line usage, this
is usually achieved by importing an **openrc** file.

To initiate a federated request, the IdP cloud must contact the SP cloud and
provide information about the user. For this, the IdP generates an *assertion*,
which is an encrypted block of information about the user, and it sends it to
the SP. The SP cloud will decrypt the assertion, verify it, and perform the
mapping of the user. If the mapping is succesful, the SP cloud will return a
*token* that the user can use to access the SP cloud.

The whole authentication process involves a few back and forths between the IdP
and SP clouds. The openstack-ansible project provides a script that performs
all the needed actions and provides the token for the IdP user to access the SP
cloud as output.

To demonstrate how all this works, I'm going to copy this script to the utility
container of my IdP, and then run it from there. Starting from a terminal on
the IdP host, this is what you need to do:

    # cd /opt/openstack-ansible
    # scp scripts/federated-login.sh <utility-hostname>:~/
    # ssh <utility-hostname>
    # source openrc
    # ./federated-login.sh --project fedproject --domain Default my_sp
    Performing federated login...
    - Obtained IdP token.
    - Obtained SAML2 assertion from IdP.
    - Submitted SAML2 assertion to SP.
    - Obtained unscoped token from SP: 5236e3a6a185488a8fe7f84ff7edcdb4
    - Domains available at sp:
    - Projects  available at sp:
    "fedproject",
    - Obtained scoped token from SP for project fedproject in domain Default: 1f6606af8cda4b27b787819f2eb3f2d4
    - Full catalog available in file catalog.json
    #----------------------------------------
    # Available endpoints:
    OBJECT_STORE_URL=https://23.253.97.96:8080/v1/AUTH_cb60fc9c11df47f9b57b7dda4a34acd2
    METERING_URL=https://23.253.97.96:8777
    IMAGE_URL=https://23.253.97.96:9292
    VOLUME_URL=https://23.253.97.96:8776/v1/cb60fc9c11df47f9b57b7dda4a34acd2
    IDENTITY_URL=https://23.253.97.96:5000/v2.0
    NETWORK_URL=https://23.253.97.96:9696
    CLOUDFORMATION_URL=https://23.253.97.96:8000/v1
    ORCHESTRATION_URL=https://23.253.97.96:8004/v1/cb60fc9c11df47f9b57b7dda4a34acd2
    COMPUTEV21_URL=https://23.253.97.96:8774/v2.1
    COMPUTE_URL=https://23.253.97.96:8774/v2/cb60fc9c11df47f9b57b7dda4a34acd2
    VOLUMEV2_URL=https://23.253.97.96:8776/v2/cb60fc9c11df47f9b57b7dda4a34acd2
    #----------------------------------------
    # OpenStack client setup:
    export OS_TOKEN=1f6606af8cda4b27b787819f2eb3f2d4
    export OS_URL=<desired-service-endpoint>

The output of the **federated-login.sh** shows a progress of all the actions
taken during the authentication process and, once the authentication is
completed, displays the information that you need to access the SP cloud.

From the output of the script, the important bits are the scoped token and
the URLs for all the services. The token is going to be used with all the
services, so it is best to put it in an environment variable that the openstack
command line client automatically picks up, as suggested by the script:

    # export OS_TOKEN=<scoped-token>

Then, for example, if you wanted to obtain a listing of all the images available
to you in the SP cloud, you would use the image service endpoint as follows:

    # openstack --os-endpoint=https://23.253.97.96:9292 image list

To get a list of instances, the compute endpoint is used in a similar way:

    # openstack --os-endpoint=https://23.253.97.96:8774/v2/cb60fc9c11df47f9b57b7dda4a34acd2 server list

You are probably thinking that it is inconvenient to have to provide the
service endpoint for each command, given that when accessing the local cloud
the openstack command line client can figure that out on its own from the
service catalog. I will discuss this and other problems with the current state
of K2K federation in the next section.

### Current limitations of K2K

Now that you've seen, and maybe even experienced, K2K federation, I'm sure you
are scratching your head and wondering why things aren't more streamlined. In
this section, I have compiled a short list of problems you may run into when
using K2K federation with the Kilo release of OpenStack.

#### Horizon support

For starters, you may be wondering if it is possible to log in from the Horizon
dashboard and have a more friendly way to interact with a remote cloud. The
unfortunate answer is no, because the implementation of the SAML2 federation
protocol in Keystone is incomplete. The SP side has support for the "websso"
flow, which enables Horizon to connect to an external IdP, but the Keystone
IdP implementation does not currently support websso, restricting Horizon to
only connect to third party IdPs at this time. An example IdP that works well
with Horizon is the Active Directory Federation Service from Microsoft (ADFS).

#### Command line client support

In the previous section, you saw that to use the `openstack` command line client
with federation you have to provide a token and the endpoint of the service
you want to connect to. When working with a local OpenStack cloud, the
clients can connect to the Keystone service to request a token and the service
catalog, and can then obtain the required endpoint from this catalog. This all
happens transparently during the authentication process, the command line
clients know how to do all this for you.

At this time, the authentication flow for K2K is not fully integrated
with the OpenStack clients, so a fully automated authentication similar to that
of a local cloud is not possible. Work on a K2K federation authentication
extension for Keystone is currently in progress, so this limitation is likely
going to be a non-issue in the Liberty release. My hope is that with some
additional variables added to the user's `openrc` file, the command line
clients can perform the complete federated authentication, similar to the
**federated-login.sh** wrapper scripts included with openstack-ansible, and with
automated endpoint lookup. We'll see if this becomes a reality.

#### Fernet tokens and federation

While working on the federation support for openstack-ansible, we noticed that
there were problems with federated tokens when the Keystone service in the SP
cloud is configured to use Fernet tokens. There is a fix made towards the
Liberty release, but that fix has not been backported to Kilo yet. Hopefully by
the time you read this, the fix will be publicly available. But if you see that
the **federated-login.sh** wrapper script fails to obtain a token, you have
to switch the Keystone service in both clouds to UUID tokens, which as you saw
above, you can do by adding these variables to your **user\_variables.yml** file:

    keystone_token_provider: "keystone.token.providers.uuid.Provider"
    keystone_token_driver: "keystone.token.persistence.backends.sql.Token"

### Final words

I hope this article was helpful in giving you an introduction to the K2K
federation features in the Kilo release. And if you weren't familiar with the
[openstack-ansible](https://github.com/openstack/openstack-ansible) project, I
hope I said enough good things about it that you will decide to check it out in
detail, even if you don't plan to use federation.

My intention is to write a follow up federation article when the Liberty
release ships. I hope by that time some of the problems I enumerated in this
article will have a solution.

Thank you!

Miguel
