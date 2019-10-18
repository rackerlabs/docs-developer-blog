---
layout: post
title: 'Welcome to Performance Cloud Servers; have some benchmarks!'
date: '2013-11-05 06:00'
comments: true
author: Jesse Noller
published: true
categories:
  - cloud servers
---

{% img right 2013-11-04-welcome-to-performance-cloud-servers/brace-yourselves.png 200 %}

Today, all of us at Rackspace are proud to roll out our new Performance Cloud Server offering. These are new flavors of Cloud Servers available to all customers as of today, providing higher performance from RAM to Disk I/O, and more. We've also rolled out a significant update to our [cloud control panel](http://mycloud.rackspace.com) to greatly improve the user experience of selecting flavors, operating systems and more.

Our Cloud Servers have been completely re-engineered from the ground up to deliver performance and reliability.  They are built entirely with RAID 10 protected SSDs and powerful Intel Xeon processors.  40 gigabits per second of highly available network throughput is delivered to **every** host, enabling high bandwidth applications and blazing fast Cloud Block Storage performance.  All hosts have dual power feeds with redundant power supplies and are deployed in Rackspace’s world-class data centers.

But you, as developers, probably want to know more. A lot more. I've spent several weeks taking many of the new flavors for a spin, putting them through a variety of benchmarks and stress tests. I’m a developer though and pretty much any time a vendor – even a well meaning one – publishes benchmarks, I want to see the raw data, how to run them and most of all, how I can recreate them, so that's what I am doing - all raw results, plots, run scripts, etc are on [GitHub](https://github.com/rackerlabs/performance_cloud_benchmarks).

<!-- more -->

### So, what's the scoop?

Alright. So we've rolled out two new flavor classes of servers: Performance 1 and Performance 2:

{% img 2013-11-04-welcome-to-performance-cloud-servers/image2013-10-16_16_0_21.png 800 %}

Both flavor groups will eventually phase out our current Cloud Server offering. These are completely RAID 10 SSD backed, Intel(R) Xeon(R) E5-2670 2.60GHz based systems (up to 32 vCPUs!) with 10GE networking (every host receives 40Gbps of network capacity - that alone accounts for huge gains when using [Cloud Block Storage](https://developer.rackspace.com/blog/happy-birthday-cloud-block-storage.html)). In the chart above, you can see how many vCPUs you get with each image, and I can tell you - they fly.

> "As an application developer, nothing's better than a data layer that doesn't slow down my app" - [Jacob Kaplan-Moss](http://jacobian.org/)

#### Availability Note:

The Performance Cloud Servers are available now in our Northern Virginia (IAD) region. They will come online in our Dallas (DFW), Chicago (ORD), and London (LON) regions later in November. Our Sydney (SYD) and Hong Kong (HKG) regions will follow in the first half of 2014.

If you are using the **nova** command line client set the following:

```
OS_REGION_NAME=IAD
```

#### Performance 1 Flavor Class

The *Performance 1* flavor class has a shared (oversubscribed) CPU and network with a 1:1 ratio of RAM to CPU (peak burst) and are best suited for apps that can benefit from burst-style usage, including web servers, batch processing, network appliances, smaller databases, and most general purpose computing workloads. When you want to build a rapid horizontal scale-out web application, mobile back end, host your site etc - this flavor class is going to be your bread and butter.

We eliminated the lowest end flavor (512) and will start with the competitively priced the 1GB flavor, while drastically increasing its performance from the previous 1 GB offering (we have charts!). This means that the price per month for a 1GB instance is now $29.20/Month ($0.04/Hr). All together?  The performance you get for the new prices across all of the Performance Cloud Server flavors is amazingly competitive and a great improvement to the Rackspace portfolio.

Oh - and the $29.20/Month 1GB server... It's fits easily into the 50$/month [developer discount](https://developer.rackspace.com/devtrial/) (just saying).

#### Performance 2 Flavor Class

The *Performance 2* flavor class has a dedicated (non-oversubscribed) CPU and network with a 3.75:1 ratio of RAM to CPU. They have more maximum IOPS than *Performance 1* and are best suited for apps with higher I/O requirements and that demand sustained performance including larger relational and non-relational databases. Clusters, HPC work, data science - all of these fit into this category. Before today, we only offered flavors with up to 30GB of ram. Now we have 60, 90 and 120GB flavors for you to use for big data, big databases, all those "scale up and out" situations.


### What do I see?

If you fire up the new control panel on [mycloud.rackspace.com](http://mycloud.rackspace.com) you'll see a lot of changes. If you're like me, and like the command line and fire up the **nova** CLI tool and do:


{% img 2013-11-04-welcome-to-performance-cloud-servers/nova-show.png 800 %}


As you can see, the new flavors are labeled by name - not ID. These match the names you'll find exposed in the control panel, making the experience much more cohesive between the command line tools / API and the control panel itself. This means firing one of them up off the command line is as simple as:

```
nova boot perf1GB --flavor performance1-1 --image 62df001e-87ee-407c-b042-6f4e13f5d7e1 --poll
```

This will spin up a 1GB Ubuntu 13.04 system for you. Use "**nova show**" once it's complete to get the public facing IP address - oh, and save the root/admin password if you're not using the "**--key-name**" SSH key system. All of the new flavors work with all of our [tools and SDKs](https://developer.rackspace.com), and of course - **you can use the [developer discount](https://developer.rackspace.com/devtrial/) to try them out**!

### You promised us benchmarks!

Yes, yes I did. And I have them. But first:

> There are lies, damned lies, and then good sir - there are benchmarks. - Mark Twain

I’m a developer, and pretty much any time a vendor - even a well meaning one - publishes benchmarks, I want to know the methodology and I want access to the raw data. Most of all, **I want to be able to run the benchmarks myself**. All raw data, results, plots, etc are on [GitHub](https://github.com/rackerlabs/performance_cloud_benchmarks)

* All tests used stock, untuned *Ubuntu 13.04* images.
* Tests were done using open source tools and utilities.
* Again, all raw test data is located on [GitHub](https://github.com/rackerlabs/performance_cloud_benchmarks).
* Tests were performed for a series of 6 iterations each, and the average of the 6 runs is the final value.
* All servers were deployed using the "nova" command line client, no special sauce.
* Tests were performed with 3 servers of each type:
  * 1GB NextGen (Current Cloud Server)
  * 1GB Performance Cloud Server (**PV**)
  * 1GB Performance Cloud Server (**PV-HVM**)
  * 30GB NextGen (Current Cloud Server)
  * 30GB Performance Cloud Server (**PV**)
  * 30GB Performance Cloud Server (**PV-HVM**)

#### Wait, what?

{% img right 2013-11-04-welcome-to-performance-cloud-servers/dog-dude-wait-what.jpg 300 %}

Yeah, you're probably wondering what the **PV** and **PV-HVM** markers in that list are. As you probably know, Rackspace runs [OpenStack](http://www.openstack.org), and the key virtual machine component, Nova offers you a choice of [hypervisors](http://en.wikipedia.org/wiki/Hypervisor) to work with. Internally, our clusters use [Xen](http://www.xenproject.org/), an open source, scalable and powerful hypervisor. Hypervisors though are funny little animals - they actually operate within a [spectrum](http://wiki.xen.org/wiki/Virtualization_Spectrum), meaning you can virtualize some of the resources for guests, all, or some interesting mixture for your specific needs.

The basic terminology you need to know (quoting from the [xen wiki](http://wiki.xen.org/wiki/Virtualization_Spectrum)):

* [Paravirtualization (PV)](http://wiki.xen.org/wiki/Paravirtualization_(PV)): Paravirtualization (PV) is an efficient and lightweight virtualization technique introduced by Xen, later adopted by other virtualization solutions. PV does not require virtualization extensions from the host CPU and thus enables virtualization on hardware architectures that do not support Hardware-assisted virtualization. However, PV guests and control domains require kernel support and drivers that in the past required special kernel builds, but are now part of the Linux kernel as well as other operating systems.
* [PV on HVM (PV-HVM)](http://wiki.xen.org/wiki/PV_on_HVM): PV on HVM is a mixture of paravirtualization and full hardware virtualization. The primary goal of PV on HVM is to boost performance of fully virtualized HVM guests through use of specially optimized paravirtual device drivers (also called PVHVM or PV-on-HVM drivers).

You can also read more about the [PV-HVM Linux drivers](http://wiki.xen.org/wiki/Xen_Linux_PV_on_HVM_drivers)

So, terminology aside, today, when you boot any Linux image on Rackspace Cloud, that image uses standard paravirtualization (PV), for Windows and FreeBSD we use HVM. In the case of the new Performance Cloud Servers, we still default to PV images, and are currently testing PV on HVM images. PV-HVM images can be great for CPU-intensive workloads (as you'll see).

For these benchmarks - I tested all three styles - our current (well, as of yesterday) Next Gen Cloud Server (PV), Performance PV and Performance PV-HVM. We should be rolling out the PV-HVM images to customers as soon as our quality engineers are happy with their stability and functionality. As it is you **could** use them today (for Fedora 19 and Ubuntu) 13.04 using the **nova** client to pick one of the test images:

* Fedora 19 image ID: a12bf25c-e098-45bd-8a7b-b2ed89db250f
* Ubuntu 13.04 image ID: 62df001e-87ee-407c-b042-6f4e13f5d7e1

But be warned: they are not meant for production use *at this time*.

#### First up; Unixbench

* Code Used: [https://code.google.com/p/byte-unixbench/](https://code.google.com/p/byte-unixbench/), version 5.1.3.
* Test(s) run: standard "index" (**./Run**)
* Iterations: 6

Unixbench is pretty much a gold standard when putting a machine through the paces - it's tied to the original BYTE UNIX benchmark suite. The purpose of UnixBench is to provide a basic indicator of the performance of a Unix-like system; hence, multiple tests are used to test various aspects of the system's performance. These test results are then compared to the scores from a baseline system to produce an index value, which is generally easier to handle than the raw scores. The entire set of index values is then combined to make an overall index for the system.

On a single-CPU machine it runs once with one copy of each test program running at a time. On multi-CPU systems it runs the tests multiple CPUs, the default behavior is to run the selected tests twice -- once with one copy of each test program running at a time, and once with N copies, where N is the number of CPUs.

First up: the 1GB, 1 CPU Performance Cloud Server ([click here for full size](http://7c5dfdbb739dc73f99cb-b85bd20d3e627e59093de9f95b53ad56.r58.cf5.rackcdn.com/unixbench_1gb.png)):

{% img 2013-11-04-welcome-to-performance-cloud-servers/unixbench_1gb.png 900 %}

What this shows is the results for each of the subtests, and then the final score (far right). As stated before, the average of 6 runs was used.

* **1GB Next Gen (Current) 6 run average unixbench System Score**: 444 (baseline)
* **1GB Performance PV 6 run average unixbench System Score**: 560.1 (~29% higher than baseline)
* **1GB Performance PV-HVM 6 run average unixbench System Score**: 1568.45 (~347% higher than baseline)

From the chart you can see IO operations alone are stunningly better.

Next up: the 30GB, 8 CPU Performance Cloud Server, single process run ([click here for full size](http://7c5dfdbb739dc73f99cb-b85bd20d3e627e59093de9f95b53ad56.r58.cf5.rackcdn.com/unixbench_30gb_1proc.png)):

{% img 2013-11-04-welcome-to-performance-cloud-servers/unixbench_30gb_1proc.png 900 %}

* **30GB Next Gen (Current) 6 run average unixbench System Score**: 428.17 (baseline)
* **30GB Performance PV 6 run average unixbench System Score**: 515.3 (~31% higher than baseline)
* **30GB Performance PV-HVM 6 run average unixbench System Score**: 1591 (~376% higher than baseline)

And now the 30GB, 8 CPU Performance Cloud server, multiple process edition ([click here for full size](http://7c5dfdbb739dc73f99cb-b85bd20d3e627e59093de9f95b53ad56.r58.cf5.rackcdn.com/unixbench_30gb_8procs.png))

{% img 2013-11-04-welcome-to-performance-cloud-servers/unixbench_30gb_8procs.png 900 %}

* **30GB Next Gen (Current) 6 run average unixbench System Score**: 1546 (baseline)
* **30GB Performance PV 6 run average unixbench System Score**: 1974.24 (~29% higher than baseline)
* **30GB Performance PV-HVM 6 run average unixbench System Score**: 4876 (~260% higher than baseline)

They're pretty fast, I'd say - but you can look at the raw data and draw your own conclusions. Using the PV-HVM enabled Ubuntu image sees massive increases in the overall performance on both the 1GB and the 30GB Performance flavors.

#### Second up; fio

* Code Used: fio (from apt-get - fio_2.0.8-2)
* Test(s) run: **fio --name fio_test_file --direct=1 --rw=randwrite --bs=16k --size=1G --numjobs=16 --time_based --runtime=180 --group_reporting**
* Iterations: 6 (+1 for initial warmup)

So, fio is an I/O tool meant to be used both for benchmark and stress/hardware verification. It has support for 13 different types of I/O engines (sync, mmap, libaio, posixaio, SG v3, splice, null, network, syslet, guasi, solarisaio, and more), I/O priorities (for newer Linux kernels), rate I/O, forked or threaded jobs, and much more.

It spits out a lot of data, and sure - we could chart it but the results... Well, the charts look down right silly with an increase of almost 2000-5000% with IOPS jumping from 1-2k to 22k+. Just to show how silly, we charted just the IOPS across the 1GB and 30GB servers:

{% img 2013-11-04-welcome-to-performance-cloud-servers/fio_IOPS.png 900 %}

That little sliver of blue? He's not the new Performance Cloud Server.

That all said - the 1GB, 1 CPU Performance Cloud Server results ([click here for full size](http://7c5dfdbb739dc73f99cb-b85bd20d3e627e59093de9f95b53ad56.r58.cf5.rackcdn.com/fio_1gb.png)):

{% img 2013-11-04-welcome-to-performance-cloud-servers/fio_1gb.png 900 %}

As you can see - IOPS way up, latency way down - Aggregate bandwidth on a 1GB server? **Insanely high.** And almost uniformly a ~5000% increase over today's 1GB server.

Now for the 30GB, 8 CPU Performance Cloud Server results ([click here for full size](http://7c5dfdbb739dc73f99cb-b85bd20d3e627e59093de9f95b53ad56.r58.cf5.rackcdn.com/fio_30gb.png)):

{% img 2013-11-04-welcome-to-performance-cloud-servers/fio_30gb.png 900 %}

On the 30GB Performance Cloud servers we see a consistent ~1900-2000% increase over the original cloud server. That's a lot of IOPS. So many IOPS.

#### Third up; kernel compiles!

* Code Used: make, gcc
* Test(s) run: **time make -j$(cat /proc/cpuinfo | grep processor | wc -l)**
* Iterations: 6

The amusing part about this one - the kernel will kick in and execute your kernel compile on a 1GB server if you've left anything else running or have random things consuming the memory. Also, running this and the PyPy test (next) across 9+ servers in a single data center probably made someone watching a usage graph go "what the heck?!"

Results! ([click here for full size](http://7c5dfdbb739dc73f99cb-b85bd20d3e627e59093de9f95b53ad56.r58.cf5.rackcdn.com/kernel_compile.png))

{% img 2013-11-04-welcome-to-performance-cloud-servers/kernel_compile.png 900 %}

1GB High Performance spreadsheet breakdown ([click here for full size](http://7c5dfdbb739dc73f99cb-b85bd20d3e627e59093de9f95b53ad56.r58.cf5.rackcdn.com/kernel1gb.png)):

{% img 2013-11-04-welcome-to-performance-cloud-servers/kernel1gb.png 900 %}

About a ~25% increase from baseline on the PV-HVM image - this really stresses the CPU more than anything - and these are single CPU boxes with 1GB of ram. What we can see is given the same base constraints the new Performance Cloud Server consistently improve from our baseline comparison.

30GB High Performance spreadsheet breakdown ([click here for full size](http://7c5dfdbb739dc73f99cb-b85bd20d3e627e59093de9f95b53ad56.r58.cf5.rackcdn.com/kernel30gb.png)):

{% img 2013-11-04-welcome-to-performance-cloud-servers/kernel30gb.png 900 %}

We of course see an increase of ~20-42% here from baseline - better processors (but same number), better I/O, same amount of RAM - but again, painting the same overall improvement picture we've been seeing.

#### Finally; PyPy!

* Code Used: python, gcc, dark magic
* Test(s) run: **time python ../../rpython/bin/rpython -Ojit targetpypystandalone**
* Iterations: 6

Ok, so you won't see any 1GB flavor results here - [PyPy](http://pypy.org/) needs oodles of RAM to generate it's rpython system, translations - make a just in time compiler, etc. You're going to need several GB of ram to build it from scratch. I did exactly this - I even skipped the part about using a pre-built rpython binary to do the translation and used the good old CPython 2.7.4 to make it even more pokey. But hey, it takes hours and draws fractals on your screen and like the kernel and other benchmarks, running it in parallel across 9+ servers makes ops people make this face:

{% img center 2013-11-04-welcome-to-performance-cloud-servers/sadface.gif 400 %}

So, the graph ([click here for full size](http://7c5dfdbb739dc73f99cb-b85bd20d3e627e59093de9f95b53ad56.r58.cf5.rackcdn.com/kernel30gb.png)):

{% img 2013-11-04-welcome-to-performance-cloud-servers/pypy_translate.png 900 %}

And now the table ([click here for full size](http://7c5dfdbb739dc73f99cb-b85bd20d3e627e59093de9f95b53ad56.r58.cf5.rackcdn.com/pypy_build.png)):

{% img 2013-11-04-welcome-to-performance-cloud-servers/pypy_build.png 900 %}

Again, just as in the kernel compile test - we see ~20% increases from baseline on the compile speed (yes - PyPy naturally takes that long to compile/translate). The story is the same as before though, consistent improvement.

### Summary - and a call for more benchmark suggestions!

I've run you though a series of what I'd call **baseline** benchmarks - none of these really show off what one might call "real applications" though the benefits to real applications should be readily apparent. You've got a massively improved IO system, hot new Intel(R) Xeon(R) processors, more RAM options and oh - the boot times...

{% img 2013-11-04-welcome-to-performance-cloud-servers/boot-time.png 900 %}

Under a minute and a half to provision (from the command line) a 1GB Performance Cloud server. I don't know about you, but having fast boots from clean images, as well as all of the other goodies we've thrown into our completely OpenStack based offering is pretty exciting.

I'm looking forward to more posts about this new offering - we already have piles of crazy 3D charts from IOZone runs - but we'd love to hear what benchmarks **you** want to see run. Pick a language framework, pick a web framework, heck, pick a web server or entire application we can throw apachebench at with one of the 120GB monsters we have and we'll put it together (though - if you have a deployment script, that would be nice!) and we'll run it and push the results to [GitHub](https://github.com/rackerlabs/performance_cloud_benchmarks).

Things on the wish list:

* Phoronix Test Suite full run
* Nginix load test on 1GB servers
* Real Postgresql (pgbench) numbers (plus Postgres with stream replication)
* MongDB/Non-relational benchmarks
* Application level deployment/stress testing (nginix + gunicorn/etc + web framework of choice)

Actually, since we're on that topic - if you have corrections, or additions, or suggestions for us to add to all of this, please file an issue on the [GitHub repository](https://github.com/rackerlabs/performance_cloud_benchmarks) - all raw results, plotting scripts, etc is sitting right there, though my in progress fabric script to run them all didn't make the print deadline.

If you see something wrong? Let us know. All of these new flavors are fully operational with our complete range of [tools and SDKs](https://developer.rackspace.com). You can reach out to me ([Jesse Noller][1]) on [Twitter][2], [email the developer support team](mailto:sdk-support@rackspace.com), ping [@Rackspace](https://twitter.com/Rackspace) on Twitter, or even reach out to [help@rackspace.com](mailto:help@rackspace.com). Special thanks to the entire Rackspace team for making this possible, a special shout-out to [Brian Curtin](https://twitter.com/brian_curtin) for helping me get all the data put together into some semblance of sanity! Thanks to [plot.ly](http://plot.ly) for making graphing data simple and awesome!

I'm really looking forward to seeing what these new Performance Cloud Servers, a revitalized [Cloud Block Storage](https://developer.rackspace.com/blog/happy-birthday-cloud-block-storage.html), [OpenStack Heat](https://developer.rackspace.com/blog/openstack-heat-orchestration-coming-to-rackspace.html) orchestration, and [Cloud Queues](http://www.rackspace.com/blog/cloud-queues-available-now-to-all-cloud-customers/) will empower you, developers & hackers to dream up and build.

Remember - want to test drive? Go ahead and use the [developer discount](https://developer.rackspace.com/devtrial/) - we're here to build amazing things, on open technology and with an open community for you. I couldn't be more proud!

{% img center 2013-11-04-welcome-to-performance-cloud-servers/simba.gif 400 %}

[1]: http://jessenoller.com/
[2]: https://twitter.com/jessenoller
