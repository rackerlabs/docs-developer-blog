---
layout: post
title: AEM 6 Performance with MongoDB3.0
date: '2016-1-18 23:59'
comments: true
author: Nathan Coble
authorIsRacker: true
published: true
categories:
  - aws
---

MongoDB has made some noticeable improvements with the 3.0 release and new engine, WiredTiger.  This post shows how those improvements in MongoDB translate into real performance gains for your application.


<!-- more -->

Last month we went over [how to install AEM with MongoDB 3.0.][bp1] In this post, I am going compare performance of two Adobe Experience Manager author instances using MongoDB 2.6 and MongoDB 3.0

### The Testing Setup
The AEM authors and MongoDB servers were installed on seperate m4.2xlarge EC2 instances at AWS. (You knew [Rackspace supports AWS][faws1] already, didn't you?) Dedicated EC2 instances were used to alleviate "noisy neighbor" problems during testing. Testing the author performance was done with [Adobe Tough Day][td1].  The Tough Day tool from Adobe comes with several prebuilt tests you can use for performance comparison of the author instances.

### The Tests
For the first test, I used the Adobe Tough Day tool to create pages at several levels of the repository. To start the test, you run the Tough Day jar file, and specify options for the test.

```
$ java -Xmx1024m -Dhostname=localhost -Dport=4502 -DcreatePages.toplevels=100 -DcreatePages.sublevels=50 -DcreatePages.subsublevels=50 -DcreatePages.concurrentUsers=30 -DcreatePages.rampup=1 -DcreatePages.thinkt=5 -DcreatePages.activate=true -DcreatePages.delete=true -jar toughday-6.0.jar createPages
```

The second test used the authoring scenario from the Tough Day tool.

```
$ java -Xmx1024m -Dhostname=localhost -Dport=4502 -Dauthoring.loop=15 -Dauthoring.thread=30 -jar toughday-6.0.jar authoring
```

### The Results
The charts show the time, in seconds, it took for the author instance to complete the test with the MongoDB versions (Lower is better).

![Create Page Scenario]({% asset_path 2016-01-18-AEM-6-Performance-with-MongoDB3.0/CreatePageChart.png %})

![Authoring Scenario]({% asset_path 2016-01-18-AEM-6-Performance-with-MongoDB3.0/AuthoringChart.png %})

The results are significant, showing a 33% increase in performance for page creation and a 23% increase in performance with the authoring scenario.

   [bp1]: <https://developer.rackspace.com/blog/AEM6.1-With-MongoDB-3.0-And-WiredTiger>
   [faws1]: <https://www.rackspace.com/managed-aws>
   [td1]: <https://docs.adobe.com/docs/en/aem/6-1/develop/test/tough-day.html>
