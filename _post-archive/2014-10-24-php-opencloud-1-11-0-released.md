---
layout: post
title: php-opencloud 1.11.0 Released
date: '2014-10-24 08:00'
comments: true
author: Shaunak Kashyap
published: true
categories:
  - sdk
  - developers
  - openstack
bio: |
  Shaunak Kashyap is a Developer Advocate on the Rackspace Developer Experience
  team. He works primarily on the open-source php-opencloud SDK. You can find
  Shaunak on Twitter @shaunak and Github as ycombinator.
---

Today we are proud to announce the [v1.11.0 release](https://github.com/rackspace/php-opencloud/releases/tag/v1.11.0) of php-opencloud. In the four months since our last minor release, we have added support for the [OpenStack Orchestration service](https://wiki.openstack.org/wiki/Heat), support for [booting a server from a volume](https://docs.openstack.org/user-guide/content/boot_from_volume.html), and several other improvements and bug fixes. Many of these improvements and bug fixes have come from community contributors, which makes this release just that much more special.

<!-- more -->

## Orchestration

This release adds support for the OpenStack Orchestration service (OpenStack project alias: Heat). OpenStack Orchestration is a service that will let you launch multiple composite cloud applications based on templates in the form of JSON or YAML files. At Rackspace, our implementation of it is known as [Cloud Orchestration](https://www.rackspace.com/cloud/orchestration/).

## Boot From Volume

Until now you could use php-opencloud to boot up OpenStack compute servers by specifying an image ID. With this release, you can alternatively boot up servers by specifying a bootable volume ID.

## Datastores and Configurations

Now you can use php-opencloud to retrieve information about the various [datastores](https://docs.rackspace.com/cdb/api/v1.0/cdb-devguide/content/datastore_types_and_versions.html) supported by your OpenStack or Rackspace cloud. You can also create and manage [custom configurations](https://docs.rackspace.com/cdb/api/v1.0/cdb-devguide/content/configurations.html) for these datastores.

## Other Improvements and Bug Fixes

We made several smaller &mdash; but no less important &mdash; improvements and bug fixes as well. We also improved our documentation and added more code samples. You can read about them in our [release notes](https://github.com/rackspace/php-opencloud/releases/tag/v1.11.0).

## To Our Community Contributors
Many of the additions and bug fixes in this release came from our community contributors. Thank you, [Jasper Aikema](https://github.com/asusk7m550), [Chris Smith](https://github.com/cs278), [Ben Speakman](https://github.com/Ben-Speakman), [Josh Manders](https://github.com/killswitch), [Graham Campbell](https://github.com/GrahamCampbell), [Jim Bodine](https://github.com/jsbodine), [Joseph Roberts](https://github.com/jjtroberts), and [Markus Stefanko](https://github.com/mastef) for your contributions and bug reports to php-opencloud.

If _you_ would like to become a contributor as well, just read our [contribution guidelines](https://github.com/rackspace/php-opencloud/blob/working/CONTRIBUTING.md) and send in your pull requests!

## Conclusion

Let us know what you think! Feel free to reach out to me, Shaunak Kashyap, on Twitter [@shaunak](https://twitter.com/shaunak). And, as always, if you find a bug or see something we could improve in php-opencloud, please file an issue [here](https://github.com/rackspace/php-opencloud/issues).
