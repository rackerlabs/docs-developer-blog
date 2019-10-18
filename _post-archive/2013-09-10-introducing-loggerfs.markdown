---
layout: post
title: Introducing LoggerFS
date: '2013-09-10 09:15'
comments: true
author: Eric Cheek
published: true
categories: []
---
> WARNING: LoggerFS PROJECT HAS BEEN ABANDONED BY ITS MAINTAINER.

Applications generate logs for the purposes of debugging, maintenance, analytics and sometimes legal compliance. Logs are important but are too often overlooked until they cause problems (e.g. filling hard disks and crashing production systems). Veteran devops engineers are more proactive about logging and use systems such as [Logstash](https://logstash.net/), [Loggly](https://loggly.com/) or [Splunk](https://www.splunk.com/) to move logs away from application servers and provide analytics and indexed search. While the merits of various log management tools can be debated, the simple fact is you should be using something (and not grepping through 100mb+ files).

<!-- more -->

Typically log management systems consist of two components: shippers and aggregators. Shippers (AKA tailers, readers, or [beavers](https://beaver.readthedocs.org/) run on application servers to collect and transmit logs. Aggregators run on a central server, cluster of servers, or in a remote cloud for long-term storage and indexing. While aggregators handle most of the heavy-lifting for log management systems, shippers must support logging from arbitrary services, survive network failures, and live within a small footprint that doesn't take system resources away from applications.

#### Problems with Log Shippers
* **Polling** -  Some shippers periodically check files for changes, unnecessarily burning CPU cycles
* **Local writes** -  Many log shippers expect logs to be written to a local disk. In the case of database servers, DB operations and logging compete for the same, limited resource resulting in a negative impact on performance. 
* **Potential duplication/loss of log lines** -  Many shippers use a file to store the seek position in a log file across server reboots/failures. This writer/reader positions can become out of sync particularly when log rotation is involved.
* **Log rotation is a nightmare** - There are several of ways to achieve log rotation with each requiring some level of coordination between separate applications. Traditional shippers require configuration to support various schemes and without careful reasoning, it's possible to introduce ugly race conditions.

Shippers that solve the above problems usually require integration into applications. This requires modifying your applications or [begging](https://jira.mongodb.org/browse/SERVER-2957) [maintainers](https://forum.nginx.org/read.php?2,225811,225811) to [add support](https://mail-archives.apache.org/mod_mbox/couchdb-dev/201004.mbox/%3C1864489532.633161270122867302.JavaMail.jira@brutus.apache.org%3E) for a logging system (typically Syslog).


### Introducing LoggerFS
LoggerFS is a [Go](https://golang.org/)-based [FUSE](https://fuse.sourceforge.net/) filesystem designed to be a universal interface to various log management systems. It's trivial to feed logs into LoggerFS since it's a file system and [everything is a file](https://en.wikipedia.org/wiki/Everything_is_a_file). LoggerFS eliminates the need for polling, log rotation, and reader seek state files.

Under the hood, LoggerFS implements a subset of file system operations to allow writing and basic permissions management. The log data is buffered in-memory (potentially journaled for reliability) and sent over a configurable transport. The applications (e.g. Nginx, Mongodb, or your service) simply interact with files without knowing or caring what happens behind the scenes.

##### Features

* Backend/Aggregator agnostic (includes multiple log transports)
   * Supports any Syslog-based log manager
      * Loggly, Splunk, Logstash, Rsyslog/Syslog-ng
   * ZeroMQ
   * [NSQ](https://github.com/bitly/nsq) transport -- used [internally at AutoRef.com](https://autoref.com/blog/tag/web%20tech/)
   * Generic UDP/TCP
   * And soon: AMQP and Redis (and later: Scribe? Fluentd?)
* Tagging
   * Add arbitrary custom fields to log data (e.g. hostname, filename, pid/process name, uid/username of writer)
* Improved security
   * Doesn't need permission to read log files and, depending on configuration, logs never touch the disk.
   * TLS-support (for some transports)
* Easy to use with any service
   * For most applications it's as simple as pointing the log to the mounted file system
   * What if a service only writes to STDOUT/STDERR? Redirect to LoggerFS: 

   ```
   mydaemon 2> /mnt/loggerfs/service.error.log 1> /mnt/loggerfs/service.log
   ```
   
Unlike piping a shipper, LoggerFS supports an arbitrary number of services that can start and stop independently.
   
   * Can't customize the log file path? Symlink to loggerfs: 
   
   ```
   ln -s /mnt/loggerfs/mydaemon.log /var/log/rigid_path.log;
   mydaemon
   ```

You can also symlink entire directories to capture multiple files.

* Can't disable log rotation? Configure LoggerFS to ignore the rotated files.

```
logs:
  - name: exclude rotated logs
    pattern: .*\.[0-9]+(\.gz)?
    ignore: yes
```

#### Future Developments

We hope that building an easy-to-use and reliable log shipper will help teams adopt a log management system.

For now, we're polishing the code and writing tests to prepare an initial open source release of LoggerFS. [Let us know](https://twitter.com/autoref) if you're interested in checking it out! We could also use some input on a name -- I'm currently thinking 'SlumberjackFS' (tagline: Sleep knowing your logs are safe).

---
##### About the Author
Eric Cheek is a senior software engineer at [AutoRef.com](https://autoref.com). Check out other AutoRef tech articles and the latest on the automotive industry at the AutoRef blog: [https://autoref.com/blog/tag/web tech/](https://autoref.com/blog/tag/web tech/)
