---
layout: post
title: "Developing an effective monitoring strategy"
date: 2018-1-2 00:00
comments: false
author: Josh Mattson
published: true
authorIsRacker: true
authorAvatar: 'https://www.gravatar.com/avatar/791617263c70278859e1b26c15d13eab'
categories:
  - DevOps
  - aws
---

Modern application environments can be complex and include many discrete elements that can all affect the end user's experience.  Because of this, it can be challenging to develop an effective monitoring strategy that allows you to be alerted during potential performance problems and also to use these metrics from a variety of systems to proactively address potential bottlenecks and slow points before they cause end user impact.  In this article, we'll be discussing several best practices for ensuring that your environment is effectively monitored.

<!-- more -->

### Conceptualize monitoring of complex distributed applications

First, it's important to define what an effective monitoring strategy looks like.  What is most important?  Every application and environment exists to serve a business purpose and getting a clear view of this business purpose helps to guide our choices.

For example, an e-commerce application exists to directly generate revenue via customer sales.  In this case, the end user experience is tantamount to determinining the health of the application.  Are your end users satisfied?  End users who recieve timeouts adding products to the cart or slow load times loading searches will very quickly give up an move on to a competitor.

On the other end of the spectrum, even applications that are not public facing and might not have direct end user interaction still need to be considered.  Consider an application that is not internet facing but simply exists to serve API requests to other applications.  In this hypothetical scenario, your end users are the other applications that are issuing API calls.  Yes, these 'end users' will never get frustrated and move to a competitor, but it's still important that we consider the business case when ensuring that we have a holistic view of the environment and a sane alerting policy.

### Take stock of your environment

Once you've clearly identified the business purpose your application services, we can dive in to the technical.  We need to compile a list of all critical components within the application environment.  Depending on how your environment is architected, this list could vary significantly.  A cloud native application is very different from a legacy monolithic application hosted in an internal datacenter.

Generally speaking, you should include most (if not all) of these components in your assessment:

* Hardware
* Networking
* Host (or OS/Guest OS)
* Application
* Database
* Availability/Synthetic Transaction Monitoring
* End User Experience Monitoring

Depending on your environment's architecture, you might also need to include things like virtualization, storage, containerization, caching, and so on.

Finally, it's important to additionally look _outside_ of your application's environment.  Does your application depend on any third parties?  For example, does your e-commerce environment (hosted in AWS) talk to an inventory and fullfilment application located within your corporate datacenter that is managed by a separate team?  You might not be able to directly monitor these ancillary applications, but it's very important to keep them in mind in order to be effective.

### Use monitoring tools

Now that we've identified which components are critical to ensure that the application can serve its business purpose, we can start to identify tools that can help us to meet this goal.  Unfortunately, few platforms exist that truly standout for monitoring all necessary parts of your stack.  That said, there is still great value in having a single pane of glass to simplify monitoring, alerting, and reporting.  It's important to consider the value of a single pane of glass when evaluating potential tools and trade-offs that you might be willing to make.  For example, if you are hosting an application within Azure, hardware monitoring is likely unnecessary, but having the ability to monitor Azure inventory and status may be worthwhile.  Similarly, you may be willing to give up end user experience monitoring if you're hosting an application that isn't internet facing and is either only serving internal users or simply responding to API calls.

Ultimately, you need to determine which of the areas identified in your initial evaluation of your environment are _the most_ business critical.  Ensure that your primary monitoring platform can meet all or most of these most critical areas.  Less critical areas can be supplemented with a second, third, or even fourth tool, though I should caution that adding additional tooling can significantly increase complexity, time to resolution, and the amount of effort required to perform proactive performance assessment and improvement activities.

Consider _which_ metrics and what kind of data is important to you and your application.  The tools you choose will look very different for a small PHP e-commerce environment than for a highly distributed containerized Python application.  Ensure that the monitoring platform candidates you're selecting can provide the required metrics.  Many tools in the market can accomplish these needs, but it's also important to consider the work required to gather these metrics.  Some tools may be able to collect the metrics you require out of the box, and others require extensive customization or even modifications to your application's code.

### Consider  monitoring vs. alerting

This is an important distinction that is often lost during these kinds of discussions.  Monitoring refers to collecting metrics that are available for review.  Contrast this to alerting, which is proactive notification via various means (such as email, SMS, ticketing system integration, and so on) of an ongoing or likely performance issue.  A best practice with monitoring vs. alerting is to monitor as much as is needed in order to have _full_ visibility in to your application's performance and alert on only on critical (or potentially) critical situations.  A term we often discuss with customers is 'alert fatigue' in which monitoring systems generate so many non-critical alerts, which require no action, that eventually the operational teams become immunized to the alerts and begin to ignore them.  This, as you can imagine, easily leads to missed situations in which your application's performance is severely degraded (or worse, a complete outage).  With alerting, less is more.

It's important to keep in mind that tuning alert volume to reach to appropriate level is often an on-going process.  When starting out, refer back to the business purpose of your application.  In an e-commerce application, for example, monitoring the transaction response time for business critical transactions such as 'add to cart' and 'checkout' are clearly important, but monitoring for CPU usage on a given application server is probably unnecessary.  Consider what is important for your end users and focus your alerting to enhance that end user experience.  Some tools in the marketplace also have functionality like dynamic baseline alerting, which help you to avoid the pitfall of constantly setting and adjusting static thresholds for certain alerts; this is a very useful feature.

### Final thoughts

Developing an effective monitoring strategy is decidedly _not_ a simple process and is something that is often only paid lip service.  However, to have a truly performant and reliable application, it's critically important.  Spending time now to ensure that you've assessed and addressed all the requirements for monitoring your application's health can prevent significant heartache and the possibility of SLA payouts or even direct revenue loss in the future.
