---
layout: post
title: 'rsyslog &amp; ElasticSearch'
date: '2013-08-02 08:00'
comments: true
author: Micah Yoder
published: true
categories: []
---
There is a clear benefit to being able to aggregate logs from various servers and services into one place and be able to search them for any sort of arbitrary event.  Traditional syslog can aggregate logs, but aggregating events from them sometimes involves grep and convoluted regular expressions.  Logging structured data to a database makes a lot of sense.  rsyslog and ElasticSearch can do that, but figuring out how to get it to work from the rsyslog documentation can be difficult.  Let's start from the beginning.<!-- more -->

First, you need the newest stable rsyslog, 7.4.x.  The older 7.2 won't cut it.  You need the plug-ins mmnormalize and omelasticsearch, both of which are available from rsyslog's yum repositories for RHEL/CentOS.  mmnormalize requires some packages from EPEL so that will need to be added to the server as well.

Let's walk through this from the beginning, starting with the most basic rsyslog configuration:

	module(load="imuxsock") # provides support for local system logging (e.g. via logger command)
	module(load="imklog")   # provides kernel logging support (previously done by rklogd)
	$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
	*.*     /var/log/messages

This simply loads the necessary modules for basic logging operation, sets the normal log format, and sends everything to /var/log/messages.  With this if you issue this command:

	# logger 'hello world!'

You get this in /var/log/messages:

	Mar 27 14:16:47 micahsyslog root: hello world!

There are several parts here: the date/time, the hostname, the syslog tag or program (root), and the message.  Another example:

	# service sshd restart

yields:

	Mar 27 14:19:27 micahsyslog sshd[23295]: Received signal 15; terminating.
	Mar 27 14:19:27 micahsyslog sshd[16602]: Server listening on 0.0.0.0 port 22.
	Mar 27 14:19:27 micahsyslog sshd[16602]: Server listening on :: port 22.

By the way, if we remove the `ActionFileDefaultTemplate` directive, we get the default line with an ISO time, which is nicer for automatic processing but a bit less readable for humans:

	2013-03-27T21:51:29.139796+00:00 micahsyslog root: Hello world #2!

That is good to know, but actually irrelevant for putting data into ElasticSearch.  If you also log to text files, you can decide whether to use the ISO time or the more human readable time.

Now let's try to get it to normalize messages from the log!  For this example we will need rsyslog running with ActionFileDefaultTemplate directive (keep it in for now, but you can remove it later if you want).

Create a rulebase file, which will be used by liblognorm.  liblognorm is a library written by Rainer Gerhards, the author of rsyslog, which parses log messages according to a pattern and extracts variables from them.  We can create the file as /etc/rsyslog.d/rules.rb and put in these contents:

	prefix=%date:date-rfc3164% %hostname:word% %tag:word%
	rule=user: new user: name=%user:char-to:,%, UID=%uid:number%, GID=%gid:number%, home=%home:char-to:,%, shell=%shell:word%
	rule=test: Hello %x:number%

Now if we log something:

	# logger “Hello 55”

We should be able to get something like this:

	# lognormalizer -r rsyslog.d/rules.rb -t test < /var/log/messages 
	[cee@115 event.tags="test" x="55" tag="root:" hostname="micahsyslog" date="Mar 27 22:53:30"]

See what happened?  The lognormalizer command, which uses liblognorm, was able to pull out the number in the log as variable “x” according to our “test” rule.

A short description of the rule base is in order.  The prefix line contains a prefix that will be applied to all following rules.  A rule is defined by a line beginning with the word “rule”, followed by an “=” sign, an optional tag, then a “:”.  A space should then follow – but the space is actually part of the rule!  There will be a space after the prefix, so it needs to be there.

Documentation on the rulebase file can be found here: https://www.liblognorm.com/files/manual/index.html
Then navigate to How to use liblognorm → Rulebase.
This will show you all the directives you can use.

Now we need to get the data into ElasticSearch.  First we need to install it, which is very simple (at least for a single test node).  Just extract its tarball, change into the base directory, and run:

	# bin/elasticsearch -f

The `-f` causes it to run in the foreground so you can see what is going on.

We then add this to rsyslog.conf:

	module(load="mmnormalize")
	module(load="omelasticsearch")

	template(name="test" type="subtree" subtree="$!")

	set $!fac = $syslogfacility;
	set $!host = $hostname;
	set $!sev = $syslogseverity;
	set $!time = $timereported;
	set $!tgen = $timegenerated;
	set $!tag = $syslogtag;
	set $!prog = $programname;

	action(type="omelasticsearch" server="localhost" template="test")

So what is all this?  First we load the modules to normalize the log messages and for export to ElasticSearch.  These should be placed near the top of your rsyslog.conf file with any other includes.

The template statement tells which part of the CEE data should be sent to ElasticSearch.  Here a brief explanation of the data structure is necessary.

JSON (the format for CEE logging data and the native format for ElasticSearch) is a hierarchical data structure.  The root of the data structure in rsyslog is $! - something like the '{}' in a JSON document.  Assigning to $!data1 would put a value into the “data1” top level JSON element {“data”: “...”}.  Trees can be built.  If you assign to $!tree1!child1, you will get a JSON document like this: {“tree1: {“child1”: “...”}}

[This rsyslog document][1] lists the available properties that you can use to populate these CEE variables.

Unfortunately only the standard rsyslog properties and constants can be assigned to these variables.  I have not been able to find a way to assign the result of an rsyslog string or list template, which would allow more complex values.  Unfortunately that is what you need to put a sortable timestamp into the document.  Indeed that does not appear to be possible at the moment.  Hopefully future developments in rsyslog will enhance this functionality.

To get around this limitation (sort of), I created an ElasticSearch index with a timestamp.  Here is the command I used:

	curl -XPUT https://elasticsearch.hostname:9200/logs -d '{"mappings":{"events":{"_timestamp":{"enabled": true, "store": "yes"},"prog":{"store":"yes"},"host":{"store":"yes"}}}}'

This also “stores” the host and prog syslog fields, which should help with querying based on the host or program.  This will create an index called “logs”.  ElasticSearch by default inserts events into the “system” index so you will want to specify the index name in your omelasticsearch line in rsyslog.conf (or one of its includes):

	action(type="omelasticsearch" server="elasticsearch.hostname" template="cee_template_name" searchIndex="logs" bulkmode="on")

We also enabled bulk mode, which allows rsyslog to send many events at once to ElasticSearch.  This will greatly improve performance.

Now you can query it!

	curl 'https://elasticsearch.hostname:9200/logs/_search?pretty=1&fields=_source,_timestamp&size=100' -d '{"sort":{"_timestamp": "desc"}}' | less

The "pretty=1" and piping it to `less` are simply there to pretty print the JSON result and make it easy for you to browse the data set.  A real search program, of course, would not turn on pretty mode and the code would directly consume the JSON.

You can add parameters after the 'size=100' (which, of course, says to return the 100 most recent results).

* &q=word will search the logs for that word in any field.
* &q=prog:name will search for 'name' in the syslog program field. Examples: postfix, sudo, crontab
* &q=host:hostname will find events for that hostname.  Just use the base hostname, not a FQDN.

And that should get you started!  Hopefully this is helpful.

[1]: https://www.rsyslog.com/doc/property_replacer.html