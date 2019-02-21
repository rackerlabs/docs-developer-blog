---
layout: post
date: '2015-08-11 23:59'
title: 'Introducing rack &ndash; A Rackspace global command-line interface'
comments: true
author: Ken Perkins
authorIsRacker: true
authorAvatar: 'https://pbs.twimg.com/profile_images/421780751701401600/0YpuLSd3_400x400.jpeg'
published: true
categories:
  - General
---

It's not every day that we get to release a new tool! Awesome Rackers across the company produce tools all the time, but we think today's news stands alone. We're thrilled to announce the first beta release of `rack`, a new [global command-line interface](https://developer.rackspace.com/docs/rack-cli) purpose-built for interacting with the Rackspace cloud.

<img class="blog-post" src="{% asset_path 2015-08-11-introducing-rack-global-cli/rack.gif %}"/>

<!-- more -->

`rack`, a single binary download, requires _almost_ no installation. We've made `rack` in Go, and we have binaries available for [OSX](https://ec4a542dbf90c03b9f75-b342aba65414ad802720b41e8159cf45.ssl.cf5.rackcdn.com/1.0.0-beta.1/Darwin/amd64/rack), [Linux](https://ec4a542dbf90c03b9f75-b342aba65414ad802720b41e8159cf45.ssl.cf5.rackcdn.com/1.0.0-beta.1/Linux/amd64/rack), and [Windows](https://ec4a542dbf90c03b9f75-b342aba65414ad802720b41e8159cf45.ssl.cf5.rackcdn.com/1.0.0-beta.1/Windows/amd64/rack.exe). In addition, we've standardized the command interface across services, so there should never be any suprises.

`rack` has built-in support for profiles, so that you can have multiple sets of credentials and manage using different sets easily. Command auto-completion makes learning new commands truly effortless.

Once you [download `rack`](https://developer.rackspace.com/docs/rack-cli) and make it executable, create a profile.

```
rack configure
```

This configuration wizard will guide you through creating a profile that can be used in successive calls. If you choose to create a default profile, you won't even have to specify the profile when invoking `rack`. For example, to view all of your servers (based on the default profile you created):

```
rack servers instance list
```

The preceding example is representative of all of the commands in `rack`, which take the form of `rack <service> <sub-service> <action> [flags]`. We hope that this model makes it easy to interact with `rack` and you dive in to explore services you haven't had much opportunity to interact with before.

The initial release of `rack`, version `1.0.0-beta.1` supports four core Rackspace services:

- Cloud Servers
- Cloud Files
- Cloud Networks
- Cloud Block Storage

In the coming releases, we'll add support for additional services, and respond to feedback we get from you. We can't make this tool be awesome without your input; we're using GitHub for [issue tracking](https://github.com/rackspace/rack/issues) and [planning purposes](https://github.com/rackspace/rack/milestones). We truly appreciate all contributions, especially feature requests! Great software is the result of impassioned people working together.

We hope you love what we're building with `rack`, and we can't wait to add more capabilities.

- [Download `rack`](https://developer.rackspace.com/docs/rack-cli/#quickstart)
