---
layout: post
title: "Introduction to load and performance testing with the Gatling tool"
date: 2018-12-06 14:00
comments: true
author: Ning Zhang
published: true
authorIsRacker: true
bio: "Ning Zhang is a Software Developer in Test in the Rackspace Private Cloud Powered by VMware. Ning Zhang has years of experience in automation testing, performance testing, agile development and CI/CD."
categories:
    - Automation
---

This blog explores the fundamentals of Load and Performance Testing as well as the basics of the Gatling Tool (https://gatling.io). Some popular testing tools are also introduced here for load and performance testing, stress testing and web application monitoring.

<!-- more -->

Without further ado, here is everything you need to know about load and performance testing.

### What is performance testing?

Performance testing is a type of testing to determine the speed, responsiveness, and stability of a computer, network, software program, or device under a workload. The goal of performance testing is to ensure that software applications perform well under their expected workload.

The focus of performance testing is to measure a software application’s speed, stability, reliability, and scalability.

*	Speed – Determine how fast the application responds
*	Stability – Determine if the application is stable under varying load condition
*	Reliability – Determine if the application has the ability of fault tolerance and recoverability
*	Scalability – Determine the maximum number of concurrent users that the application can handle

It is important to check an application’s performance and ensure the software’s high quality by verifying that it has an acceptable load time and site speed. Performance testing is crucial for mission critical applications to ensure that they can run for a long time without deviations. In addition, performance testing helps development teams analyze application activities and predict traffic trends.


### Load testing vs stress testing

Load testing and stress testing are two important categories in performance testing. Within the definitions of a load test and a stress test, they are not completely independent from each other. The combination of load and stress tests is usually used for a system or an application’s performance.

A load test is a planned test to perform a specified number of requests to a system in order to test the functionality of the system under specific levels of simultaneous requests, like how quickly does it load when one user visits your website? How quickly will it load when 15 people are accessing your website at once? A load test ensures that a web system is capable of handling an expected volume of traffic, and therefore is sometimes referred to as volume testing. The goal of a load test is to verify that a system can handle the expected volume with minimal to acceptable performance degradation.

A stress test is a test designed to increase the number of simultaneous requests on a system past a point where performance is degraded, possibly even to the point of complete failure. A stress test is used to specifically push a system beyond its intended capacity to identify components that begin to slow down, identify bottlenecks in the system, and bring to light possible points of failure. By simulating 10,000 users, for example, a website will likely perform differently under that pressure than it will in everyday use. While stress testing encompasses unlikely test environments and user scenarios, it’s important for analyzing potential risks and breaking points in the system.


## Gatling tool for your performance testing

Gatling is an open-source load and performance testing framework based on Scala, Akka and Netty, and allows you to run it on any system. It is designed for ease of use, maintainability and high performance on different local machines and cloud servers to create and run your tests.

### Gatling metrics

Out of the box, Gatling generates detailed metrics dashboard of test results, which are stored as HTML files for deep analysis and metrics comparison, including indicators, active users, number of requests, and response time.

The following images show these dashboard metrics:

**Indicators**

{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/charts-indicators.png %}

**Statistics**

{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/charts-statistics.png %}

**Active users over time**

{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/charts-users.png %}

**Requests per second over time**

{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/charts-requests-per-sec.png %}

**Response time percentiles over time**

{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/charts-response-percentiles-per-sec.png %}

**Response time distribution**

{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/charts-distrib.png %}

**Jenkins Gatling plugin**

In addition, Gatling performance tool has built-in integration with Continuous Integration pipelines. For instance, you can choose the useful [Jenkins Gatling plugin](https://plugins.jenkins.io/gatling), which enables you to keep track of a Gatling simulation providing performance trends across builds, and publish detailed reports for each build.

{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/jenkins-dashboard.png %}

### Run a simple performance test with Gatling

Use the following steps to conduct a performance test with Gatling.

#### Install Gatling

Go to Gatling [download page](https://gatling.io/download/), and download the latest Gatling tool zip bundle. Unzip and put it in some location.

#### Configure your browser

Before starting to record a test scenario using Gatling recorder, we need to configure our browser proxy settings with the following steps. (All steps are done with a Google Chrome browser on Mac in this demo.)

1. Open the Google Chrome browser, and go to the settings.

2. Open proxy settings, and click **Advanced** at the bottom of the page.

    {% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/configuring-browser-1.png %}

    {% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/configuring-browser-2.png %}

3. Go to Proxies tab, check **Web Proxy (HTTP)** and **Secure Web Proxy (HTTPS)**, and type the address (**127.0.0.1**) and the port (**8000**).

    {% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/configuring-browser-3.png %}

    {% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/configuring-browser-4.png %}

4. Close the browser window.

#### Record a test scenario

Use the following steps to record the test scenario:

1. Gatling recorder `recorder.sh` is located under _/gatling-charts-highcharts-bundle-3.0.1.1/bin_. Note that `Java.exe` is required to open the recorder window.

2. Before starting the recorder, enter some settings in the recorder window.

    2.1 Enter the port number in the local host box (In my case **8000**).

    2.2 Enter the package name and the class name.

    2.3 Check **Follow Redirects?**, **Infer HTML resources?**, **Remove cache Headers?** and **Automatic Referers?**.

    2.4 Select the output folder path.

    2.5 Keep all other options as default.

    2.6 Click **Start**.

{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/gatling-recorder-1.png %}

<ol start=3>
    <li>  Open the Google Chrome browser, go to the URL: http://computer-database.gatling.io/, and try some operations on this page. The executed events can be observed in the recorder window. Click <b>Stop & Save</b>.</li>
</ol>


{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/gatling-recorder-2.png %}

#### Edit the Gatling script

After you finish the recording, find the simulation results stored in the folder _/gatling-charts-highcharts-bundle-3.0.1.1/user-files/simulations/gatlingExample_ under the name _gatlingExampleSimulation.scala_. Here is the produced output:

{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/gatling-script.png %}

The simulation script is written in Scala, and you can edit it based on the needs of your test scenario.

#### Execute a Gatling script

Launch `gatling.sh` located in the bin directory, and you should see a menu with the simulation examples:

{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/gatling-script-output.png %}

Select the ID number of the simulation that you want to execute. When the simulation is done, the console displays a link to the HTML reports.

### Integrate Gatling with Maven

This section shows you how to integrate the Gatling tool with Maven by using plugins, which has become essential in the world of CI/CD.

#### Plugin versions and download

To use Gatling with Maven, the plugin `gatling-maven-plugin` is required. Since Gatling is written in Scala, you also need another plugin `scala-maven-plugin` for it. Check out available versions on [Maven Central](https://search.maven.org/search?q=g:io.gatling%20AND%20a:gatling-maven-plugin&core=gav).

#### Setup and configurations

After creating a Maven project on your local, the setup in pom.xml file looks more or less like this:

{% img center 2018-11-29-Introduction-to-load-and-performance-testing-with-gatling-tool/pom-xml.png %}

In **pom.xml**, you can configure things like the multiple simulations’ execution, includes/excludes filters, etc. Check the [Gatling documentation](https://gatling.io/docs/current/extensions/maven_plugin/#configuration) for more configuration examples.

#### Usage

To execute your tests, you can directly launch the gatling-maven-plugin with the test or execute goal:

```
mvn gatling:test
mvn gatling:execute
```

## Other performance testing tools

The following list has the most widely used load and performance testing tools, whether those be open source, paid or a combination of both.

### Apache JMeter

Apache JMeter is a Java-based open source tool for load testing and measuring performance. It’s used for recording, building, monitoring, and debugging on different applications, servers, and networks. Also, it is of a great use in creating a functional or load test plan.
Download link: [Apache JMeter download](http://jmeter.apache.org/download_jmeter.cgi)

### WebLOAD

WebLOAD is an enterprise-level load and performance testing tool for web applications. It has both a free version and a paid version. The free edition offers 50 virtual users, and the paid professional edition provides the choices for enterprises with heavy user load and complex testing requirements. WebLOAD Cloud has a new level of visibility, control, and collaboration – on premises or in the cloud, and it integrates with other open source software like Selenium and Jenkins.
Free trial: [WebLOAD download](https://www.radview.com/webload-download/?utm_campaign=top-15-tools&utm_medium=top-15-tools&utm_source=softwaretestinghelp)

### LoadNinja

LoadNinjia is a cloud-based load testing and performance testing platform for web applications. It helps developers, QA teams, and performance engineers check if their web servers sustain a massive load and if the servers are robust and scalable. It also helps the engineer to focus more on creating applications that scale instead of focusing on developing load testing scripts.
Free trial: [LoadNinja download](https://loadninja.com/)

### LoadView

LoadView is a fully managed, on-demand load testing tool that allows for completely hassle-free load and stress testing. It can run in real browsers as well as headless http tasks to test the load of your website or web application. All test results are recorded and available in real-time online graphs and detailed reports to help track the response time.
Free trial: [LoadView download](https://userauth.dotcom-monitor.com/Account/FreeTrialSignUp?solutionType=StressTesting)

