---
layout: post
title: Building an in-house analytics collector with nginx
date: '2013-09-09 09:09'
comments: true
author: Gabriel Preda
published: true
categories: []
---
There is a bigger need of web analytics out there than any single provider can offer (pun intended). Our in-house analytics system was tightly coupled into our web application because it grew along with it. It was about time we decoupled the analytics system.

We needed something very...

 * simple to build and understand in a way that our [bus factor](https://en.wikipedia.org/wiki/Bus_factor) does not decrease;
 * powerful because the load is not constant as it ranges from 60 to over 800 requests / second and we're constantly beating our records;
 * reliable because our billing system is based on it and any information loss would mean more disappointed clients (and less money for us).

Nginx to the rescue!<!-- more -->
======================

Collector setup
---------------

We've started a new server in Rackspace with just Nginx installed. To keep the costs low this is just a 512 MB RAM machine. As of version 0.3.10 Nginx has a built-in [Empty GIF Module](https://wiki.nginx.org/HttpEmptyGifModule). This module keeps an 1x1 transparent GIF image in memory for faster serving. Setup is very simple:

```
location = /track/me.gif
{
    empty_gif;
}
```

Another cool module in Nginx that we are using is the geolocation module called [GeoIP](https://wiki.nginx.org/HttpGeoipModule). It uses the "C library for country/city to IP address mapping". (We are using CentOS so this is available from epel repository where it is called geoip-geolite or GeoIP.) To use it you have to load the files in Nginx:

```
geoip_country  /usr/share/GeoIP/GeoIP.dat;       # the country IP database
geoip_city     /usr/share/GeoIP/GeoLiteCity.dat; # the city IP database
```
The above lines gives us some extra variables to use in nginx.conf.

*Note:* paths may vary, as I wrote before we (only) use CentOS. Also if you need to identify only the country of the visitor the first line would be enough.

New log format
--------------
We defined a new log formats that suits our requirements. The first log format will be called *analytics* and it will record data that will be parsed by the [ETL](https://en.wikipedia.org/wiki/Extract,_transform,_load) process. We will need to record:
```
 * the date & time: $time_iso8601
 * remote address:	$remote_addr
 * referer:			$http_referer
 * user agent:		$http_user_agent
 * country code:	$geoip_country_code
 * region:			$geoip_region
 * city:			$geoip_city
 * latitude:		$geoip_latitude
 * longitude:		$geoip_longitude
 * query string:	$query_string
```
Config lines are:
```
log_format analytics '$time_iso8601»$remote_addr»$http_x_forwarded_for»'
	'$http_referer»$http_user_agent»'
'$geoip_country_code»$geoip_region»$geoip_city»$geoip_latitude»$geoip_longitude»'
	‘$query_string';
```
We used » as a separator. The fixed part are all variables before *$query_string*. The dynamic part is the *$query_string* which will contain all the characters after the "?" in the http request. In this field the important analytics data will be kept.

We also use a *server_performance* log to keep track of some extra internal numbers:
```
log_format server_performance '$time_iso8601»$status»'
	'$remote_addr»$geoip_country_code»'
	'$request_time»$request_length';
```
Of course the most important indicator for us in the above log is *$request_time* which tells the time it took nginx to work on the request in seconds (with millisecond precision).

Now let's see all of the above together:
```
.........
http
{
.........
geoip_country  /usr/share/GeoIP/GeoIP.dat;       # the country IP database
geoip_city     /usr/share/GeoIP/GeoLiteCity.dat; # the city IP database

log_format analytics '$time_iso8601»$remote_addr»'
    '$http_referer»$http_user_agent»'
'$geoip_country_code»$geoip_region»$geoip_city»$geoip_latitude»$geoip_longitude»'
	‘$query_string';

log_format server_performance '$time_iso8601»$status»'
	'$remote_addr»$geoip_country_code»'
	'$request_time»$request_length';
.........

server
{
.........
location = /track/me.gif
{
    empty_gif;
    log_not_found  off;
    access_log  /var/log/nginx/events.access.log analytics;
    access_log  /var/log/nginx/srv-performance.access.log server_performance;
}
.........
}
.........
}
```

Almost... logrotate
-------------------
Logrotate is a great tool but we needed a finer granularity in rotating the logs. We decided that data as fresh as 20 minutes is enough for our business to call it "**real time**". Allowing 10 minutes for number crunching (and all other tasks: transfer from collecting machine to the ETL machine, the ETL process and finally the transfer of the computed results to the web facing database) we were left with a 10 minutes collection interval. So every 10 minutes a bash script moves away the nginx logs and sends a signal to the server to reopen it's logs.

```
#!/bin/bash
#
# Run every 10 minutes...
# */10 * * * * /path/to/rotate-logs.sh
#
DEST_EVNT="/events";
DEST_PERF="/server-performance";

SOURCE_EVNT="/var/log/nginx/events.access.log";
SOURCE_PERF="/var/log/nginx/srv-performance.access.log";

PREFIX_EVNT="events-";
PREFIX_PERF="srv-perf-";

############### Script code
PREFIX_EVNT="${PREFIX_EVNT}`date --date='10 minutes ago' +%Y%m%d-%H%M`";
PREFIX_PERF="${PREFIX_PERF}`date --date='10 minutes ago' +%Y%m%d-%H%M`";

PIGZ=`which pigz`;
HOSTID=$($(which hostid));
HOSTNAME=$($(which hostname));
SUDO=`which sudo`;

FILE_EVNT="$DEST_EVNT/${PREFIX_EVNT}_$HOSTID_${HOSTNAME}_0";
FILE_PERF="$DEST_PERF/${PREFIX_PERF}_$HOSTID_${HOSTNAME}_0";

mv $SOURCE_EVNT $FILE_EVNT;
mv $SOURCE_PERF $FILE_PERF;

# pkill -USR1 nginx -U 0; # Found a more elegant solution...
$SUDO /etc/init.d/nginx reopen_logs > /dev/null

sleep 2;

$PIGZ --best --processes 3 --no-time $FILE_EVNT;
$PIGZ --best --processes 3 --no-time $FILE_PERF;
```

This is not a big/fancy script... it's pretty straightforward. A bunch of conventions on the name of the file (string prefix, date component, hostid and hostname), two calls to move files from source to destination and a signal to Nginx to reopen the logs (also you can see the old version of how we did things - mostly is the same thing that reopen_logs does) - which it recreates because they're not there anymore. Then wait 2 seconds for things to calm down and compress the logs.

*Note:* beware that timing is not perfect... until Nginx reopens it's logs data is still written to the old logs. Let's say at 11:00 the bash script runs to rotate the log data collected from 10:50 until 11:00. Because the reopen log signal is sent just after 11:00 Nginx will write some lines for the first minute of hour 11. Depending on your load it can be a few lines or it may be thousands of lines.

Going wild... ...or HA!
-------------------
You can extend this setup to make sure it's **highly available**. (For the moment) we have two collector servers that are not facing the web directly but exposed through HaProxy machines (that has some other duties as well). We can add as many collectors we want and because they push data to the ETL machine (rather than having the ETL machine to pull data from collectors) everything will work from the moment they are up & running.

If you're interested in doing this you may want to load an additional module in Nginx: [Real IP](https://wiki.nginx.org/HttpRealipModule) (available since version 0.3.8). This module replaces the internal ip with the one from a given header. HaProxy sends the requests to Nginx servers through Rackspace ServiceNet so we won't get billed for this traffic. Setup for Nginx is quite straightforward and you can put it in http, server or even location section of the config:

```
set_real_ip_from   10.yy.xx.zz;    # HaProxy 1 ServiceNet address
set_real_ip_from   10.ab.cd.ef;	# HaProxy 2 ServiceNet address
real_ip_header     X-Forwarded-For;	# We’re certain that the good IP will be in this header
```

Of course the HaProxy machine is not alone. There are two HaProxy machines that are load balanced through DNS. The DNS server checks the availability of HaProxy machines and if any of them are down it's taken out. It is not a perfect solution but it's a good solution for us.

And yes... all of them are managed by [Puppet](https://puppetlabs.com/puppet/puppet-open-source).

Bonus: in house GeoLocation
===========================

For an inside feature we needed to identify the position of the visitor when he entered the page then use that info to customize his experience. After some considerations we found out that we already had the tools in place... we just needed to tweak a few things.

Yes we put the collectors to a little more work!
------------------------------------------------
We've setup a new location in nginx that looked something like this:

```
location /can/you/find/me.html
{
    root   /our/awesome/geo/finder;
    index  it-the-geo-finder.html;
    ssi on;
    ssi_silent_errors on;
}
```

The above activates *ssi* (server side includes) on the given location... so all calls to https://some-hostname.example.com/can/you/find/me.html will be serverd a special server generated file... the it-the-geo-finder.html.
Remember the geolocation variables from the log format definition? Well those can be used in *ssi* files. Here is how it looks:

```
[v@collector-0 ~]# cat /our/awesome/geo/finder/it-the-geo-finder.html
{
"country_code":"<!--# echo var="geoip_city_country_code" default="NULL" -->",
"country_code3":"<!--# echo var="geoip_city_country_code3" default="NULL" -->",
"country_name":"<!--# echo var="geoip_city_country_name" default="NULL" -->",
"region":"<!--# echo var="geoip_region" default="NULL" -->",
"city":"<!--# echo var="geoip_city" default="NULL" -->",
"continent_code":"<!--# echo var="geoip_city_continent_code" default="NULL" -->",
"latitude":"<!--# echo var="geoip_latitude" default="NULL" -->",
"longitude":"<!--# echo var="geoip_longitude" default="NULL" -->"
}
```
I’m sure most of the readers already know what is going to happen. As for the rest here is a result:
```
{
"country_code":"US",
"country_code3":"USA",
"country_name":"United States",
...
"latitude":"38.0000",
"longitude":"-97.0000"
}
```

We were actually in the mountains when I set this up and it took me about 10-15 minutes... mostly because of a bad Internet connection.

Conclusions
-----------
How much data are we talking here? Well on a monthly basis we're around 60G of compressed raw log files... that end up in databases (after ETL) as (again) 60G in compressed MariaDB tables (we use the Archive storage engine). The uncompressed InnoDB tables are *a little* bigger... some months ending up at a whopping 300G.

Overall we're using two machines with 512 MB RAM for collectors and two 512 MB RAM for balancers but, again, balancers are not only there for the analytics. If we were to consider the cost of the balancer in the *analytics system* the *collection phase* of the analytics would end up at: $21.90/mo * ( 2 + 2 ) = $87.60/mo (servers only).

We hope this article could be a starting point for anyone trying to build an in house analytics collector.

###About the Author
This is a guest post from Gabriel Preda from [Brainient](https://brainient.com), a Rackspace customer since 2011.

[Brainient](https://brainient.com) offers a cross-device interactive video platform that enables brands, advertisers, publishers and networks to create, deliver and measure interactive video campaigns across a multitude of platforms and devices. Our platform enhances video campaigns, increases dwell time, drives engagement and generates conversions. We work with all VPAID / MRAID / ORMMA compatible video players while delivering on: desktops, smartphones, tablets and connected TVs. Customers can see how their interactive campaigns are performing by accessing our web-based real-time analytics dashboard where anyone can track impressions, CTR, engagement rates, dwell time and more metrics.

Gabriel has over 10 years experience in developing web-applications. In 2008 he became a Certified MySQL Associate and a Zend Certified Engineer. His first work was within NGO which allowed him to do research more than 50% of the time. Over a year ago he joined the amazing team at [Brainient](https://brainient.com) where he has been working on the real time analytics system for their cross-device interactive video platform and "DevOps". Although he is the father of a waggish boy which fills (almost) all of his spare time, he still finds some time to "preach" Fedora for desktops and start a local [MariaDB](https://mariadb.org) User Group.