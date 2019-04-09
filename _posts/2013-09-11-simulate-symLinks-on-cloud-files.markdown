---
layout: post
title: Simulate symLinks on Rackspace Cloud Files
date: '2013-09-11 08:00'
comments: true
author: Sri Rajan
published: true
categories:
  - Cloud Files
---

Rackspace cloud files which is based on [Openstack Swift](http://docs.openstack.org/developer/swift/)
provides reliable & fast, object storage and you can read more about the product
[here](http://www.rackspace.com/cloud/files/technology/).

In Cloud Files, there is no built-in way to do aliases or multiple names to the
same object. However, after some documentation trolling and speaking to some of
our Cloud Files engineers, there is a way to achieve it, although it is not
straightforward.

<!-- more -->

Cloud Files offers large file (over 5G) support by allowing multiple segments
to be uploaded and then a manifest that links the segments. This
[blog post](http://www.rackspace.com/blog/rackspace-cloud-files-now-supporting-extremely-large-file-sizes/)
explains the concept well.

We can leverage the same feature to achieve symlinking/aliasing. To begin with get an auth token:


	 curl -D - \
  	  -H "X-Auth-Key: <replace with your api key>" \
  	  -H "X-Auth-User: <replace with your username>" \
  	  https://identity.api.rackspacecloud.com/v1.0


Results should look similar to the following example:

    HTTP/1.1 204 No Content
	 Server: nginx/0.8.55
	 Date: Sat, 24 Aug 2013 14:12:13 GMT
	 Connection: keep-alive
	 X-Storage-Token: <storage token>
	 X-Storage-Url: <returned storage URL>
	 X-Server-Management-Url: <returned server management URL>
	 X-CDN-Management-Url: <returned CDN management URL>
	 X-Auth-Token: <auth token used for subsequent requests>
	 vary: Accept, Accept-Encoding, X-Auth-Token, X-Auth-Key, X-Storage-User, X-Storage-Pass, X-Auth-User
	 Cache-Control: s-maxage=85963
	 VIA: 1.0 Repose (Repose/2.3.5)
	 Front-End-Https: on

Now let's create a test file which we will use for the symlink.

	 echo 'Analys(z)e  This !! :)' >adata.txt

We now upload this file to a Cloud Files container named 'examples' using the storage URL returned above.

	 curl -X PUT -H 'X-Auth-Token: <auth token from above>' \
	 <storage URL from above>/examples/adata.txt --data-binary '@adata.txt'

Now we use our friendly X-Object-Manifest header to create the links we want.
Create a link for **analyse.txt**. In this case we pass an empty input to `--data-binary`:

	 curl -X PUT -H 'X-Auth-Token: <auth token from above>' \
	 -H 'X-Object-Manifest: examples/adata.txt' \
	 <storage URL from above>/examples/analyse.txt --data-binary ''

Then create a link for analyze.txt:

	 curl -X PUT -H 'X-Auth-Token: <auth token from above>' \
	 -H 'X-Object-Manifest: examples/adata.txt' \
	 -H 'Content-Type: text/plain; charset=UTF-8' \
	 <storage URL from above>/examples/analyze.txt --data-binary ''


Test with curl

	 curl http://54f0e726bcfd86d8ba66-784e69335b6098f55ce69a880b15667d.r49.cf3.rackcdn.com/analyse.txt
	 Analys(z)e  This !! :)

	 curl http://54f0e726bcfd86d8ba66-784e69335b6098f55ce69a880b15667d.r49.cf3.rackcdn.com/analyze.txt
	 Analys(z)e  This !! :)

We have effectively created a symlink to another object inside the cloud files container.

If you are using CDN, you likely have more friendly URLS and they will work the same:

	 curl <Friendly CDN URL>/analyse.txt
	 curl <Friendly CDN URL>/analyze.txt

While this may seem like bit of a workaround, functionality wise, this works
the same as any other object storage operation in Cloud Files.
