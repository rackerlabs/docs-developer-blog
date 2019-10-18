---
layout: post
title: Developing with Cloud Images for fun and profit
date: '2014-04-01 11:00'
comments: true
author: Brian Rosmaita
published: true
categories:
  - Cloud Servers
  - OpenStack
---

Rackspace has just launched Cloud Images, a public OpenStack Images
API v2 endpoint in the Rackspace open cloud.  Why should you care?
Well, this product creates several opportunities for developers.

<!-- more -->

{% img 2014-03-27-announcing-cloud-images/Rackspace_Cloud_Images_vert_clr.png %}

### API only

Cloud Images is currently accessible via the API only, so there's an
opportunity to create interfaces and tools to facilitate use of Cloud
Images itself.  See the [Rackspace Cloud Images Developer Guide](http://docs.rackspace.com/images/api/v2/ci-devguide/content/index.html)
for more information.

### Image sharing

Cloud Images allows users to share VM images with each other using the
OpenStack Images API v2.  The v2 implementation was designed to
prevent image producers from "spamming" other users by filling their
image-lists with junk images.  Thus, image sharing is a two step
process:

3. The image producer makes another user with whom the image is to be
shared a "member" of that image.  Once this happens, the image member
can boot servers from that image immediately (as long as they know its
UUID).
3. The image consumer can "accept" the image to make it appear in his
or her image list.  (But note that this isn't necessary in order for
the consumer to use the image.  It is necessary, though, if the
consumer is going to find the image in the Cloud Control Panel and
boot from it there.)

The opportunity here is that the Images API doesn't provide for
producer-consumer communication.  It's assumed that all communication
is done independently.  Thus, if a producer makes you a member of an
image, you don't get any kind of notification from Cloud Images.
Rather, the producer must contact you via normal communication
channels (e.g., email) that already have anti-spam measures in place
if you decide that you really don't want to interact with this image
producer.

In other words, Cloud Images provides the infrastructure for some type
of image marketplace, but doesn't put any constraints on how the
marketplace should function.

See the [Cloud Images API documentation](http://docs.rackspace.com/images/api/v2/ci-devguide/content/image-sharing.html) for a more detailed overview of
image sharing and the associated API calls.

### New image creation

It's great to have an image sharing infrastructure, but of course that
would be pretty pointless without there being cool images to share.
Thus another opportunity for developers is to create new images.
There are a few different ways to do this depending on your interests.

3. Boot a server in the Rackspace cloud using one of our standard
public images, configure it with software (properly licensed, of
course ... you have to handle that part yourself), create an image of
the server, and then share that image.
3. Use [boot.rackspace.com](https://developer.rackspace.com/blog/introducing-boot-dot-rackspace-dot-com.html) to create an image containing an
operating system that isn't included among the standard Rackspace
public images, and then share that image.
3. Build a completely new image offline (although it must be [properly
prepared to boot in the Rackspace cloud](http://www.rackspace.com/knowledge_center/article/preparing-an-image-for-import-into-the-rackspace-open-cloud)), then use the image
import feature of Cloud Images to make it a bootable image, and then
share that image.

### And more

Check out our [Cloud Images FAQ](http://www.rackspace.com/knowledge_center/article/cloud-images-frequently-asked-questions) to get a more extensive overview
of the product and what it can do.

### References

- Rackspace Cloud Images Developer Guide: http://docs.rackspace.com/images/api/v2/ci-devguide/content/index.html
- Image Sharing Overview: http://docs.rackspace.com/images/api/v2/ci-devguide/content/image-sharing.html
- boot.rackspace.com: https://developer.rackspace.com/blog/introducing-boot-dot-rackspace-dot-com.html
- Preparing an Image for the Rackspace Cloud: https://support.rackspace.com/how-to/preparing-an-image-for-import-into-the-rackspace-opencloud/
- Cloud Images FAQ: https://support.rackspace.com/how-to/cloud-images-faq/
