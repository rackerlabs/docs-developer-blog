---
layout: post
title: PostgreSQL + WAL-E + Cloudfiles = Awesome
date: '2014-01-6 12:00'
comments: true
author: Alex Gaynor
published: true
categories:
  - General
---

If you're a big PostgreSQL fan like I am, you may have heard of a tool called
WAL-E. Originally developed by Heroku, WAL-E is a tool for efficiently sending
PostgreSQL's WAL (Write Ahead Log) to the cloud. In addition to Heroku, WAL-E
is now used by many companies with large PostgreSQL deployments, including
Instagram.

Let's unpack what that means. If you've ever set up replication with PostgreSQL
you're probably familiar with the WAL. Essentially there are two parts to
replication and backup in PostgreSQL, the "base backup" and the WAL. Base
backups are a copy of your database files that can be taken while the database
is running. You might create base backups every night, for example. The WAL is
where PostgreSQL writes each and every transaction, as they happen. When you
run normal replication, the leader will send its log file to the followers as
it writes it.

Instead of just using a simple socket to communicate, WAL-E sends these base
backups and WAL files across the internet with the help of a cloud object
store, like Cloudfiles (or any OpenStack Swift deployment). This gives you the
advantage that, in addition to just being replication, you have a durable
backup of your database for disaster recovery. Further, you have effectively
infinite read scalability from the archives, you can keep adding more followers
without putting more stress on the leader.

With the help of WAL-E's primary author, Daniel Farina, we recently added
support for OpenStack Swift to it. It's not yet in a final release, but if
you're interested in checking it out, read on!

<!-- more -->

### Setting it up

The first thing to do to get this running is to spin up two cloud servers, one
for your PostgreSQL leader, and another for the follower (you can do it with
one server that has both the leader and the follower, but where's the fun in
that?). You can spin up your servers with either the control panel, or one of
our many SDKs. Here I'm booting up two 1GB performance cloud servers.

```
$ pip install rackspace-novaclient
...
$ export OS_AUTH_URL=https://identity.api.rackspacecloud.com/v2.0/
$ export OS_AUTH_SYSTEM=rackspace
$ export OS_REGION_NAME=IAD
$ export OS_USERNAME=<your username>
$ export OS_TENANT_NAME=" "
$ export NOVA_RAX_AUTH=1
$ export OS_PASSWORD=<your api key>
$ export OS_NO_CACHE=1
$ nova boot postgresql-leader --flavor performance1-1 --image 62df001e-87ee-407c-b042-6f4e13f5d7e1 --key_name my_key --poll
...
Instance building... 100% complete
Finished
$ nova boot postgresql-follower --flavor performance1-1 --image 62df001e-87ee-407c-b042-6f4e13f5d7e1 --key_name my_key --poll
...
Instance building... 100% complete
Finished
```

Now that we have our servers, let's SSH into each of them and get PostgreSQL
installed.

```
(postgresql-leader) $ sudo apt-get update
(postgresql-leader) $ sudo apt-get install -y postgresql python-virtualenv python-dev git libevent-dev pv lzop
(postgresql-follower) $ sudo apt-get update
(postgresql-follower) $ sudo apt-get install -y postgresql python-virtualenv python-dev git libevent-dev pv lzop
```

Let's get the leader configured and sending it's logs up to Cloudfiles:

```
(postgresql-leader) $ virtualenv /opt/wale
(postgresql-leader) $ . /opt/wale/bin/activate
(postgresql-leader) $ pip install git+https://github.com/wal-e/wal-e
```

Before we go any further we need to create a container in Cloudfiles. You can
easily do this from the [Web interface](https://mycloud.rackspace.com/files).
Below it's referred to as "container-name".

Now you'll want to edit ``/etc/postgresql/9.1/main/postgresql.conf`` on
``postgresql-leader`` and change the following values:

```
wal_level = hot_standby
archive_mode = on
archive_command = 'WALE_SWIFT_PREFIX="swift://container-name" SWIFT_AUTHURL="https://identity.api.rackspacecloud.com/v2.0/" SWIFT_REGION="IAD" SWIFT_TENANT=" " SWIFT_USER="your username" SWIFT_PASSWORD="your password" /opt/wale/bin/wal-e wal-push %p'
archive_timeout = 60
```

You may find it easier to manage these environment variables with a tool like
``envdir`` (part of the ``daemontools`` package). Now you can restart
PostgreSQL:

```
(postgresql-leader) $ /etc/init.d/postgresql restart
```

PostgreSQL will now stream its logs to Cloudfiles, but we also need to upload a
base backup, so that there's something these logs are relative to:

```
(postgresql-leader) $ sudo -u postgres bash -c "WALE_SWIFT_PREFIX='swift://container-name' SWIFT_AUTHURL='https://identity.api.rackspacecloud.com/v2.0/' SWIFT_REGION='IAD' SWIFT_TENANT=' ' SWIFT_USER='your username' SWIFT_PASSWORD='your password' /opt/wale/bin/wal-e backup-push /var/lib/postgresql/9.1/main/"
```

Now let's throw some data into our PostgreSQL


```
(postgresql-leader) $ sudo -u postgres psql
postgres=# select generate_series(0, 10000000) into foobar;
SELECT 10000001
postgres=# \q
```

If you take a look at your container in the Control Panel, you'll see that
``wal-e`` has started sending your logs up to the cloud.

Now that we have our leader set up, it's time to set up the follower:

```
(postgresql-follower) $ virtualenv /opt/wale
(postgresql-follower) $ . /opt/wale/bin/activate
(postgresql-follower) $ pip install git+https://github.com/wal-e/wal-e
```

Now we can download the base backups:

```
(postgresql-follower) $ /etc/init.d/postgresql stop
(postgresql-follower) $ rm -rf /var/lib/postgresql/9.1/main
(postgresql-follower) $ sudo -u postgres bash -c "WALE_SWIFT_PREFIX='swift://container-name' SWIFT_AUTHURL='https://identity.api.rackspacecloud.com/v2.0/' SWIFT_REGION='IAD' SWIFT_TENANT=' ' SWIFT_USER='your username' SWIFT_PASSWORD='your password' /opt/wale/bin/wal-e backup-fetch /var/lib/postgresql/9.1/main/ LATEST"
(postgresql-follower) $ chmod 0700 /var/lib/postgresql/9.1/main
```

And create ``/var/lib/postgresql/9.1/main/recovery.conf`` on
``postgresql-follower`` with the following variable:

```
standby_mode = on
restore_command = 'WALE_SWIFT_PREFIX="swift://container-name" SWIFT_AUTHURL="https://identity.api.rackspacecloud.com/v2.0/" SWIFT_REGION="IAD" SWIFT_TENANT=" " SWIFT_USER="your username" SWIFT_PASSWORD="your password" /opt/wale/bin/wal-e wal-fetch "%f" "%p"'
```

You'll also need to edit ``/etc/postgresql/9.1/main/postgresql.conf`` to set:

```
hot_standby = on
```

Now you can turn PostgreSQL back on:

```
(postgresql-follower) $ /etc/init.d/postgresql start
```

And if you wait a few moments and then spin up ``psql``, your data will be
there:

```
(postgresql-follower) $ sudo -u postgres psql
postgres=# select count(*) from foobar;
  count
----------
 10000001
(1 row)

postgres=# \q
```

And boom, we're set up and ready to go!

You can check out the [WAL-E docs](https://github.com/wal-e/wal-e#readme) for
more information on how to get the most out of it.

I'd like to thank Daniel Farina of Heroku for the afternoon he spent pair
programming with me to get this up and running.

Enjoy!
