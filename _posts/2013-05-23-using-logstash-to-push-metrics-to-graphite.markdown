---
layout: post
title: Using logstash to Push Metrics to Graphite
date: '2013-05-23 8:00'
comments: true
author: Erik Redding
published: true
categories: []
---
{% img right 2013-05-23-logstash/data-visualization-logo.png 200 %}
One of the cool things we do on the [Cloud Databases](https://www.rackspace.com/cloud/databases/) operations side of the house is come up with statistics that can help us gain insight to hardware performance to identify issues with systems. We use some really cool tools, but one of the most versatile tools we work with is [logstash](https://www.logstash.net/). The goal of this article is to get you started pushing metrics with logstash that you may already collect to [Graphite](https://graphite.wikidot.com/). Along the way, I'll be showing you how to get started with logstash, test your configuration locally and then start pushing your first metrics to Graphite with some different examples along the way.<!-- more -->

* Openjdk or a form of modern java installed
* Sysstat package installed
* A functional Graphite installation

In this tutorial, our carbon cache listening endpoint for Graphite is 10.10.10.10:2003. For help installing Graphite, see the links section below. Our host running logstash is going to be named "MYHOST." We were collecting system statistics with Sysstat and we decided to leverage the fact that we already have metrics being collected.

To get started using logstash, you'll want to start by grabbing the monolithic jar file:

<https://logstash.objects.dreamhost.com/release/logstash-1.1.9-monolithic.jar>

This contains the logstash code and all the plugins provided by the base logstash configuration. You can extend logstash with Ruby plugins too, but we'll cover that some other time. The logstash configuration has three possible sections: input, filter and output. Here, we'll explore input types exec; filter types split and grok; and the Graphite output filter.  

Back in the early logstash days, I got started testing my configuration by making a wrapper script. As it turns out, this was very similar to the guide to getting started with logstash that you'll find in the links section at the bottom of this post, but they cover far more functionality that we're not concerned with. So with that said, this is the abbreviated version of that getting started guide, but with a wrapper script for testing; it reduces typing and ensures repeatability.

First, let’s set up our logstash environment. Let’s create a directory called "logstash" in /opt, download the monolithic jar, and create a couple of files that help with the testing. To the code!

```bash
mkdir -p /opt/logstash/{conf,bin}
pushd /opt/logstash/bin
curl -O 
https://logstash.objects.dreamhost.com/release/logstash-1.1.9-monolithic.jar

cat <<EOFSMPL > /opt/logstash/conf/simple.conf
input { stdin { type => "stdin-type"}}
output { stdout { debug => true }}
EOFSMPL

# escape your $’s:
cat <<EOFBIN > /opt/logstash/bin/logstash.sh
#!/bin/bash
conf=/opt/logstash/conf/simple.conf
lsjar=/opt/logstash/bin/logstash-1.1.9-monolithic.jar
myjava=\$(which java)
if [ -z \$myjava ]; then
  echo "java is required; please install openjdk or jre"
  exit 1
fi
# spawn logstash
\$myjava -jar \$lsjar agent -f \$conf
EOFBIN
chmod +x /opt/logstash/bin/logstash.sh
```

Now, to get started running our sample config, we will type some random stuff into the terminal. The monlithic jar takes a while to get started, so be patient!

```bash
$ /opt/logstash/logstash.sh
test!
{"@source":"stdin://MYHOST/","@tags":[],"@fields":{},"@timestamp":"2013-03-
29T18:13:01.601Z","@source_host":"MYHOST","@source_path":"/","@message":"te
st!","@type":"stdin-type"}
```

As you can see, logstash output some structured data; @ symbols indicate variables such as source, timestamp, tags, type and message.

In our next example, we'll grab the load average on a Linux system. Let’s edit our simple.conf file with this configuration:

```
input {
  exec {
    type => "system-loadavg"
    command => "cat /proc/loadavg | awk '{print $1,$2,$3}'"
    interval => 30
  }
}
filter {
  grok {
    type => "system-loadavg"
    pattern => "%{NUMBER:load_avg_1m} %{NUMBER:load_avg_5m}
%{NUMBER:load_avg_15m}"
    named_captures_only => true
  }
}
output {
  stdout { debug => true debug_format => "json" }
}
```

Since extra GNU utility calls are cheap and executed in the same subshell, we can manipulate any output into something we can easily push through logstash. Here, we only output the load average stats found in /proc/loadavg with the awk statement. Note: in our input section we set a logstash "type" which sets the @type variable. The logstash type and tag fields let you target specific sets of data with your filter and output sections. Next, the grok filter plugin is used to describe common patterns in unstructured data using the "%{SYNTAX:SEMANTIC}" form. The “syntax” is the type of data you're grabbing (ex: NUMBER, INT, WORD) and “semantic” is the name of the field. The named_captures_only parameter makes the grok plugin only store the items we specified to capture instead of any extra items that grok may naturally collect. Grok is ultra powerful and shines when you're pulling data from logs, however, in this case we're using it to grab our one-minute, five-minute and 15-minute load averages.
 
Let’s run it with the new config; hit CTRL+C to break out of the shell script and stop running logstash:

```bash
$ ./logstash.sh 
{"@source":"exec://MYHOST/","@tags":[],"@fields":{"command":"cat
/proc/loadavg | awk '{print
$1,$2,$3}'","load_avg_1m":["0.35"],"load_avg_5m":["0.19"],"load_avg_15m":["
0.07"]},"@timestamp":"2013-04-01T16:03:44.738Z","@source_host":"MYHOST","@s
ource_path":"/","@message":"0.35 0.19 0.07\n","@type":"system-loadavg"}
^CSIGINT received, shutting down. {:level=>:warn}
```

We can see that the fields variable has some key things - I'm prettying up the output:

```
"@fields":{
 "command":"cat /proc/loadavg | awk '{print $1,$2,$3}'",
 "load_avg_1m":["0.35"],
 "load_avg_5m":["0.19"],
 "load_avg_15m":["0.07"]
},
```

There are four fields captured: command, load_avg_1m, load_avg_5m, load_avg_15m. Each one of them has a value assigned to it and these are the metrics we'll push to Graphite.

With this example, we're tweaking the output section to hit Graphite now that we see how the data is being rendered with logstash.

```
input {
  exec {
    type => "system-loadavg"
    command => "cat /proc/loadavg | awk '{print $1,$2,$3}'"
    interval => 30
  }
}
filter {
  grok {
    type => "system-loadavg"
    pattern => "%{NUMBER:load_avg_1m} %{NUMBER:load_avg_5m}
%{NUMBER:load_avg_15m}"
    named_captures_only => true
  }
}
output {
  graphite {
    host => "10.10.10.10"
    port => 2003
    type => "system-loadavg"
    metrics => [ "hosts.%{@source_host}.load_avg.1m", "%{load_avg_1m}",
"hosts.%{@source_host}.load_avg.5m", "%{load_avg_5m}",
"hosts.%{@source_host}.load_avg.15m", "%{load_avg_15m}" ]
  }
}
```

The example config file is exactly the same as before with the exception of the output filter; now it's pushing data to our Graphite endpoint. We're grabbing the "system-loadavg" type, and we are creating an array of metrics. We use a built-in variable @source_host set by logstash to set up the Graphite metric scope for this particular host - notice that we're only setting the metric scope and value. Then logstash will use the @timestamp when it pushes out each metric pair to Graphite. Assuming your Graphite install is functional, we could then pull data from our URL: https://10.10.10.10:9000/render/?target=hosts.MYHOST.load_avg.1m

Some of the tools we use for system metrics are sar and sysstat. We track things like disk performance and network performance. Here's and example configuration file that logs network statistics from sar:

```
input {
  exec {
    type => "system-netstats"
    command => "sar -n DEV 10 1 | sed '1,3d' | grep -v 'Average' | sed
'$d' | awk '{print $3,$4,$5,$6,$7,$8,$9,$10,$11}'"
    interval => 30
  }
}
filter {
  split {
    type => "system-netstats"
  }
  grok {
    type => "system-netstats"
    pattern => "%{DATA:iface} %{NUMBER:rxpck_s} %{NUMBER:txpck_s}
%{NUMBER:rxkb_s} %{NUMBER:txkb_s} %{NUMBER:rxcmp_s} %{NUMBER:txcmp_s}
%{NUMBER:rxmcst_s}"
    named_captures_only => true
  }
}
output {
  graphite {
    host => "10.10.10.10"
    port => 2003
    type => "system-netstats"
    metrics => [ 
"hosts.%{@source_host}.netstats.interfaces.%{iface}.rxpck_s",
"%{rxpck_s}", 
"hosts.%{@source_host}.netstats.interfaces.%{iface}.txpck_s",
"%{txpck_s}", "hosts.%{@source_host}.netstats.interfaces.%{iface}.rxkb_s",
"%{rxkb_s}", "hosts.%{@source_host}.netstats.interfaces.%{iface}.txkb_s",
"%{txkb_s}", "hosts.%{@source_host}.netstats.interfaces.%{iface}.rxcmp_s",
"%{rxcmp_s}", 
"hosts.%{@source_host}.netstats.interfaces.%{iface}.txcmp_s",
"%{txcmp_s}", 
"hosts.%{@source_host}.netstats.interfaces.%{iface}.rxmcst_s",
"%{rxmcst_s}" ]
  }
}
```

The input section is the same concept as before but we're running a sar report and pruning the extra stuff like column headers. The filter section first passes our system-netstats through the split filter – this splits common multiline data and hands each line through the logstash data pipeline individually. The grok filter is then used to name each field in the input, and the output section creates an array of scope and value data pairs for our graphite endpoint. We can pull one of the stats collected for device eth0 with the URL: https://10.10.10.10:9000/render/?target=hosts.MYHOST.netstats.interfaces.eth0.rxpck_s


As you can see, logstash has some great functionality that allows us to grab data and pass it on to Graphite. Using GNU utilities, you can leverage existing data collection through daemons such as sysstat and start collecting some great statistics and generate graphs with Graphite.

Installing Graphite: <https://graphite.wikidot.com/installation>
Logstash Getting Started: <https://logstash.net/docs/1.1.9/tutorials/getting-started-simple>
Logstash Command Line Arguments: <https://logstash.net/docs/1.1.9/flags>
Logstash configuration file details: <https://logstash.net/docs/1.1.9/configuration>
Grok Plugin for Logstash: <https://logstash.net/docs/1.1.9/filters/grok>
Grok Patterns: <https://github.com/logstash/logstash/blob/v1.1.9/patterns/grok-patterns>

_Erik Redding works at Rackspace as a Linux System Engineer for Cloud Databases_
