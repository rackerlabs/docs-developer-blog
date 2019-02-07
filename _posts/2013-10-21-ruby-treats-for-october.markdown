---
layout: post
title: Ruby treats For October
date: '2013-10-23 09:00'
comments: true
author: Kyle Rames
published: true
categories:
  - devops
---

Here are the latest Ruby treats from the Developer Relations Group.

### Fog (1.16.0)

After two months the fog community released 1.16.0. With all this extra time we sure managed to pack a lot of goodies into it!

Highlights include:

* Support for **Rackspace Auto Scaling**.
* The Rackspace Compute provider now **defaults** to Next Gen Servers.
* Cloud Block Storage now supports creating volumes using a snapshots.
* Cloud Servers now retrieves **full details** for **flavor** and **image** calls.

Auto scaling is our favorite new feature. To help you get started right away, we have created a [quick start guide](https://github.com/fog/fog/blob/master/lib/fog/rackspace/docs/auto_scale.md) and have included several [examples](https://github.com/fog/fog/tree/master/lib/fog/rackspace/examples/auto_scale).

<!-- more -->


And if you still do not have access to this exciting new feature, you can request it [here](https://rackspace.qualtrics.com/SE/?SID=SV_6S7kmhVU8ClMEXr).


### vagrant-rackspace (0.1.4)

vagrant-rackspace now allows you to provision servers with custom networks using the `rs.network` option.

For example, if you wanted to create a server and attach it to the Internet, Rackpace ServiceNet, along with custom network `443aff42-be57-effb-ad30-c097c1e4503f` you would update your `Vagrantfile` as follows:

```ruby
config.vm.provider :rackspace do |rs|
  rs.username = "mitchellh"
  rs.api_key  = "1234"
  rs.network '443aff42-be57-effb-ad30-c097c1e4503f'
end
```

For more information refer to the [network section](https://github.com/mitchellh/vagrant-rackspace#networks) of the vagrant-rackspace documentation.

### rumm (0.0.24)

And finally a long requested feature for rumm *--multiple region support*!

When you login to rumm it will now ask you for your default region. To access servers outside of this region simply prefix your rumm command with `REGION=<region name>`.

For example to list servers in the IAD data center you would execute the following:

    REGION=iad rumm show servers

### About the Author

Kyle Rames is a developer advocate for the Rackspace Cloud specializing in all things Ruby. You can follow him on twitter [@krames](http://twitter.com/krames) and on Github as [krames](https://github.com/krames).

