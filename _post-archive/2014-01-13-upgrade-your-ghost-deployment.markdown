---
layout: post
title: Upgrade Your Ghost Deployment
date: '2014-01-13 16:00'
comments: true
author: Ryan Walker
published: true
categories: []
---

Back in October of 2013 I wrote about how to [launch Ghost with Rackspace Deployment](https://developer.rackspace.com/blog/launch-ghost-with-rackspace-deployments.html). Today, Ghost [announced](http://blog.ghost.org/ghost-0-4/) the release of thier latest version - 0.4.0. Now that Ghost has gone through a few updates, it is a good time to go over the process of updating your Ghost deployment. <!-- more -->

# It's Dangerous to Go Alone! Take This.

First things, first. Here's what you will need before we begin:

* Root access to your Ghost server.
	* When you created your deployment, you should have been given an SSH key that will provide you with root access. You kept that, right?
	* If you are unfamiliar with SSH keys, check out these docs for [Linux/Mac](http://www.rackspace.com/knowledge_center/article/logging-in-with-a-ssh-private-key-on-linuxmac) and [Windows](http://www.rackspace.com/knowledge_center/article/logging-in-with-a-ssh-private-key-on-windows).
	* If all else fails and you don't know the root password, follow [these](http://www.rackspace.com/knowledge_center/article/managing-your-server-7-reset-your-server-password-0) instructions to reset it through the control panel.
* A recent backup.
	* Seriously. If anything on your Ghost blog is important, back it up first. While this update method is tested, swamp gas, solar flares, and/or aliens could cause unexpected consequences.
	* Check out [this](http://www.rackspace.com/knowledge_center/article/cloud-essentials-4-creating-an-image-backup-cloning-and-restoring-a-server-from-a-saved) link on how to create a server snapshot.

# Roll Up Your Sleeves and Dig In

* Once logged in to the server as `root`, type `cd /var/www/vhosts/<your_domain>` to change into the directory where Ghost is installed.
* Download the latest version of Ghost: `wget http://ghost.org/zip/ghost-latest.zip`.
* Next, remove the the existing Ghost core directory: `rm -rf ghost/core`.
* Extract the new Ghost files into the `ghost` directory: `unzip -uo ghost-latest.zip -d ghost`.
* Change the ownership of the new files: `chown -R ghost:ghost ghost/*`.
* Now, `cd` into the `ghost` directory: `cd ghost`.
* Run `npm install --production` to install/update dependencies.
* Finally, restart the Ghost service: `restart ghost`.

# Check Yourself

It doesn't look like the UI displays a version anywhere, so to verify that everything updated, look for this content in the HTML:

```
# curl -s localhost|grep generator
<meta name="generator" content="Ghost 0.4" />
```

The `content=` section should match the version you installed.

# This Is Why We Can't Have Nice Things

If you experience issues with posts not displaying after updating, it may be caused by Nginx caching. In newer Ghost Deployments, this has been removed, but if you experience issues the caching can easily be disabled.

* Copy the text below and paste it into `/etc/nginx/sites-available/ghost`:

```
server {
  listen       80 default_server;

  access_log  /var/log/nginx/ghost-access.log;
  error_log   /var/log/nginx/ghost-error.log;

  location ~ ^/(img/|css/|lib/|vendor/|fonts/|robots.txt|humans.txt) {
    root /var/www/vhosts/ghost.example.com/ghost/core/client/assets;
    access_log off;
    expires max;
  }

  location ~ ^/(shared/|built/) {
    root /var/www/vhosts/ghost.example.com/ghost/core;
    access_log off;
    expires max;
  }

  location ~ ^/(favicon.ico) {
    root /var/www/vhosts/ghost.example.com/ghost/core/shared;
    access_log off;
    expires max;
  }

  location ~ ^/(content/images/) {
    root /var/www/vhosts/ghost.example.com/ghost;
    access_log off;
    expires max;
  }

  location / {
    proxy_redirect	   off;
    proxy_set_header   X-Real-IP            $remote_addr;
    proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   Host                   $http_host;
    proxy_set_header   X-NginX-Proxy    true;
    proxy_set_header   Connection "";
    proxy_http_version 1.1;
    server_tokens off;
    proxy_buffering on;
    proxy_pass             http://localhost:2368/;
  }
}
```

* Replace `ghost.example.com` with the domain name used with the deployment:

```
sed -i 's/ghost.example.com/<your_domain>/g' /etc/nginx/sites-available/ghost
```

* Restart Nginx: `service nginx restart`.

# About the Author
Ryan Walker is a DevOps Engineer at Rackspace working on the Deployments team. You can follow him on twitter [@theryanwalker](http://twitter.com/theryanwalker) and on Github as [ryandub](https://github.com/ryandub).
