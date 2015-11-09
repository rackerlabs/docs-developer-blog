---
layout: post
title: "Getting started with Hadoop using Hortonworks Sandbox"
date: 2013-04-25 8:00
comments: true
author: Sudarshan Acharya
published: true
categories:
- Big Data
- Hadoop
---
{% img right 2013-04-25-getting-started-with-hadoop/hortonworks.jpg 200 200 %}

Getting started with a distributed system like Hadoop can be a daunting task for developers.From installing and configuring Hadoop to learning the basics of MapReduce and other add-on tools, the learning curve is pretty high.

<!-- more -->

Hortonworks recently released the Hortonworks Sandbox for anyone interested in learning and evaluating enterprise Hadoop.

The Hortonworks Sandbox provides:

1.	A virtual machine with Hadoop preconfigured.
2.	A set of hands-on tutorials to get you started with Hadoop.
3.	An environment to help you explore related projects in the Hadoop ecosystem like Apache Pig, Apache Hive, Apache HCatalog and Apache HBase.

You can download the Sandbox from Hortonworks website:

[http://hortonworks.com/products/hortonworks-sandbox/](http://hortonworks.com/products/hortonworks-sandbox/)

The Sandbox download is available for both VirtualBox and VMware Fusion/Player environments. Just follow the instruction to import the Sandbox into your environment.

The download is an OVA (open virtual appliance), which is really a TAR file.

```
tar -xvf Hortonworks+Sandbox+1.2+1-21-2012-1+vmware.ova
```

Untar it and the archive consists of an OVF (Open Virtualization Format) descriptor file, a manifest file and a disk image of vmdk format.

Rackspace Cloud doesn’t let you upload your own images, but if you have an OpenStack based cloud, you can boot a virtual machine with the image provided.

First, you can convert the vmdk image to a more familiar format like qcow2.

```
qemu-img convert –c -O qcow2 Hortonworks_Sandbox_1.2_1-21-2012-1_vmware-disk1.vmdk hadoop-sandbox.qcow2

file hadoop-sandbox.qcow2
hadoop-sandbox.qcow2: QEMU QCOW Image (v2), 17179869184 bytes
```

Now, let’s upload the image to Glance.

```
glance add name="hadoop-sandbox" is_public=true container_format=bare disk_format=qcow2 < /path/to/hadoop-sandbox.qcow2
```

Now let’s create a virtual server off of the new image - give at least 4GB of RAM.

```
nova boot --flavor $flavor_id --image $image_id hadoop-sandbox
```

Once the instance goes to ACTIVE status and that the instance pings, you can ssh into the instance using

* Username: root
* Password: hadoop

Watch `/var/log/boot.log` as the services are coming up, and it will let you know when the installation is complete. This can take about 10 minutes.

At the end, you should have these java processes running:

```
jps
2912 TaskTracker
2336 DataNode
2475 SecondaryNameNode
3343 HRegionServer
2813 JobHistoryServer
2142 NameNode
3012 QuorumPeerMain
4215 RunJar
4591 Jps
3568 RunJar
3589 RunJar
1559 Bootstrap
2603 JobTracker
3857 RunJar
```

Go to the browser at http://instance_ip and your single node Hadoop cluster should be running. Just follow through the UI; it has demos, videos and step-by-step hands-on tutorials on Hadoop, Pig, Hive and HCatalog.
