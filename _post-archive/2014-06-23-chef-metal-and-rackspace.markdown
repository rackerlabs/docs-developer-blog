---
layout: post
title: Chef Metal and Rackspace
date: '2014-06-26 08:00'
comments: true
author: Hart Hoover
published: true
categories:
  - Chef
---
{% img right 2014-06-23-chef-metal/chef-logo.png 160 160 %}

Chef recently launched [Chef Metal][1], a way to define clusters of machines with
Chef recipes. With Chef Metal's `machine` resource, you can keep your entire
server environment under the same version control that holds your configuration
management recipes.

<!-- more -->

Chef Metal works by using a provisioning node to control your infrastructure. The
provisioning node keeps track of the machines you've defined and will create a
new one if needed.

For Chef Metal to work with a Chef Server (or while using Chef's Platform) you
will need to have an existing node that will act as your provisioner. This node
will already need to be registered as a client with your Chef Server. The
provisioner will also require admin privileges. You can set this with the
`knife acl` plugin or edit permissions with knife:

`knife edit groups/admins.json`

Once that's all done, you'll need to add a Chef Metal recipe to the
provisioner's run list. Here's a sample recipe to use:

```ruby
case node['platform']
when 'debian', 'ubuntu'
  node.set['apt']['compile_time_update'] = true
  include_recipe 'apt'
when 'redhat', 'centos', 'fedora', 'amazon', 'scientific'
  include_recipe 'yum'
end

node.set['build-essential']['compile_time'] = true
include_recipe 'build-essential'

chef_gem 'chef-metal' do
  version '0.12.1'
  action 'install'
end

chef_gem 'chef-metal-fog' do
  version '0.6.1'
  action 'install'
end

require 'chef_metal'
require 'chef_metal_fog'
require 'cheffish'
require 'fog'

# Get credentials
rackspace = Chef::EncryptedDataBagItem.load('secrets', 'cloudcreds')
username = rackspace['username']
apikey = rackspace['apikey']

with_driver 'fog:Rackspace:https://identity.api.rackspacecloud.com/v2.0',
            compute_options: {
              rackspace_api_key: apikey,
              rackspace_username: username,
              rackspace_region: 'iad'
            }

# You need to generate a keypair in ~/.ssh for use with Metal
fog_key_pair my-key

with_machine_options ssh_username: 'root',
                     bootstrap_options: {
                       key_name: my-key,
                       flavor_id: 'performance1-2',
                       image_id: 'ffa476b1-9b14-46bd-99a8-862d1d94eb7a'
                     }

with_chef_server Chef::Config[:chef_server_url],
                 client_name: Chef::Config[:node_name],
                 signing_key_filename: Chef::Config[:client_key]

# Database node first, then web node through notifies statement
machine 'mysql' do
  chef_environment '_default'
  recipe 'apt'
  recipe 'mysql'
  attributes(
    mysql: {
      server_root_password: 'randompass',
      server_repl_password: 'randompass',
      server_debian_password: 'randompass'
    }
  )
  notifies 'converge', 'machine[web]', 'delayed'
end

machine 'web' do
  chef_environment '_default'
  recipe 'apt'
  recipe 'apache2'
  action 'nothing'
end
```

Let's walk through this in sections. The first section basically gives Chef the
tools it will need to install Chef Metal:

```ruby
case node['platform']
when 'debian', 'ubuntu'
  node.set['apt']['compile_time_update'] = true
  include_recipe 'apt'
when 'redhat', 'centos', 'fedora', 'amazon', 'scientific'
  include_recipe 'yum'
end

node.set['build-essential']['compile_time'] = true
include_recipe 'build-essential'

chef_gem 'chef-metal' do
  version '0.12.1'
  action 'install'
end

chef_gem 'chef-metal-fog' do
  version '0.6.1'
  action 'install'
end

require 'chef_metal'
require 'chef_metal_fog'
require 'cheffish'
require 'fog'
```

The second section is loading your Rackspace Cloud credentials from an
[encrypted data bag][2]:

```ruby
# Get credentials
rackspace = Chef::EncryptedDataBagItem.load('secrets', 'cloudcreds')
username = rackspace['username']
apikey = rackspace['apikey']
```

The third section is when we really get into Chef Metal bits. Chef Metal uses a
driver system to talk to clouds, bare metal, or virtualized infrastructure. For
this example, we're using the [chef-metal-fog][3] driver which uses the [fog][4]
library to talk to the Rackspace API. In this code block we're telling Chef Metal
which driver to use, as well as providing the credentials we read from our data
bag. We're also providing the region in which we wish to build. This section can
also be placed in your knife.rb if you want to keep it out of your recipe.

```ruby
with_driver 'fog:Rackspace:https://identity.api.rackspacecloud.com/v2.0',
            compute_options: {
              rackspace_api_key: apikey,
              rackspace_username: username,
              rackspace_region: 'iad'
            }
```

The next section defines a SSH key for Chef Metal to use when provisioning
new servers. `fog_key_pair` will look for matching key files in .chef/keys,
~/.chef/keys and ~/.ssh. The `with_machine_options` code will apply these options
to all machines Chef Metal encounters. Here, I'm saying I want all machines to
be Ubuntu 12.04 and 2GB Performance Cloud Servers.

```ruby
# You need to generate a keypair in ~/.ssh for use with Metal
fog_key_pair my-key

with_machine_options ssh_username: 'root',
                     bootstrap_options: {
                       key_name: my-key,
                       flavor_id: 'performance1-2', # 2GB Performance Cloud
                       image_id: 'ffa476b1-9b14-46bd-99a8-862d1d94eb7a' # Ubuntu 12.04
                     }
```

Next, this section tells Chef Metal that when you spin up a new machine, register
it with same Chef Server that controls the provisioning node.

```ruby
with_chef_server Chef::Config[:chef_server_url],
                 client_name: Chef::Config[:node_name],
                 signing_key_filename: Chef::Config[:client_key]
```

Finally, I have two machines defined. I have the web node set to
`action 'nothing'`, with a `notifies` statement that converges the web node upon
completion of the database node.

```ruby
# Database node first, then web node through notifies statement
machine 'mysql' do
  chef_environment '_default'
  recipe 'apt'
  recipe 'mysql'
  attributes(
    mysql: {
      server_root_password: 'randompass',
      server_repl_password: 'randompass',
      server_debian_password: 'randompass'
    }
  )
  notifies 'converge', 'machine[web]', 'delayed'
end

machine 'web' do
  chef_environment '_default'
  recipe 'apt'
  recipe 'apache2'
  action 'nothing'
end
```

Another way to build machines in a specific order is to set `auto_batch_machines =
false` in your recipe. Otherwise Chef Metal will build all of your machines in
parallel. Using Chef Metal's "batch mode" you can build many of the same machines
at once:

```ruby
machine_batch do
  %w(primary secondary web1 web2)
  action 'setup' # does everything except converge
end

machine_batch do
 machine 'primary' do
   recipe 'initial_ha_setup'
   action 'converge'
 end
end

machine_batch do
 machine 'secondary' do
   recipe 'initial_ha_setup'
   action 'converge'
 end
end
```

You can bootstrap your provisioning node with knife with this recipe, and it will
create two nodes on the Rackspace Cloud!

`knife bootstrap -x root -E 'development' -r "recipe[cookbook::metal.rb" 12.34.56.78`

You can also build nodes with Chef Metal without a provsioner using the
`chef-client` in [local mode][5]. Just set the 'with_chef_server' section in your
recipe appropriately. Chef Metal is still under heavy development and you can
follow along on [GitHub][6]. Couple Chef Metal provisioning with a mixture of
Cloud Servers and [OnMetal Compute][7] and you'll be one happy Chef.

### About the Author

Hart Hoover is an Engineer with the [DevOps Automation Service][8] team at
Rackspace. You can follow him on twitter [@hhoover](https://twitter.com/hhoover).

[1]: https://www.getchef.com/blog/2014/03/04/chef-metal-0-2-release/
[2]: https://docs.opscode.com/chef/essentials_data_bags.html#encrypt-a-data-bag-item
[3]: https://github.com/opscode/chef-metal-fog
[4]: https://fog.io
[5]: https://www.getchef.com/blog/2014/06/24/from-solo-to-zero-migrating-to-chef-client-local-mode/
[6]: https://github.com/opscode/chef-metal
[7]: https://www.rackspace.com/cloud/servers/onmetal/
[8]: https://www.rackspace.com/devops/
