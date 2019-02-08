---
layout: post
title: Elasticsearch autodiscovery on the Rackspace Cloud
date: '2014-03-18 13:30'
comments: true
author: Ryan Richard
published: true
categories:
  - Chef
  - DevOps
---


[Elasticsearch](http://www.elasticsearch.org/) is a powerful distributed
schema-less datastore and its main focus is indexing/search functionality. One
benefit of Elasticsearch is simple cluster management via
[multicast](http://en.wikipedia.org/wiki/Multicast), which is provided out of
the box.

Unfortunately, multicast is often blocked by cloud vendors due to security
concerns of a mutli-tenancy network (imagine exposing your software to the rest
of the cloud via multicast). This is where
[Rackspace Cloud Networks](http://www.rackspace.com/knowledge_center/article/getting-started-with-cloud-networks)
can help out. One of the primary goals of Cloud Networks is to allow personal
L2 networks in a mutli-tenancy environment. This means we get multicast!

<!-- more -->

### Set up

(The following assumes nova CLI already set up your workstation)

Create your ES cloud network:

```
nova network-create es 192.168.3.0/24
```

Boot an instance with the network attached:

```
nova boot --flavor performance1-1 --image 80fbcb55-b206-41f9-9bc2-2dd7aac6c061 --nic net-id=<UUID from network-create> es-blog1
```

The above steps can be performed in the Cloud Control Panel as well.

### Server configuration

Install Elasticsearch your preferred way. I prefer this [Chef cookbook](https://github.com/elasticsearch/cookbook-elasticsearch), but you'll need to add some attributes to configure the multicast address in the next section if your using Chef.

Set net.ipv4.icmp_echo_ignore_broadcasts to 0:

```
sysctl net.ipv4.icmp_echo_ignore_broadcasts=0
```

Next, you'll need to add a route for the multicast network range. Again replace eth2 with the interface associated your cloud-network:

```
ip route add 224.0.0.0/4 dev eth2
```

Feel free to replace the multicast network with a smaller one. Be sure to add the route and sysctl settings to the appropriate places to allow it persist across reboots.

### Elasticsearch configuration

In your elasticsearch.yml file, set:

```
discovery.zen.ping.multicast.enabled: true discovery.zen.ping.multicast.address: _eth2:ipv4_
```

Replace eth2 with the interface associated with your cloud network range (most likely eth2).

You can check /usr/local/var/log/elasticsearch/elasticsearch.log to make sure you've discovered the cluster correctly once you've booted a second Elasticsearch node:

```
[INFO ][cluster.service         ] [es-blog2] detected_master [es-blog1][89ltAR7psngnHl3PA][inet[/1.1.1.1:9300]]{max_local_storage_nodes=1}, added {[es-blog1][89ltAR7psngnHl3PA][inet[/1.1.1.2:9300]]{max_local_storage_nodes=1},}, reason: zen-disco-receive(from master [[es-blog1][89ltAR7psngnHl3PA][inet[/1.1.1.2:9300]]{max_local_storage_nodes=1}])
```

### Conclusion

By default, Elasticsearch sends *transport* (inter-cluster communication) data
out eth0. Since you have your own L2 network, I would recommend setting
transport.host: _eth2:ipv4_ as well.

Lastly, be sure to read the documentation regarding the architecture for
Elasticsearch, how to handle failure scenarios, and how to configure Elasticsearch
to avoid split-brain scenarios.


