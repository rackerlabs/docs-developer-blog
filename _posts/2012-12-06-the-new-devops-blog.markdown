---
layout: post
title: The new DevOps blog
date: '2012-12-06 12:07'
comments: true
author: Hart Hoover
categories:
  - General
---
We've moved! The Rackspace DevOps Blog is now hosted on Rackspace [Cloud Files](http://www.rackspace.com/cloud/public/files/) (powered by [OpenStack Swift](http://www.openstack.org/software/openstack-storage/)) using [Octopress](http://octopress.org/). This blog was hosted on [WordPress](http://www.wordpress.org), using a mix of various Rackspace Open Cloud products:

* Cloud Load Balancers
* Cloud Servers
* Cloud Databases

Wayne and I loved this setup and were pleased with performance and security. WordPress on this infrastructure was secure for our purposes (it's a simple blog, not hosting medical data or taking credit cards) so we were happy. So why move?
<!-- more -->

##We wanted something more scalable.
*Huh, what? Those products all scale!* Well, yes. The issue was WordPress scalability. If you want to scale WordPress you need to think about things like file synchronization across servers for uploads (or NFS or clustering) and MySQL replication. Sure we were doing some things right - we had [Varnish](https://www.varnish-cache.org/), we had [Memcached](http://memcached.org/), we were using [lsyncd and rsync](http://code.google.com/p/lsyncd/). But again, this is a simple blog - why is this so complicated?

Hosting static pages on Cloud Files is stupid easy and extremely scalable. Our blog is distributed globally using [Akamai's CDN](http://www.rackspace.com/cloud/public/files/technology/?page=cdn) with no effort on our part.

##We wanted to fit into the Open Cloud philosophy
WordPress is open source, but it isn't easy for Rackers around the company to contribute to our blog. Wayne and myself are the only people who can log into WordPress for posting. Here is the process for someone else to give us a story when we used WordPress:

1. Someone writes a story using a text editor of their choice. (Word, vim, TextMate, emacs, whatever)
2. They email one of us the story. The other person might not know about it.
3. We read it, and email it back to them for revisions.
4. They rework it, send it to us again... by email.
5. We email the finished article to our editor, [Andrew Hickey](https://www.linkedin.com/in/andrewrhickey).
6. Andrew emails us a different copy with his edits.
7. We cut/paste the article into WordPress and post it.

**What a horrible process.** We wanted to start thinking of our blog and posts like source code. In software development, writing code using the above process would be impossible. We have version control systems for a reason and we want to use them. We did not see a way to do that with WordPress without a lot of work. With our blog sitting in a GitHub repository and static, the new process is a lot easier:

1. Someone forks [our GitHub repository](https://github.com/raxdevblog/devopsblog) and creates a post: `rake new_post['Title']`.
2. They submit a [pull request](https://help.github.com/articles/using-pull-requests) to us with the new post.
3. We review, make revisions if needed and approve the pull request.
4. Jenkins sees the new commit, generates our blog and deploys it to our Cloud Files container automatically.

We've introduced some automation, saved ourselves from some email, and made it easier for developers to contribute to our blog.

##So how did we migrate?
Migrating from WordPress to Octopress is not foolproof, although there are some tools out there that help.

First, I cloned the [Octopress repository](https://github.com/imathis/octopress) from GitHub to my local machine and [set it up](http://octopress.org/docs/setup/). The process is pretty straightforward on that front. I renamed the theme from "classic" to "rackspace" and customized it for our needs using [this post from Aijaz Ansari](http://aijazansari.com/2012/08/27/how-to-customize-octopress-theme/) as a guide. I made a few other changes and added some sidebar and social content.

At this point I had a working Octopress installation, but I needed the existing content from WordPress. I used the ["export" function](http://codex.wordpress.org/Tools_Export_Screen) inside WordPress to get an XML file of our posts. To convert this to Markdown format for Octopress, I used a tool called [exitwp](https://github.com/thomasf/exitwp). It is extremely important to make sure you have body_replace tags [set in exitwp](https://github.com/thomasf/exitwp/blob/master/config.yaml) to automate the conversion as much as possible. I found I still had to go through each article and check for things I missed, as well as set an author for each post.

##Setting up Cloud Files
Once I had Octopress ready to be published, I needed a Cloud Files container to serve our content. I used the following API commands with Cloud Files:

{% codeblock lang:bash %}
#Auth
curl -i -H "X-Auth-User: ${USER}" -H "X-Auth-Key: ${KEY}" https://auth.api.rackspacecloud.com/v1.0

#Create a Cloud Files container called "devops"
curl -X PUT -H "X-Auth-Token: $TOKEN" https://storage101.dfw1.clouddrive.com/v1/MossoCloudFS/devops

#Set the proper header for serving web content
curl -X POST - -H "X-Container-Meta-Web-Index: index.html" -H "X-Auth-Token: ${TOKEN}" https://storage101.dfw1.clouddrive.com/v1/MossoCloudFS/devops/
{% endcodeblock %}

Now we have a container called "devops" that serves our content. I set up [Jenkins](http://jenkins-ci.org/) on a Cloud Server to watch commits to our GitHub repository and deploy our blog to Cloud Files. Last but not least, I switched DNS from our old environment to the Cloud Files container.

##Shouldn't this blog be called NoOps now?
At this point, that case can probably be made. There is still some operational work to be done on the Jenkins end, but for the most part the blog is basically operations-free from our end. We want to focus on providing good content, not on operational day-to-day work for a blog and this setup allows us that freedom.
