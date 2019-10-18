---
layout: post
title: A Big Data Solution Running On Top of Rackspace Private Cloud
date: '2014-09-22 11:00'
comments: true
author: James Thorne
published: true
categories:
  - openstack
  - private-cloud
bio: >
  James Thorne is a Sales Engineer at Rackspace focused on working with
  OpenStack. He is a Texas State University alumnus and former Platform
  Consultant at Red Hat. James has been working with Linux professionally for
  the past four years and in his free time even longer. James blogs at
  thornelabs.net and can be followed on Twitter @jameswthorne.
---

Two weeks ago, I presented a live webinar on [a big data solution running on top of Rackspace Private Cloud](https://youtu.be/V55gzeBxmwE).

The following post, the fifth and last in the [RPC Insights series](https://www.rackspace.com/blog/welcome-to-rpc-insights/), will be a summary of that live webinar. I will be discussing what big data is, why Rackspace Private Cloud is a good fit for running big data solutions, some tools associated with big data, and briefly showing you how to run your first Hadoop job.

<!-- more -->

This is the third and last use case webinar/blog posts in the RPC Insights series. The second use case webinar/blog post talked about using Rackspace Private Cloud to support your software development lifecycle. If you happened to miss the last webinar and are interested in watching it, please go [here](https://developer.rackspace.com/blog/using-rpc-software-dev-lifecycle/). There you will find a link to the recorded webinar as well as a blog post discussing a general overview of the software development lifecycle, why Rackspace Private Cloud is a good fit for this use case, and demonstrating how to integrate Jenkins with GitHub.

What is Big Data?
-----------------

So, what is big data? Just like "cloud", you hear the term all the time.

[Wikipedia](https://en.wikipedia.org/wiki/Big_data) provides a broad definition:

> Big data is an all-encompassing term for any collection of data sets so large and complex that it becomes difficult to process using on-hand data management tools or traditional data processing applications.

[MongoDB](https://www.mongodb.com/big-data-explained) also provides a similar definition but is a bit more focused:

> Big Data refers to technologies and initiatives that involve data that is too diverse, fast-changing or massive for conventional technologies, skills and infrastructure to address efficiently. Said differently, the volume, velocity or variety of data is too great.

It Isn't Just About Volume
--------------------------

Keep in mind, even though the word "big" is in the term big data, it isn't always about the amount of data (otherwise referred to as volume). As mentioned in the MongoDB example, it is also about the __velocity__ and __variety__ of the data.

According to [Jim Gallo](https://www.informationweek.com/software/information-management/is-your-data-big-enough-for-big-data/d/d-id/1109038?), national director of business analytics for ICC, an IT services provider based in Columbus, Ohio, "volume isn't everything. For organizations to accurately determine whether a big data platform is right for them, they must also study the variety and velocity of their data."

You could very well just have a large volume of transactional and structured data that doesn’t really classify as big data or require big data tools to analyze.

So, what are some big data examples? Once again, [MongoDB](https://www.mongodb.com/big-data-explained) provides several:

> For example, retailers can track user web clicks to identify behavioral trends that improve campaigns, pricing and stockage. Utilities can capture household energy usage levels to predict outages and to incent more efficient energy consumption. Governments and even Google can detect and track the emergence of disease outbreaks via social media signals. Oil and gas companies can take the output of sensors in their drilling equipment to make more efficient and safer drilling decisions. "Big Data" describes data sets so large and complex they are impractical to manage with traditional software tools.

Why Rackspace Private Cloud?
----------------------------

The first half of the battle is figuring out if you have big data. The second half is figuring out how you can make use of it all.

Once you determine that you actually have big data to process, why would you want to use Rackspace Private Cloud to process all of it? You could just as easily use a public cloud to run your big data solution.

In the last webinar, I built a narrative around using Rackspace Private Cloud to support your software development lifecycle.

Let's again build a similar narrative for running a big data solution on Rackspace Private Cloud. Similar to the last webinar, there are some key factors as to why you may want to use a private cloud instead of a public cloud.

The Narrative
-------------

Your company recently acquired another company who has a large volume and variety of raw data that is constantly being captured. The company you acquired has no idea how to take advantage of this raw data. It is quickly determined that this raw data is something that could have a huge return on investment if the proper analysis are performed on it to create actionable information. If even a small sample of this raw data is seen by competing companies it could put the acquisition at risk.

So, based on that, you have decided to take this raw data and process it on top of a Rackspace Private Cloud environment. What are some of the factors influencing your decision to run your environment within a private cloud instead of a public cloud?

### Privacy and Security

First, privacy and security.

Some data is crucial to businesses, other data is not. There is a good chance that if you truly have big data to process into valuable information, that raw data and the way you process it are crucial to your business. When using a private cloud to run your big data workloads, you run a much lower risk of your raw data being compromised when compared to running it on a public cloud. Rackspace Private Cloud provides you the privacy and security needed to ensure your data stays within your organization.

### Performance

Second, performance.

One of the three “V’s” of big data you heard earlier was volume. When you have a high volume of raw data to process, some of that data you may want to process as fast as possible because the quicker you process it the quicker you can make business decisions that could positively impact your business. With a Rackspace Private Cloud, you run your workloads on OpenStack Instances that run on your own bare metal servers. There are no other tenants besides you in the environment. Because of this, you do not have to worry about noisy neighbor's affecting the performance of your workloads like you would in a public cloud.

### More Control

Third, more control.

The raw data you have to process may require different types of server configurations or OpenStack Instance types. Running a Rackspace Private Cloud gives you the ability to customize such things as spindle hard drives vs SSD hard drives in your compute nodes, 1 Gb or 10 Gb networking, or the ability to exactly define your OpenStack Flavors so you can create OpenStack Instances with the perfect amount of vCPU, RAM, and Storage.

### Cost

Fourth, cost.

Big data workloads can run for a very short time, for a very long time, or anything in between. If your workloads are running in a public cloud, your cost continually increases until your workload finishes. If you workloads are running in a private cloud, your cost is flat regardless if your workload is running. With a Rackspace Private Cloud, you only pay for the gear you currently have. You can create and run as many OpenStack Instances as you want on it without the cost changing. You only add cost when you add physical servers to your environment.

Big Data Tools
--------------

So, with those four factors, and there are always more, you have decided to run your big data solution on a Rackspace Private Cloud.

But, what sort of tools would you be running on your Rackspace Private Cloud to process your big data?

There are too many big data tools to list and talk about, but I will briefly discuss some of the more popular ones.

### Analysis Tools

As for big data analysis tools, there is of course Hadoop. Whenever big data is discussed, Hadoop is not far from being mentioned. But, what is Hadoop?

From [hadoop.apache.org](https://hadoop.apache.org):

> The Apache Hadoop software library is a framework that allows for the distributed processing of large data sets across clusters of computers using simple programming models. It is designed to scale up from single servers to thousands of machines, each offering local computation and storage.

Hadoop was designed with cloud environments and infrastructure in mind.

Another useful tool is MapReduce, which is often also talked about when discussing Hadoop.

From [Wikipedia](https://en.wikipedia.org/wiki/MapReduce):

> MapReduce is a programming model and an associated implementation for processing and generating large data sets with a parallel, distributed algorithm on a cluster.

Hadoop gives you the ability to run MapReduce jobs across a cluster so you can process your raw data quicker.

### Database Backends

As for some database backends, you have Cassandra and mongoDB.

[Cassandra](https://cassandra.apache.org) is a highly scalable, eventually consistent, distributed, structured key-value store. It is one of the NoSQL databases. Hadoop has support for using Cassandra as a data storage mechanism.

[MongoDB](https://www.mongodb.com), another NoSQL database, is a document-oriented database that uses JSON-like documents with dynamic schemas. It too has a connector that allows you to use it as a data storage mechanism in Hadoop.

Demo
----

So, with that overview of what big data is, why Rackspace Private Cloud is a good fit for running big data solutions, and some tools associated with big data, the last thing I want to cover is a short demo.

Hadoop is not a simple thing to get up and running, and how to install it is out of the scope of this post. However, I want to briefly show you how to run your first Hadoop job once you have a Hadoop cluster up and running.

### The Hadoop Cluster

As mentioned, how to install Hadoop is out of the scope of this post. There are plenty of guides available on the internet to get Hadoop up and running.

Alternatively, if you simply want to get a Hadoop cluster up and running quickly, you can use the Rackspace Public Cloud by creating a Rackspace Public Cloud account, going to the __Big Data__ section, and clicking __Create Cluster__. Within about 10 minutes you will have a Hadoop cluster you can begin tinkering with. Be aware that charges will apply as long as the cluster is created.

A very basic Hadoop environment is going to have three nodes: a gateway node, a name node, and a data node.

The gateway node is going to be running services such as [pig](https://en.wikipedia.org/wiki/Pig_(programming_tool)) and [hive](https://en.wikipedia.org/wiki/Apache_Hive) and is your entry, or "gateway", into the Hadoop cluster.

The name node is going to be running services such as [yarn](https://hortonworks.com/hadoop/yarn/). It is responsible for keeping a directory tree of all files in the Hadoop file system, or in other words, it tracks where data is stored throughout the Hadoop cluster.

The data node is also going to be running the yarn service. It is responsible for storing the actual data and processing that data when a MapReduce job is run. The MapReduce job is run on the data node because the processing should be performed as close to the data as possible.

### Running Your First Hadoop Job

Once you have a working Hadoop cluster you can begin running MapReduce jobs.

Log into your gateway node via SSH. You should have tied your user account to Hadoop during the installation process. Whatever user you used, `su - $USER` to that user.

Begin by viewing the root HDFS filesystem with the following command:

    hadoop fs -ls /

A handful of directories will be returned. You can view your user's directory (in this case the user is jamesbond) with the following command:

    hadoop fs -ls /user/jamesbond/

That user's directory is most likely empty. To process any data with Hadoop, the data needs to be in the Hadoop filesystem. So, download the following text version of "Ulysses by James Joyce" to the gateway node:

    curl -O https://www.gutenberg.org/cache/epub/4300/pg4300.txt

If you want some other large files to tinker with, here is the text version of [The Notebooks of Leonardo Da Vinci — Complete by Leonardo da Vinci](https://www.gutenberg.org/cache/epub/5000/pg5000.txt).

Once the text file has been downloaded to the gateway node, upload it to your directory in the Hadoop file system:

    hadoop fs -put ulysses-by-james-joyce.txt /user/jamesbond/

Verify the file is there:

    hadoop fs -ls /user/jamesbond/ulysses-by-james-joyce.txt

With the data you want to process in place, you now need MapReduce jobs to run against it. Hadoop comes with an example Java Jar file containing MapReduce jobs. Depending on how you installed Hadoop, you may or may not already have this file. If for some reason you do not or simply can't find it, it can be found by downloading the [compiled Hadoop tar file](https://mirrors.sonic.net/apache/hadoop/common/hadoop-2.4.0/hadoop-2.4.0.tar.gz) (in this example I am using Hadoop 2.4.0), un-taring it, and copying file __~/hadoop-2.4.0/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.4.0.jar__ to your home directory on the gateway node.

Once you have the example Java Jar file in place, you can run the __wordcount__ MapReduce job to count the number of times all words appears in the text file:

    hadoop jar hadoop-mapreduce-examples-2.4.0.jar wordcount /user/jamesbond/ulysses-by-james-joyce.txt /user/jamesbond/ulysses-output

While the job is running, go to the [Hadoop docs](https://hadoop.apache.org/docs/r1.2.1/mapred_tutorial.html#Example%3A+WordCount+v1.0) and click __Example: WordCount v1.0__ to understand what the MapReduce job is doing.

Once the job completes, all of the output is in the directory you specified above (__/user/jamesbond/ulysses-output__ ). Within that directory is a file containing the final output of the MapReduce job. Download that file from the Hadoop file system and save it to the local file system on the gateway node:

    hadoop fs -get /user/jamesbond/ulysses-output/part-r-00000 .

The output file is simply a text file, so use your favorite command line text editor to view it. When you open the text file, you will see one column containing all of the words in the file and a second column containing a count of the number of times that word appeared in the file.

The example Java Jar file [contains many MapReduce jobs you can run](https://www.informit.com/articles/article.aspx?p=2190194&seqNum=3). For example, another job you can tinker with the is the __wordmedian__ job:

    hadoop jar hadoop-mapreduce-examples-2.4.0.jar wordmedian /user/jamesbond/ulysses-by-james-joyce.txt /user/jamesbond/ulysses-output2

Once the job completes, you can download the output file and save it to the local file system on the gateway node:

    hadoop fs -get /user/jamesbond/ulysses-output2/part-r-00000 .

Again, the output file is simply a text file, so use your favorite command line text editor to view it. When you open the text file, you will see different output from the last job. The text file will contain one column with the length of a word and a second column with a count of the number of times that length of word appeared.

These are two very simple example MapReduce jobs to get you started working with Hadoop. You can upload whatever data you want to your Hadoop cluster and begin processing it with MapReduce jobs that you write.

What's Next
-----------

I have discussed what big data is, why Rackspace Private Cloud is a good fit for running big data solutions, some tools associated with big data, and briefly showed you how to run your first Hadoop job.

This concludes the fifth and last blog post in the [RPC Insights series](https://www.rackspace.com/blog/welcome-to-rpc-insights/).

Thank you all for watching and reading.
