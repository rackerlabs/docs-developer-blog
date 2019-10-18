---
layout: post
title: 'Can you really run a fault-tolerant, high-performance, scale-out SQL database in a cloud?'
date: '2014-04-10 13:00'
comments: true
author: 'Roland Schmidt, Sr. Director of Business Development, Clustrix, Inc.'
published: true
categories: []
---


For those of you not yet familiar with Clustrix, we have developed ClustrixDB,
the industry’s first scale-out SQL database engineered for the cloud.
ClustrixDB is uniquely and ideally suited to handle massive volumes of
ACID-compliant transactional workloads while concurrently running real-time
analytics on the same operational data. (See:
[https://www.clustrix.com](https://www.clustrix.com)).

Delivering a database like ClustrixDB with linearly-scaling performance,
automated fault-tolerance and self-healing in a cloud would be a significant
challenge. Success would depend heavily upon a well-architected infrastructure
on which to deliver this level of enterprise value at the SLAs our customers
had come to expect from us. And we were actively seeking a cloud with such
capabilities.

<!-- more -->

### Where Did ClustrixDB Grow Up?
Prior to our OCT ’13 GA release of ClustrixDB Software Version, we had only
delivered ClustrixDB for production use on our own dedicated, turn-key Appliance
clusters comprising 3-to-N nodes. Each node had eight 64-bit physical cores,
48GB RAM, 1GB NVRAM, 7 x 160GB SSDs, dual 40Gbps Infiniband fabrics for
node interconnect, and multiple Gb Ethernet NICs for front-end client SQL access.

Years of development and commercial success had proven our Appliance to be
the optimal delivery vehicle for on-premise or co-located datacenter
Enterprise deployments, but extremely difficult, if not impossible, to deploy
in a cloud. This was due to:

1. lack of availability of the type of components in the cloud that ClustrixDB needed to function at the SLAs it was intended
2. general lack of consistent, predictable cloud performance
3. the lack of the option to co-locate an Appliance in the cloud.

### What Would ClustrixDB Need to Succeed in a Cloud? (second verse, same as the first)

There are several key factors of critical importance in delivering ClustrixDB with the SLAs on which our Appliance customers had come to depend for their massive web-scale transactional applications.

These are:

1. high-speed, low-latency cluster interconnect - to support large cluster node counts with linearly-scaling performance and fault tolerance
2. large CPU core counts per node - to support massively parallel processing of complex analytic queries simultaneously with large-volumes of highly-concurrent transactions
3. very fast access to sufficient capacity of highly-reliable, persistent SSD storage.

What would we need to succeed in a cloud? What could we give up without compromising ClustrixDB significantly? Very little! We concluded we’d need the same three key characteristics of our Appliance. However, most of these things have been conspicuously absent from cloud environments. That is until Rackspace’s introduction of its Performance flavor class of cloud servers on NOV 5th, 2013.

###Maybe We Can Really Do This Now? (what Clustrix wanted to learn)

The introduction of Rackspace’s Performance flavor class of cloud servers really motivated us to want to test our new ClustrixDB Software Version on these all-SSD-based VMs. At first glance they seemed to us to finally bring the characteristics of our Appliance to the cloud.

In particular, we were interested in comparing them to other HDD-based cloud servers we had tested to determine if they sufficiently closed the gap with our Appliance in their ability to support production workloads, and do so with the linearly-scaling performance and availability customers expect from us.

Prior to the GA release of ClustrixDB we had only characterized the applicability of ClustrixDB for cloud usage on several kinds HDD-based cloud servers. We found most all of them lacking in one or more key areas to be useful for the types of problems our customers wanted to solve at scale.

Before that we tested some standard 64-bit physical servers, including using our own Appliance hardware used in a more generic manner. We stripped the Appliance software stack with its raw, direct-I/O access to SSD, replacing it with a CentOS ext4 file system, removed our NVRAM buffer, emulating that in software, and replaced the Infiniband adapters, using instead 10GbE NICs for cluster interconnect. Our tests revealed we could actually get close to the functionality and performance of our dedicated Appliance.

Now we hoped we could replicate this performance in a cloud as well, and Rackspace appeared to be our best hope for that.

Of particular interest to us in their “Perf2” servers was the:

1. all-SSD storage
2. non-oversubscription of vCPUs and RAM
3. high network bandwidth guarantees.

Could we finally be able to get out of a noisy-neighborhood cloud apartment that always seems to run out of hot water just when you need it most? And instead, move into a nice, fresh, new shared townhouse complex with sound-proof walls and separate utilities? Evict us now please!

### What Cloud Configurations Did We Compare?
Knowing already what our Appliance does, and what most of its underlying hardware did with the ClustrixDB software version replacing the Appliance Software stack, we next compared clusters built from Standard Instance and Performance2 VMs using the same test harnesses we use at Clustrix for Appliance testing, and also used for standard 64-bit servers as well as our stripped Appliance hardware.

To determine the suitability of the Rackspace Open Cloud as a new delivery vehicle for ClustrixDB we created all cluster nodes from a single Rackspace “Saved Image” that we first made by downloading a ClustrixDB v5.2-10117 package from our website onto a VM built with Rackspace’s CentOS 6.4 image, configured iptables, and saved that image.  Then we spun up 18 nodes from the image, 9 each of:

* Standard Instance - 8vCPUs-30GB RAM-1,200GB HDD, 300/600 Mbps (pub/priv) net bandwidth
* Performance2 class - 8vCPUs-30GB RAM-40+300GB SSD, 2.5 Gbps total network bandwidth

We purposely chose comparable VMs in terms of #s of vCPUs and GBs of RAM from the previous and new generation of cloud servers to determine relative improvement between these generations. [See the actual Rackspace Cloud Portal images below for how simply and easily this was done, and also how intuitive and visually improved it is as well.] It’s way better than just the new Performance cloud servers.

Next, we made and mounted ext4 file systems on each Perf2 VM’s 300GB data disk (Standard Instances come with a single disk for OS and data), ran the ClustrixDB install script on all nodes, and then formed 2 min. 3-node clusters of each instance type using ClustrixDB’s Insight Install Wizard. Done in under 15 minutes! NOTE: Using Rackspace’s “Saved Image” feature greatly simplified and sped up cluster building while eliminating unintended variability and human error from creeping into and tainting our testing.

We left our other 12 nodes, 6 of each type, standing by and ready to be used to grow the 2 test clusters by 3 nodes each after the first and second test passes of each test. NOTE: This operation is very simply done through Clustrix’s Insight Manager web UI. It takes only seconds and a couple clicks to add nodes.

![Flavor][1]

![enter image description here][2]

###Let The Testing Begin (enough talk already!)

ClustrixDB is first and foremost a SQL relational database. As such its principle use case is as a primary transactional database for an enterprise’s operational data. Uniquely so, ClustrixDB can run heavy real-time analytics workloads simultaneously with high-volume, highly-concurrent transactional workloads.  Because of this we need cloud servers capable of doing both. For this first round of testing we decided to use two separate workloads focused exclusively on OLTP queries and Analytic queries respectively.

The OLTP workload was created using Sysbench. We produced result sets for 3 different workload query mixes:

1. 90% Read/10% Write
2. 100% Write
3. 100% read.

It should be noted that due to the size of the Sysbench data set all the data fit in RAM, therefore not all of the advantages of faster I/O to SSD on the Perf2 clusters will be visible on the 90%/10% R/W and 100% Read workloads. In production use we believe the improvement over the Standard Instance would be much greater.



![OLTP][3]




```
Cluster Size    Maximum TPS
Standard Instance   Maximum TPS
Performance 2   Perf 2 Improvement
> Standard Instance
3-Nodes 42964   62990   46.6%
6-Nodes 69323   98863   42.6%
9-Nodes 89047   123540  38.7%
```

**OLTP Results - Sysbench Mixed Workload of 90% Read & 10% Write Queries**


![enter image description here][4]










```
Cluster Size    Maximum TPS
Standard Instance   Maximum TPS
Performance 2   Perf 2 Improvement > Standard Instance
3-Nodes 13318   19471   42.6%
6-Nodes 20603   29329   42.4%
9-Nodes 29804   42503   42.6%
```


**OLTP Results - Sysbench Write-Intensive Workload of 100% Write Queries**



![enter image description here][5]







```
Cluster Size    Maximum TPS
Standard Instance   Maximum TPS
Performance 2   Perf 2 Improvement > Standard Instance
3-Nodes 57917   76468   32.0%
6-Nodes 87829   117791  34.1%
9-Nodes 130391  169713  30.2%
```


**OLTP Results - Sysbench Read-Intensive Workload of 100% Read Queries**




The OLAP Analytics Query workload was created using a mix of long-running analytics queries including large multi-table joins and distributed aggregates across the cluster. This test is intended to get the cluster into a fairly compute-bound state with minimal intra-cluster traffic occurring as a percentage of query execution time. This characterization along with the dataset fitting well within the 30GB of RAM on each cluster node will do a pretty good job of isolating CPU and Memory differences.  This test clearly will not be able to expose the superior I/O performance of the Perf2 cluster nodes.  However it does show the percentage of gain of the Perf2 VMs maintained across the three cluster sizes.



 ![enter image description here][6]


```
Cluster Size    Secs to completion
Standard Instance   Secs to Completion
Performance 2   Perf 2 Improvement > Standard Instance
3-Nodes 1515.03 1344.42 11.3%
6-Nodes 1163.69 1039.01  10.7%
9-Nodes 993.42  886.98  10.7%
```

**OLAP Results – Analytics Query Workload**


Summary and Conclusions (sign me up and spin ‘em up!)
Rackspace’s new Performance2 flavor class servers are definitely up to the task of providing a solid new delivery vehicle for production deployment of ClustrixDB in a cloud. They significantly close the gaps in functionality and performance between cloud-based clusters and dedicated, purpose-built Appliance clusters. Scalability is good and performance is predictable and close to that of our Appliance hardware.

Compared to a Rackspace Standard Instance server a Performance2 server of the same vCPU count and GBs of RAM ranges from 30-46% faster on OLTP database tests representative of production query types and mixes. The gains are even more meaningful when considering the size of RAM on both types of nodes was large enough to hold the entire data set, so the full value of the speed of the Perf2’s SSD could not be fully realized during the OLTP Read and Read/Write mixes.

With data sets of sizes much larger than the RAM on the clusters, the Perf 2 servers would register greater improvements as indicated in the OLTP 100% write test where the performance gains were consistently averaging 42.5% higher than the Standard Instance clusters and more of the Perf 2’s SSD performance was then visible. On memory-resident 100% reads the gains were still never less than 30%, and averaged 32%, which is likely a good indicator of the CPU and RAM speed improvements alone.

In terms of CPU count, RAM and SSD capacity and network bandwidth, the Performance2 flavor class of Rackspace cloud servers possess the configurability and scope to meet some of the most demanding workloads currently run and supported by us on dedicated machines and Appliances. We only used cluster nodes with core counts of 8vCPUs, which is the upper limit of the Standard Instances, where 8vCPUs is the 2nd lowest core count for Performance 2. We did this to get a fair relative comparison.

Given the Performance 2 series provides us with 3 larger options for cluster nodes, we would like to do this again sometime using the 16, 24 and 32vCPU VMs in clusters of even larger than 9 nodes as we used for this testing phase. Those Perf2 VMs not only have greater #s of cores and RAM, but progressively higher levels of guaranteed bandwidth as well, which is critical to our ability to continue to scale out with greater numbers of cores and nodes across the clusters.

For highly-concurrent transactional workloads and real-time analytics Rackspace’s new Performance 2 flavor class cloud servers provide great performance, superior price/performance and therefore excellent value. Clustrix recommends them without reservation for running the ClustrixDB scale-out SQL database in a cloud. So buy a bunch, don’t worry, they’ll make even more of them!


P.S. – We’re already wondering about comparing clusters of 8 x Perf2 32vCPU/120GB RAM nodes, and 32 x 8vCPU/30GB nodes.


  [1]: https://d2793c225face3f00d0b-0c03021b939a680b5f64562de26e5c4f.r83.cf1.rackcdn.com/Flavor.png
  [2]: https://d2793c225face3f00d0b-0c03021b939a680b5f64562de26e5c4f.r83.cf1.rackcdn.com/flavorII.png
  [3]: https://d2793c225face3f00d0b-0c03021b939a680b5f64562de26e5c4f.r83.cf1.rackcdn.com/OLTP.png
  [4]: https://d2793c225face3f00d0b-0c03021b939a680b5f64562de26e5c4f.r83.cf1.rackcdn.com/OLTP%20II.png
  [5]: https://d2793c225face3f00d0b-0c03021b939a680b5f64562de26e5c4f.r83.cf1.rackcdn.com/OLTP%20III.png
  [6]: https://d2793c225face3f00d0b-0c03021b939a680b5f64562de26e5c4f.r83.cf1.rackcdn.com/OLTP%20IV.png