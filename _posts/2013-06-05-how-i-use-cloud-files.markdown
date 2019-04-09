---
layout: post
title: 'Customer Story: How I use Cloud Files'
date: '2013-06-05 09:23'
author: Brad Montgomery
comments: true
published: true
categories:
  - Cloud Files
---

I've been using Cloud Files for about two years, and I thought I'd share some
of the tools that fit into my typical workflow. At
[Work for Pie](https://workforpie.com), we're using Cloud Files for three
somewhat distinct purposes:

1. Storage & Content Delivery for our web application's static assets (i.e.
   CSS, JavaScript, and images).
2. Storage & Content Delivery for user-uploaded images (photos and user avatars)
3. Storage for nightly database backups.

I've [previously written](http://www.rackspace.com/blog/work-for-pie-cloud-files/)
a bit about how our web app deals with the first two cases, but in this article,
I'll list of the tools that I personally use to work with Cloud Files.<!-- more -->

The Control Panel
-----------------

Rackspace has recently launched a newer, faster, control panel for Cloud Files—
and their other Cloud-based services—that provides easy CRUD operations for
all of your Cloud Files containers. Thankfully, this is a huge improvement over
the previous control panel (sorry guys, but it was really too slow to use with
any frequency).

The new control panel is fast, easy to use, and it's aesthetically pleasing. If
I need to create a new Cloud Files container, or double-check the public CDN
links for a container, this is where I go. Not to mention, the new control panel
also includes all the tools to manage CloudServers as well as other Rackspace
Cloud products.

Command-Line Tools
------------------

While the new control panel is really useful, and easy to use, I still prefer a
good-old-fashioned command line. I already work on the command line frequently,
so having a command-line Cloud Files interface is convenient. Additionally, I
can automate command-line tools, which lets me schedule tasks to publish files
automatically.

We're a Python shop, and in the past, I'd built a small command-line interface
on top of ``python-cloudfiles``, but since that's recently been deprecated, I've
started using the [swift client](https://github.com/openstack/python-swiftclient),
and I'm very happy with the way it works.

In fact, I've written a collection of small bash functions
([swift_wrapper.sh](https://gist.github.com/bradmontgomery/5673778)) that
read my Rackspace credentials from environment variables, which saves me a
bit of typing. To work with Cloud Files, I'd add something like the following
to my ``.profile`` or ``.bashrc``

    export RACKSPACE_API_KEY=my_api_key
    export RACKSPACE_USERNAME=my_username
    export RACKSPACE_CLOUDFILES_CONTAINER=my_cloudfiles_container
    source /path/to/swift_wrapper.sh

You can run ``swifthelp -v`` to get a full list of commands available, but I'll
illustrate a few. Here are some typical tasks that I might perform in any given
day:

**Publish a new version of a Twitter Bootstrap.**

  If my project has the following directory structure

    myproject/
        static/
            twitter_boostrap/

  I could run the following command to publish twitter bootstrap to Cloud Files::

    cd myproject/static/ && swiftupload twitter_bootstrap/

**Delete an Arbitrary File**

  Periodically, I need to remove a user-uploaded file; either because it's been
  orphaned, or corrupted due to some edge-case in my application. Given that
  I know the path of the object, I can delete it with the following command::

    swiftdelete path/to/users/avatar.png

**Download an snapshot of a Production Database Backup.**

  Assuming that my backups are stored in a (private, non-CDN) container called
  "db_backup_container", I can list all objects with the following::

    export RACKSPACE_CLOUDFILES_CONTAINER=db_backups # Use a different container
    swiftlist

  Then, assuming I have an object named ``snapshot.sql.bz2``, I can download
  it to my local machine with:

    swiftdownload snapshot.sql.bz2

**Deploy static assets with a Fabric Task**

  We're a Django shop, and I Use [Fabric](http://fabfile.org/) for a number
  of tasks, particularly to deploy individual django apps. My task to deploy
  static assets looks something like the following:

    def publish_static_files():
        # assume we've already run "python manage.py collectstatic"
        with lcd(STATIC_ROOT):
            local('swiftupload *')

  The really nice thing about this, is that the swift client only uploads the
  files that have changed since the previous upload.

**A Cron Task that stores Database Backups**

  I also have a nightly cron task that just dumps all content from a read-only
  PostgreSQL slave, compresses it, then publishes to a private container::

    source /path/to/swift_wrapper.sh

    DATE=`date +%F`
    BACKUP_FILE=$DATE.sql

    # Dump & Compress the DB
    pg_dump -U $DBUSER $DBNAME > $BACKUP_FILE
    bzip2 $BACKUP_FILE
    BACKUP_FILE=$BACKUP_FILE.bz2

    # Store on Cloud Files
    source /path/to/virtualenv/swift/bin/activate && swiftupload $BACKUP_FILE


My General Opinion of Cloud Files
--------------------------------

In general, I'm really happy with both the performance and the ease with which
I can use Cloud Files both in my applications and as an "end-user". While I wish
I could say this has always been the case, I've definitely seen an improvement
in availability over the last six months or so. For a while, we'd experience
frequent, periodic timeouts for SSL connections, but I'm happy to see these
incindents decline dramatically. Of course, when troubles do pop up, I'm quite
satisfied by the support that I recieve.

I'm also fairly intrigued by the recent announcement that Rackspace will provide
[support for your application code](http://www.rackspace.com/blog/rackspace-developer-support-fanatical-support-for-your-code/).
While I'm a bit curious just how this works (it seems you share relevant bits
of code in a regular support ticket), I think it's a good step toward
communicating that Rackspace services are developer-friendly.

This also seems to be evident by the recent launch of the
[Rackspace Developer Center](http://developer.rackspace.com). This portal
makes it much easier to find the existing documentation for various services.
It's obviously a new effort, and like most early projects, it still needs a bit
of polish. Luckily, it's also an
[open source project](https://github.com/rackerlabs/devsite/) with quite
a bit of recent activity, including a significant number of closed issues.

I hope to see continued effort to make this portal useful, as well as continued
efforts to keep the documentation current and useful. Of course, continued
support and development of the API libraries themselves is also important, and
I personally appreciate that these libraries are open source.

To wrap up, I'll say that I'm still a happy Rackspace customer, and I'm
encouraged by the positive activity that I see to make their services more
accessible to developers.

---

Brad Montgomery is a software developer and entrepreneur in Memphis, TN. He has predominantly worked on web-based products, and is the co-founder of Work for Pie — a company that believes it can find a better way for Companies to recruit software developers. Brad believes in an agile-inspired approach to work, and he prefers open source tools. He has built a number of products using Python and Django, though he fully believes in using the right tool for the job (whether that’s python, ruby, javascript, C, or a bash script). Brad lives in Bartlett, TN with his wonder wife and two amazing daughters (both of whom are growing up way to quickly!).
