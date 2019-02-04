---
comments: true
date: 2012-10-16T13:00:14.000Z
layout: post
title: 'Rate limiting with Repose, the restful proxy service engine'
author: Chad Lung
categories:
  - General
  - OpenStack
---

_Chad Lung is a software engineer on the Rackspace Cloud Integration team and
is the maintainer of Atom Hopper. Be sure to check out his personal blog at
[http://www.giantflyingsaucer.com/blog/](http://www.giantflyingsaucer.com/blog/)
and follow [@chadlung](https://twitter.com/chadlung) on Twitter._

I recently wrote an article introducing
[Repose](http://www.rackspace.com/blog/introducing-repose-the-restful-proxy-service-engine/),
which is a sponsored open-source project that is built to scale for the cloud.
[Repose](http://openrepose.org) is used within Rackspace as a a key element of
our internal [OpenStack](http://openstack.org).

<!-- more -->

Repose has many features such as **rate limiting**, **client authentication**,
**translation,** **API validation**, **versioning**, and **logging**, with
[more on the way](http://wiki.openrepose.org/display/REPOSE/_The+REstful+PrOxy+Service+Engine%3A+Introduction).

Today I want to show you how you can use Repose for your own projects, and, in
particular, I'm going to focus on [Rate Limiting](http://wiki.openrepose.org/display/REPOSE/Rate+Limiting+Filter).
Since Repose doesn't care what programming language my particular web service is
written in, I'm going to write a very simple [Node.js](http://nodejs.org) API
server and then use Repose to enforce rate limiting on it. At the same time, I
will also be using Repose's [HTTP Logging](http://wiki.openrepose.org/display/REPOSE/HTTP+Logging+Filter)
and [IP Identity](http://wiki.openrepose.org/display/REPOSE/IP+Identity) filters.

**Note:** I assume from here that you are working in a Linux or OS X environment.


### Creating the Node.js API Server

Make sure you have [Node.js](http://nodejs.org) installed and ready to go. On
your computer, create a new folder called **APIDemo** and add a new JavaScript
file called **app.js** to the folder.

The contents of the **app.js** file simply return the current date to the user.

**app.js:**

	 var express = require('express');
	 var app = module.exports = express();

	 // Very minimal API demo that returns
	 // the current date info
	 app.get('/api/getdate', function(req, res){
	   res.send(new Date());
	 });

	 app.listen(8080);
	 console.log('API demo server listening on port 8080');

To execute this code successfully, you must have [Express](http://expressjs.com/)
installed. You can do that from the command line easily by going into the **APIDemo**
folder and running the following command:

	 $ npm install express

Start the API server by running the following command:

	 $ node app.js

With a web browser, use the following URL to hit the API and have the date
returned to you:

[http://localhost:8080/api/getdate](http://localhost:8080/api/getdate)

### Setting up and Configuring Repose

Repose requires that a few folders exist on your system. Create the following folders:

* Configuration files are located in: **/etc/repose/**
* The EAR file drop location is located at: **/usr/share/repose/filters/**
* The standalone location for Repose is at: **/usr/share/lib/repose/** (You can also run Repose in a container such as [Apache Tomcat](http://tomcat.apache.org/))
* Log files are located at: **/var/log/repose/**
* The deployment location (where the EAR file is extracted) is at: **/var/repose/**

You also need to ensure that the user account that is running Repose has the
necessary access to read and execute on the appropriate folders.

With those folders created, we can move on to gathering the binary artifacts
required to run Repose. Alternatively, you can grab the source code from the
[GitHub repository for Repose](https://github.com/rackerlabs/repose) and compile
the code yourself.

Here are the steps to get the configuration and binary files copied over:

1. Copy all of the example Repose configuration files [from this location](https://github.com/rackerlabs/repose/tree/master/project-set/core/core-lib/src/main/resources/META-INF/schema/examples) into the **/etc/repose/** folder.
2. Copy the IP Identity configuration example file [from this location](https://github.com/rackerlabs/repose/blob/master/project-set/components/client-ip-identity/src/main/resources/META-INF/schema/examples/ip-identity.cfg.xml) into the **/etc/repose/** folder
3. Copy the Rate Limiting configuration example [file from this location](https://github.com/rackerlabs/repose/blob/master/project-set/components/rate-limiting/src/main/resources/META-INF/schema/examples/rate-limiting.cfg.xml) into the **/etc/repose/** folder
4. Copy the HTTP Logging configuration example [file from this location](https://github.com/rackerlabs/repose/blob/master/project-set/components/http-logging/src/main/resources/META-INF/schema/examples/http-logging.cfg.xml) into the **/etc/repose/** folder
5. Copy the latest EAR filter bundle [file from this location](http://maven.research.rackspacecloud.com/content/repositories/releases/com/rackspace/papi/components/filter-bundle/) and place **filter-bundle-x.x.x.ear** file into the **/usr/share/repose/filters/** folder.
6. Copy the latest **valve-x.x.x.jar** [file from this location](http://maven.research.rackspacecloud.com/content/repositories/releases/com/rackspace/papi/core/valve/) and place it into the **/usr/share/lib/repose/** folder.

**Note:** I’m using Repose’s **IP Identity** filter because it’s very easy to
use for demonstration purposes. In a real service, you might prefer to use the
Repose [Client Authentication](http://wiki.openrepose.org/display/REPOSE/OpenStack+Identity+Service)
filter, which supports the
[OpenStack Identity Service authentication](http://wiki.openstack.org/PluggableIdentityAuthenticationHandlers) scheme.

Next, let's modify the example **IP Identity** and **Rate Limiting** configuration
files to suit our needs. Starting with the **IP Identity** file, we can modify
it to accept requests from **localhost** only. Of course, this is just for
demonstration purposes and does not reflect a real world scenario.

**ip-identity.cfg.xml**

{% codeblock lang:xml %}
<?xml version="1.0" encoding="UTF-8"?>

<ip-identity  xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
   xmlns='http://docs.api.rackspacecloud.com/repose/ip-identity/v1.0'
   xsi:schemaLocation='http://docs.api.rackspacecloud.com/repose/ip-identity/v1.0'>

   <quality>0.2</quality>

    <white-list quality="1.0">
        <ip-address>127.0.0.1</ip-address>
    </white-list>

</ip-identity>{% endcodeblock %}

Save the changes to the file and then edit the **Rate Limiting** config file next.
This is where we lock down our API endpoint to only accept one `HTTP GET` request
per minute for standard users. This value can be configured easily, and any
changes you make get picked up by Repose and reloaded automatically.

**rate-limiting.cfg.xml**

{% codeblock lang:xml %}
<?xml version="1.0" encoding="UTF-8"?>

<rate-limiting delegation="false" xmlns="http://docs.rackspacecloud.com/repose/rate-limiting/v1.0">
    <!--
        Defining a limit group.

        The following headers can be found in the class
        com.rackspace.cloud.powerapi.http.PowerApiHeader in the Power API
        Filterlet library, maven group id com.rackspace.cloud.powerapi, artifact
        id filterlet.

        Groups are matched on the HTTP header: X-PP-Groups
        User information is matched on the HTTP header: X-PP-User
    -->
    <limit-group id="standard-ip-limits" groups="IP_Standard">
        <limit uri="/*" uri-regex="/(.*)" http-methods="GET" unit="MINUTE" value="1" />
    </limit-group>

    <limit-group id="standard-ip-limits-superuser" groups="IP_Super">
        <limit uri="/*" uri-regex="/(.*)" http-methods="GET" unit="SECOND" value="5" />
    </limit-group>
</rate-limiting>{% endcodeblock %}

Save the changes to the file and then edit the following config file next.

**http-logging.cfg.xml**

{% codeblock lang:xml %}<?xml version="1.0" encoding="UTF-8"?>

<http-logging xmlns="http://docs.rackspacecloud.com/repose/http-logging/v1.0">
    <!-- The id attribute is to help the user easily identify the log -->
    <!-- The format includes what will be logged.  The arguments with % are a subset of the apache mod_log_config
         found at http://httpd.apache.org/docs/2.2/mod/mod_log_config.html#formats -->
    <http-log id="my-special-log" format="Response Code Modifiers=%200,201U\tModifier Negation=%!401a\tRemote IP=%a\tLocal IP=%A\tResponse Size(bytes)=%b\tRemote Host=%h\tRequest Method=%m\tServer Port=%p\tQuery String=%q\tTime Request Received=%t\tStatus=%s\tRemote User=%u\tURL Path Requested=%U\n">
        <targets>
            <!-- The actual log file -->
            <file location="/var/log/repose/repose.log"/>
        </targets>
    </http-log>
</http-logging>{% endcodeblock %}

Save the changes to the file and then edit the following config file next.
We're just setting a few simple defaults.

**container.cfg.xml**

{% codeblock lang:xml %}<?xml version="1.0" encoding="UTF-8"?>

<repose-container xmlns='http://docs.rackspacecloud.com/repose/container/v2.0'>
    <deployment-config http-port="8888" connection-timeout="30000" read-timeout="30000">
        <deployment-directory auto-clean="false">/var/repose</deployment-directory>

        <artifact-directory check-interval="60000">/usr/share/repose/filters</artifact-directory>

        <logging-configuration href="log4j.properties"/>

    </deployment-config>
</repose-container>{% endcodeblock %}

Save the changes to the file. The final file to modify is the following:

**system-model.cfg.xml**

{% codeblock lang:xml %}<?xml version="1.0" encoding="UTF-8"?>

<system-model xmlns="http://docs.rackspacecloud.com/repose/system-model/v2.0">
  <repose-cluster id="repose">
    <nodes>
      <node id="node1" hostname="localhost" http-port="8888"/>
    </nodes>
    <filters>
      <!--
      <filter name="header-id-mapping" />
      -->
      <filter name="ip-identity" />
      <filter name="rate-limiting" />
      <filter name="http-logging" />
      <filter name="default-router"/>
    </filters>
    <destinations>
      <endpoint id="openrepose" protocol="http" hostname="localhost" root-path="/" port="8080" default="true"/>
    </destinations>
  </repose-cluster>
</system-model>{% endcodeblock %}

This file is used to enable the filters that we want to use and to define the
order in which they should be called. It also sets the endpoint which I pointed
back to our Node.js API server running on port 8080. Repose runs on port 8888,
but, in a real-world environment, you would probably be using port 80 for Repose.

**Note:** Repose requires [Java](http://www.oracle.com/technetwork/java/index.html) so make sure you have it installed.

Issue the following command to make Repose listen on port 8888 (which is
configured to proxy to the Node.js API server on port 8080):

    $ java -jar valve-2.3.5.jar start -p 8888 -s 8188 -c /etc/repose/


Port 8188 is the port Repose listens on for a shutdown command. In a production
environment, you should make sure to disable access to port 8188 from outside
networks. The shutdown command can be triggered with a simple HTTP GET to this
address: [http://localhost:8188/](http://localhost:8188/) The final argument
tells Repose to look in the **/etc/repose/** folder for the configuration files.

If it's not already running, go back to the Node.js app and start it.

Using a web browser, make a request to the API server to get the time. Try it out:

[http://localhost:8888/api/getdate](http://localhost:8888/api/getdate)

If you hit refresh a second time within a minute, you should get a message back
that looks similar to the following:

    {
        "overLimit" : {
            "code" : 413,
            "message" : "OverLimit Retry...",
            "details" : "Error Details...",
    	    "retryAfter" : "2012-10-10T21:21:31Z"
        }
    }

Now, go ahead and modify the rate limiting file to accept 10 requests per second.

**rate-limiting.cfg.xml**

{% codeblock lang:xml %}<?xml version="1.0" encoding="UTF-8"?>

<rate-limiting delegation="false" xmlns="http://docs.rackspacecloud.com/repose/rate-limiting/v1.0">
    <!--
        Defining a limit group.

        The following headers can be found in the class
        com.rackspace.cloud.powerapi.http.PowerApiHeader in the Power API
        Filterlet library, maven group id com.rackspace.cloud.powerapi, artifact
        id filterlet.

        Groups are matched on the HTTP header: X-PP-Groups
        User information is matched on the HTTP header: X-PP-User
    -->
    <limit-group id="standard-ip-limits" groups="IP_Standard">
        <limit uri="/*" uri-regex="/(.*)" http-methods="GET" unit="SECOND" value="10" />
    </limit-group>

    <limit-group id="standard-ip-limits-superuser" groups="IP_Super">
        <limit uri="/*" uri-regex="/(.*)" http-methods="GET" unit="SECOND" value="5" />
    </limit-group>
</rate-limiting>{% endcodeblock %}

You should be able to hit the API 10 times per second now.

When you are finished with your experiment, shut Repose down by hitting the
following URL:

[http://localhost:8188/](http://localhost:8188/)

Rate limiting is only one small piece of what Repose can do. To learn more about
Repose, the [Open Repose](http://openrepose.org/) website is your starting point
providing links to the [source code](https://github.com/rackerlabs/repose) in
GitHub. This is also the right place to find our
[documentation](http://openrepose.org/documentation.html), including a
[FAQ](http://wiki.openrepose.org/display/REPOSE/FAQ) and
[wiki](http://wiki.openrepose.org/display/REPOSE/Home. The wiki has the most
current information. If you have ideas about how Repose can grow to suit your
needs, you are welcome to
[contribute back](http://wiki.openrepose.org/display/REPOSE/Contributing+to+the+Repose+Project)
to this project.

Repose is available as open source under the [Apache License version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html).
