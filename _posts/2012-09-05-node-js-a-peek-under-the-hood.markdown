---
comments: true
sharing: true
date: 2012-09-05T08:00:22.000Z
layout: post
title: node.js - a peek under the hood
author: Wayne Walls
categories:
  - Cloud Servers
  - jclouds
  - cloud files
  - java
---

Greetings, friends! Today I want to touch on a "fairly" new programming language, Node.js. In this case, "fairly new" means it was created in 2009. [Ryan Dahl](https://twitter.com/ryah) created Node.js because he desired the ability to make web sites with push capabilities like those seen in popular web applications like Gmail. So what is Node.js, exactly? Node.js is a framework for building networked applications in JavaScript outside of the browser. It leverages [V8](http://code.google.com/p/v8/), the super fast JavaScript engine by Google. JavaScript is a great fit for writing servers due to its event-driven nature. You not only benefit from the speed of V8, but most of the time, the Node.js/JavaScript paradigms make you write code that is fast by design.

<!-- more -->

As with any programming language there are pros and cons, so node.js is not going to solve all of your problems in one deployment. However, used appropriately and in the right situations, it can be a very powerful tool that will help you dominate. Developers choose Node.js today because:




  * It's fast. Powered by the incredible V8 virtual machine, it makes JavaScript execution extremely fast.


  * It's fast by design. Most of the applications we're writing today are heavily I/O bound. Because of the event-driven nature of JavaScript (and Node by extension), whatever you write with it is going to be very fast.


  * It's one platform to rule them all. Many web applications today already require JavaScript expertise to make the user experience more appealing and the application decent by modern standards (as an example, Facebook or the new Twitter are mostly driven by JavaScript for most interactions). Having the ability to write the backend services (and not just the web backend) in the same language is extremely attractive.


  * It's a great fit for the real-time web. Since you take control of the web server, Node.js is uniquely suited for the advance of the real-time web.


In this tutorial we will complete the Node.js "HelloWorld" exercise. I will use a CentOS 6.3 Cloud Server in the Rackspace DFW datacenter for this post.

For simplicity, let's start from scratch. For your convenience, if you have [rackspace-novaclient](http://devops.rackspace.com/getting-started-using-python-novaclient-to-manage-cloud-servers.html) or [supernova](https://github.com/rackerhacker/supernova) installed, use one of the following commands to boot a CentOS 6.3 Cloud Server:


    [dubsquared@localshake ~]$ nova boot --image c195ef3b-9195-4474-b6f7-16e5bd86acd0 --flavor 2 mastershake

-OR-

    [dubsquared@localshake ~]$ supernova dfw boot --image c195ef3b-9195-4474-b6f7-16e5bd86acd0 --flavor 2 mastershake


Once your server is ACTIVE; ssh into it and let's begin!


    dubsquared@localshake ~ > supernova dfw list
    +--------------------------------------+-------------+--------+---------------------+
    |                  ID                  |    Name     | Status |       Networks      |
    +--------------------------------------+------------ +--------+---------------------+
    | d3d11e0c-0517-48b1-b0ba-2bb989278772 | mastershake | ACTIVE | (snip)              |
    +--------------------------------------+-------------+--------+---------------------+

    dubsquared@localshake ~ > ssh root@$PUBLIC_IP_HERE
    root@$PUBLIC_IP_HERE's password:
    Last login: Mon Sep  3 03:32:53 2012 from Texas


You can do this exercise as the "root" user, but I have created a new local user "dubsquared" that I will use here.

The first thing you need to do is download a few build packages so node will compile:


    [dubsquared@mastershake ~]$ yum -y install gcc make gcc-c++ screen


When the download and installation are complete, create a directory for node. Here, we will use "node-v0.8.8" as it's the current latest stable release:


    [dubsquared@mastershake ~]$ mkdir /node && cd /node
    [dubsquared@mastershake ~]$ wget http://nodejs.org/dist/v0.8.8/node-v0.8.8.tar.gz
    [dubsquared@mastershake ~]$ tar -zxvf node-v0.8.8.tar.gz && cd node-v0.8.8/


With node downloaded and unpacked, all that is left to do is compile:


    [dubsquared@mastershake ~]$ ./configure
    [dubsquared@mastershake ~]$ make
    [dubsquared@mastershake ~]$ make install


For all intents and purposes the "install" is done, now there's just a bit of configuration left to do. Using your favorite editor, create "helloworld.js" as the node configuration file:

_Sample helloworld.js_

{% codeblock lang:bash %}
var http = require('http');
http.createServer(function (req, res) {
res.writeHead(200, {'Content-Type': 'text/plain'});
res.end('Hello World!\n');
}).listen(8124, "$PUBLIC_IP_HERE");
console.log('Server running at http://$PUBLIC_IP_HERE:8124/');
{% endcodeblock %}

You can get your public IP address using "ifconfig eth0" or by checking in the Rackspace Cloud Control Panel

With helloworld.js configured, we are now ready to fire up the server. You can execute node scripts simply by putting "node" at the start of the script like most other programming languages that use their name as the executor:


    [dubsquared@mastershake ~]# node helloworld.js
    "Server running at http://$PUBLIC_IP_HERE:8124/"


If you wanted to start your program in the background, you would append an ampersand (&) to the end of the command above. For this example, we'll go ahead and background the process by pressing CTRL-Z, then entering "bg" into the terminal:


    [dubsquared@mastershake ~]$ node helloworld.js
    Server running at http://$PUBLIC_IP_HERE:8124/
    ^Z
    [1]+  Stopped                 node helloworld.js
    [dubsquared@mastershake ~]$ bg
    [1]+ node helloworld.js &


Now that you are back to your terminal, let's make sure our node server is running as expected:


    [dubsquared@mastershake ~]$ netstat -tlpn | grep node
    tcp 0 0 $PUBLIC_IP_HERE:8124 0.0.0.0:* LISTEN 24950/node


Now for the pay off -- there are two easy ways to check your work. First, use a tried and true command line utility cURL:


    [dubsquared@mastershake ~]$ curl $YOUR_PUBLIC_IP:8124
    Hello World!


Alternatively, you could browse to `$YOUR_PUBLIC_IP:8124` via your favorite browser and see the output as well!

Node.js is gaining popularity and its adoption is growing everyday. This was intended to be a beginner's primer to help you get your feet wet so in coming weeks you will be ready to dive into some deeper water. One of the areas with a lot of buzz is node + mongoDB; so in coming weeks expect to see a post in which we use node, socket.io and mongo plug-ins and start to put together a simple application framework that you can use to start building live web applications!
