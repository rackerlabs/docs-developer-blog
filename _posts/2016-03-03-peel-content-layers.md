---
layout: post
title: Peeling back layers of content
date: '2016-03-03 00:00'
comments: true
author: Anne Gentle
authorAvatar: 'https://en.gravatar.com/userimage/1298029/6adf532b0824e2fe4cd8feab84f6b98e.jpg'
bio: Anne Gentle is a Principal Engineer at Rackspace where she serves on the OpenStack Technical Committee and advocates for cloud users.
published: true
categories:
  - Developers
  - Python
  - architecture
authorIsRacker: true
---

At our annual rax.io internal technical conference in San Antonio this week, I had a blast hacking on a reporting tool for our new content engine behind developer.rackspace.com and support.rackspace.com.

<!-- more -->

## Presentation layer: the web pages

To take a look at each layer, start with the obvious one: the one you read! For each documentation page found on developer.rackspace.com/docs and support.rackspace.com/how-to, there's lovely documentation.

{% img right 2016-03-03-peel-content-layers/devrspage.png developer.rackspace.com site %}

Looking at each page, there's a particular layout for each that makes the page useful. For example, [work with server image restoration with the dashboard](
https://support.rackspace.com/how-to/create-an-image-of-a-server-and-restore-a-server-from-a-saved-image/)
and [create an image of a server with the API](
https://developer.rackspace.com/docs/cloud-servers/v2/developer-guide/#create-image-of-specified-server).

There's the "View Source" layer, which is the HTML, CSS, and JavaScript that collectively create the beautiful documentation displayed in the browser. That source is made by our [Deconst](https://github.com/deconst/) tooling to form a control layer, in our case, called [nexus-control](https://github.com/rackerlabs/nexus-control).

## Authoring layer: the source files

Peeling off that presentation layer and looking at the source files, you find [RST](https://raw.githubusercontent.com/rackerlabs/docs-cloud-servers/master/api-docs/api-operations/methods/post-create-image-of-specified-server-servers-server-id-actions.rst) and [Markdown](https://raw.githubusercontent.com/rackerlabs/rackspace-how-to/master/content/cloud-servers/create-an-image-of-a-server-and-restore-a-server-from-a-saved-image.md) files, which are stored and edited in GitHub. We can edit with authors around the world on GitHub, and it's truly amazing.

{% img left 2016-03-03-peel-content-layers/rstsource.png developer.rackspace.com source %}

## Delicious layer: the content API

The next layer is the one I wanted to hack on this week, because the content service enables a [content API](https://github.com/deconst/content-service#api). Typically, we use the API to [post the content for display in the upper layers](https://deconst.horse/developing/architecture/#lifecycle-of-an-http-request). Now that we have migrated to this new system, we have a way to report on the content for quality and completeness. I started with some use cases, wrote them down in the [README](https://github.com/deconst/cli-deconst/blob/master/README.md), and got going.

One of the best parts of this learning curve was realizing how helpful [iPython](http://ipython.org/install.html) is for this type of development -- type in a few ideas, import `pythonfilename`, edit some more, reload the `.py` file with `reload(pythonfilename)`, call the function directly in iPython with tab completion, and keep going.

I focused squarely on my Python knowledge and set to making some API calls with the [requests](http://docs.python-requests.org/) library. The first order of business was to get a list of content IDs. My first thought was to use the GitHub API and search for repos with "docs-" in the name. Then I looked for a Python library to do that and to scope it only to the rackerlabs organization. Two of my teammates helped me find suitable Python libraries, and I went with one but discovered that I couldn't figure out authentication in time to demo in the afternoon. So, we created a list by hand, and the code iterated through that list to create URL-encoded content IDs that the content API can understand.

Here's a Github repo URL:
`https://github.com/rackerlabs/docs-cloud-servers`
Here's a URL-encoded content ID:
`https%3A%2F%2Fgithub.com%2Frackerlabs%2Fdocs-cloud-servers`

{% img 2016-03-03-peel-content-layers/ipython.png iPython in action %}

Thanks, Python requests.utils.quote!

Now to take that list of content IDs and look at loads of metadata. I fed the content IDs into another function, this one uses Python requests to get the JSON from the content service and then only look at the titles.

{% img left 2016-03-03-peel-content-layers/contentid.png meta in envelope JSON %}

As an example, look at what you get back when you do a GET for a content ID by clicking [this URL](https://developer.rackspace.com:9000/content/https%3A%2F%2Fgithub.com%2Frackerlabs%2Fdocs-cloud-big-data).

Lots of JSON! I can get some meta data, the title, and with a list of content IDs, I could get a list of titles. Or a list of authors, or a list of even more metadata. Exciting!

<div class="clearfix"></div>

```
...
RackConnect API 3.0
...
Rackspace Private Cloud Powered By Red Hat
...
None
Rackspace How-To Articles
```

And look at the next to last line, the script already found a content ID with no title, though in this case it all checks out fine.

I can also search through our existing content using the `/search?q=:term` operation. After the hackathon I added the ability to do a search query based on a term. How about searching for [RackConnect](https://developer.rackspace.com:9000/search?q=rackconnect) using the content API and getting back some JSON as well as a count of 210 results.

## What's next?

The endpoint for our content API is open for read actions, so if you're interested you can take a look at the work so far at https://github.com/deconst/cli-deconst/ and join in. The [content API is documented in the content-service repo](https://github.com/deconst/content-service#api). Next we'll wrap it up in a CLI for easier reporting. Feel free to join in the delicious content API layer fun.

<a href="https://commons.wikimedia.org/w/index.php?curid=37028602">
{% img center 2016-03-03-peel-content-layers/layercake.jpg Fancy layer cake by Jacklee, CC By-SA 4.0 %}
</a>
