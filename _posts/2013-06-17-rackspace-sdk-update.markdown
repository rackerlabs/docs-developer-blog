---
layout: post
title: Rackspace SDK update
date: '2013-06-18 09:21'
comments: true
author: Jesse Noller
published: true
categories:
  - SDK
  - jclouds
---

{% img right 2013-06-17-rackspace-sdk-update/gear.png 200 %}

We have some updates to share in regards to the [Rackspace SDKs][1]! Our SDKs
are either maintained by contributing to existing projects (as in the case of
jclouds or fog) or creating our own that we hope to extend to all OpenStack-based
clouds.

###fog (Ruby)

[fog][2] 1.12.1 was released on Monday.

Among the Rackspace changes are the ability to upload large files, support for
proxies when using Authentication v2.0, and a fix to address the lack of time
zone on the last_modifed attribute.

[Kyle Rames][3], the developer contributing to fog for Rackspace, has received
some help from fellow Rackers. Chris Wuest has also made fog contributions and
Zack Feldstein assisted with [knife-rackspace][4].

Not only that, but Kyle has been making these contributions as well:

* Kyle [wrote a gist][5] on how to use cURL with the Rackspace Cloud
* Kyle also created a repository for [Ruby SDK training][6]

<!-- more -->

###pkgcloud (node.js)

[pkgcloud][7] 0.8.2 released a little over a week ago. The last few updates to
pkgcloud have been around Rackspace/OpenStack. You can read the changelog [here][8].

[Ken Perkins][9], a core maintainer for pkgcloud, is contributing a ton to make
the node.js SDK spectacular. He's been driving in huge amounts of contributions,
tests, support for Rackspace and more. The community is really taking notice!

{% tweet https://twitter.com/rosskukulinski/status/345236875138703360 align='center' %}

###Pyrax (python)

[Pyrax][10] 1.4.6 was released. Pyrax now supports all OpenStack clouds, as well
as the ability to authenticate with an existing token. The addition of
authenticating with an existing token was added at the specific request of
[Team Charmander][11], the Rackspace team working on [Heat][12]. You can read
the changelog for pyrax [here][13].

[Ed Leafe][14] has been focused on helping customers using Pyrax. He's a machine.
Literally, we think he might be a robot!

###libcloud (Python)

[Alex Gaynor][15] has been meeting with the current [libcloud][16] team to bring
libcloud into the officially supported SDK family!

###jclouds (Java)

Zack Shoylev, [Everett Toews][17], [Jeremy Daggett][18], and others have been
hard at work on [jclouds][19]. jclouds is also an official [Apache Software Foundation project][20]!

Zack is currently working on adding support for [Cloud Databases][21], Jeremy is
working on Swift/Cloud Files, and Everett has been [advocating jclouds externally][22]:

{% img center 2013-06-17-rackspace-sdk-update/everett.png 400 %}
<p style="text-align: center; font-size: 80%">Everett Toews at Cloud Expo</p>

###php-opencloud (PHP)
[Jamie Hannaford][23] recently added support for [Cloud Monitoring][24] to
[php-opencloud][25]. We are still performing some tests before we formally release it.

Keep checking back for more updates as we release them!

[1]: http://developer.rackspace.com/#home-sdks
[2]: https://rubygems.org/gems/fog
[3]: https://twitter.com/krames
[4]: https://github.com/opscode/knife-rackspace
[5]: https://gist.github.com/krames/5775104
[6]: https://github.com/rackerlabs/ruby-sdk-training
[7]: https://github.com/nodejitsu/pkgcloud
[8]: https://github.com/nodejitsu/pkgcloud/blob/master/CHANGELOG.md
[9]: https://twitter.com/kenperkins
[10]: https://github.com/rackspace/pyrax
[11]: http://developer.rackspace.com/blog/autoscale-and-orchestration-the-heat-of-openstack.html
[12]: https://wiki.openstack.org/wiki/Heat
[13]: https://github.com/rackspace/pyrax/blob/master/RELEASENOTES.md
[14]: https://twitter.com/EdLeafe
[15]: https://twitter.com/alex_gaynor
[16]: http://libcloud.apache.org/
[17]: https://twitter.com/everett_toews
[18]: https://twitter.com/jeremy_daggett
[19]: http://jclouds.incubator.apache.org/
[20]: http://developer.rackspace.com/blog/jclouds-1-6-0.html
[21]: http://www.rackspace.com/cloud/databases/
[22]: http://blog.phymata.com/
[23]: https://twitter.com/jamiehannaford
[24]: http://www.rackspace.com/cloud/monitoring/
[25]: https://github.com/rackspace/php-opencloud
