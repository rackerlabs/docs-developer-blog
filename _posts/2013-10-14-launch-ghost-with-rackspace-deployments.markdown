---
layout: post
title: Launch Ghost with Rackspace Deployments
date: '2013-10-14 00:22'
comments: true
author: Ryan Walker
published: true
categories:
  - General
---

After a successful [Kickstarter](http://www.kickstarter.com/projects/johnonolan/ghost-just-a-blogging-platform)
campaign with over 5,000 backers raising over $300,000, the team over at [Ghost](http://ghost.org)
announced today the public availability of their much anticipated new blogging platform.

I have personally been following this project from the beginning because of the
principles Ghost was born out of: simple, elegent, open source design. The Node.js-based
blogging platform touts itself as "just a simple blogging platform", but everything
about its design is focused on writing - nothing more, nothing less. Posts are
written in [Markdown](http://daringfireball.net/markdown) with a split screen
showing a live preview on the right. Adding an image? Just add the Markdown
syntax for an image and suddenly a drag-and-drop image box appears in the
preview screen ready for you to upload your image! The whole system makes writing
blog posts fast and easy and lets you quickly get back to doing something other
than yelling at the internet.

<!-- more -->

### Great, I must have it!

Whoa, slow down there, tiger. The only part of Ghost that isn't easy for most
people is installation and configuration. Like most CMS's Ghost requires a
database backend (it currently supports both Postgres and MySQL). In addition,
you have to install Node.js and run some npm commands and modify a **config.js**
file to get everything setup. Finally, if you want things to run really well,
you need to setup Nginx in front of Ghost to do caching, SSL termination and
proxy back to Ghost. This can be tedious. Wouldn't it be nice if you could just
click a few buttons and someone would do it for you?

We thought so too, and with the help of John O'Nolan and Hannah Wolfe over at
Ghost, we put together a Rackspace Deployment to do all of this for you with
just a couple of clicks. Here's how:

- Sign in to myCloud at **https://login.rackspace.com** and click the **Deployments** tab:

{% img 2013-10-14-launch-ghost-with-rackspace-deployments/deploymentstab.png 'Deployments Tab' 'Deployments Tab' %}

- Click **Create Deployment**:

{% img 2013-10-14-launch-ghost-with-rackspace-deployments/createdeployment.png 'Create Deployment' 'Create Deployment' %}

- Choose a Deployment name and region at the top and Select **Ghost** from the list:

{% img 2013-10-14-launch-ghost-with-rackspace-deployments/deploymentlist.png 'Select Ghost' 'Select Ghost' %}

- Under **Ghost Options**, enter your blog's domain name and choose if you want HTTP or HTTPS:

{% img 2013-10-14-launch-ghost-with-rackspace-deployments/ghostoptions.png 'Ghost Options' 'Ghost Options' %}

- Click **Next Step** and choose the server size you would like:

{% img 2013-10-14-launch-ghost-with-rackspace-deployments/serveroptions.png 'Server Options' 'Server Options' %}

- Click **Create Deployment** and you are done! Just sit back and wait for everything to build.

### Next step

Once your deployment is finished, you can add a DNS record for your domain to
point to the server that was created for you, or just browse to the IP address
of the server to get started using Ghost.

When you browse to your Ghost deployment, you should be greeted with a simple
page with a sample post:

{% img 2013-10-14-launch-ghost-with-rackspace-deployments/ghostwelcome.png 'Ghost Welcome' 'Ghost Welcome' %}

Before we can do anything though, we need to add a user. Navigate to ```/ghost/signup```,
and enter some info in order to create the Admin user when prompted. Ghost
currently only supports one user at this time. After filling out this info,
you are redirected to the admin panel where you can start customizing your blog
and adding new posts.

To start, let's add a new test post. Click on **New Post** at the top left, which
takes you to the post editor and the beauty of Ghost. Add a post title and start
typing out your post in Markdown. Notice that the right side of the screen shows
a live preview as you type! Also, notice the drag-and-drop image box in the preview
pane as well:

{% img 2013-10-14-launch-ghost-with-rackspace-deployments/ghosteditor.png 'Ghost Editor' 'Ghost Editor' %}

Once you are finished, click the arrow next to **Save Draft** in the bottom right
and select **Publish Now**. That's it! You now have a new blog post!

It should be noted that Ghost is still in heavy development and that this is
their first public release. There are probably bugs, and they have a ton more
features promised that have not been developed yet. However, this release puts
them off to a great start at making something that makes simple blogging simple
for everyone.

### About the Author

Ryan Walker is a DevOps Engineer at Rackspace working on the Deployments team.
You can follow him on twitter [@theryanwalker](http://twitter.com/theryanwalker)
and on Github as [ryandub](https://github.com/ryandub).
