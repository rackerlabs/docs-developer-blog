---
layout: post
title: "Load Balancing for E-Commerce (pt 1)"
date: 2015-11-16 10:00
comments: true
author: Jonathan Hurley
published: false
categories:
    - ecommerce
--- 
 
Prelude
-------

Before getting into the nuts and bolts of the load balancing architecture itself, it's 
important to understand the (typical) multiple tiers of an E-Commerce application framework:

1. Firewall (edge)
1. Physical local traffic manager (LTM)
1. Web Server
1. Application Server
1. Database Server (cluster)

Keep in mind that, top to bottom, the environment will be asymmetrical from a load 
perspective. For example, a single web server will typically be capable of 2-3x the number 
of concurrent connections as a single application server; heavily dependent on cache 
density - higher density will shift more load up into the web tier. Caching will be a 
subject for a later discussion, but at a glance should account for 80+ percent of content 
served. With room for variance, the majority of successful architectures achieve this metric 
and those that struggle tend to miss. This is not to say, of course, that a lower density 
will necessarily have difficulties. In addition to relocating load away from application 
servers, a higher cache density opens an opportunity for external services, such as Akamai 
CDN, to absorb load ahead of ever reaching the environment.

<!-- more -->

Starting Small
--------------

For smaller ecomm architectures it is effective to build 1:1 pipelines from the web tier, 
such as having one web server for each application server. This opens the option to 
statically configure connections so that the LTM is a single point of balancing that then 
cascades down. In addition to being simple to explain and document, this architecture 
greatly reduces the number of moving parts which especially pays dividends during 
troubleshooting and monitoring. Deployment simplicity is an additional, often overlooked, 
benefit that originates in the ability to transparently, and without manual intervention 
at the LTM or FW layer, remove hosts from load by failing LTM health checks.

Exploring Algorithms
--------------------

It is very tempting to explore more intelligent balancing algorithms with ecomm 
architectures because of the variable nature of session load. A simplified example contrasts 
two types of sessions - browse vs cart. In the former, a visitor may be requesting numerous, 
potentially unrelated, pages as they explore the catalog. In a perfect world, that 
interaction is wholly cached and never traverses as deep as the application servers. The 
latter session type, however, does require interaction with the application in order to 
manage the cart and session data. Further, if the cart interaction results in a conversion, 
then there is further load as order processing, shipping, and revenue tasks are executed.

Not existing in a perfect world, both load models must be accounted for in the application 
as those server processes will necessarily be carrying some percentage of non-dynamic 
traffic. This model leads to decision number one - optimize around the likely more critical 
conversion traffic or focus on the more frequent, lower-impact browse traffic. In the simple 
1:1 architecture above, this decision is made and implemented from the perspective of the 
LTM only. Although this simplifies the decision tree by eliminating factors, it also forces 
an "either / or" proposition for east-west load distribution. A simple example that could 
occur would be if the LTM implements a round-robin algorithm and, by happenstance, all order 
conversion sessions are sent to a single web server. This scenario can result in anomalously 
elevated load for the application server and potentially the web server in that stack. 
Strictly speaking this is not a problem, provided that a single web and app server can 
sustain the load of all concurrent orders. Of course, if that is the case, then the 
environment is probably over-sized for its requirements.

Although this scenario is not likely, perhaps there is a better way? Perhaps. Algorithms 
that account for load and/or latency could be an effective solution for this behavior. The 
primary challenge is that the architecture intentionally abstracts application server load 
in favor of focus on the web servers; due to the nature of caching, even heavy load against 
the web servers will likely manifest as lower resource utilization than the respective 
application servers. This gives the artificial, and potentially incorrect, impression that 
a given web/app pair are not heavily utilized and could accept additional load.

The Multi-Balance Architecture
------------------------------

So there's no good way to solve the problem? Well not exactly. At its heart the challenge 
is one of perception; environmental load balancing needs to account for both web and 
application tier utilization in order to effectively route traffic. The way that hybris, 
as well as others, have solved this challenge is to implement load balancing functionality 
within the web tier. Effectively, this means that the LTM balances across web servers then 
a second tier, potentially the web servers themselves, balance across the application 
servers. 

For example:

```
    <VirtualHost 127.0.0.1:*>
      ServerName www.example.com
      DocumentRoot "/var/www/html/example/"  ProxyPassMatch ^/product/? !
      ProxyPassMatch ^/pdf/? !
      ProxyPassMatch ^/rma/? !
      ProxyPassMatch ^/health_check.htm !
      ProxyPassMatch ^/balancer-manager/? !
      ProxyPass / balancer://cluster/ stickysession=ROUTEID nocanon
      ProxyPass /balancer-manager !
      ProxyPassReverse / balancer://cluster/
      <Proxy balancer://cluster>
        BalancerMember ajp://192.168.0.1:8009  loadfactor=1 route=node1 keepalive=On ping=3 ttl=60 max=3 retry=60
        BalancerMember ajp://192.168.0.2:8009  loadfactor=1 route=node2 keepalive=On ping=3 ttl=60 max=3 retry=60
        ProxySet lbmethod=byrequests timeout=30
        Order deny,allow
        Allow from all
      </Proxy>
```

This example shows use of the mod_proxy_ajp Apache HTTPd module. The primary alternative is 
mod_jk for Apache. Without descending into a comparative of modules, for another day, there 
is a difference and a host of reasons to pick one over another. 

A few important takeaways:

* This is configured by VirtualHost. It is not terribly common, but theoretically possible 
  to configure different pools based on the vHost
* The BalanceMember configuration works in conceptually similar fashion to any LTM:
  * loadfactor : 0-100 defines load weighting
  * keepalive : prevent idle sessions from timing out. This can lead to load and 
    performance issues and should be tested thoroughly
  * ping : defines an interval in seconds (socket connection if negative) to determine 
    up/down of target node 
  * retry : if the member is in a failed state, then do not recheck for n seconds 
  * max : maximum number of connections from the MPM pool to be sent to that member 
     (note: prefork is always 1)
* ProxySet
  * lbmethod : specify the load balancer method
  * byrequests - weighted request
  * bytraffic - weighted traffic bytes
  * bybusyness - pending request balancing
  * timeout : wait n seconds for a member to be available
 
In Practice
-----------

For a traditional balancing discussion, the focus will tend to be on the algorithm 
itself, because that is the mechanism driving overall performance and behavior. Referencing 
the above configuration for hybris, the environment will be controlled by two algorithms: 
*RR* at the LTM and *BR* at HTTPd. Nothing is inherently incorrect or risky with 
this configuration; however, it does introduce two significant challenges:

1. The debugging surface is much larger because it must now account for asymmetric 
   north-south as well as east-west load patterns.
1. Inter-node communication must be solved to avoid roaming load.

*Roaming Load* in this context refers to a situation where one or more hosts, typically 
application servers, experience inflated load distribution as a by-product of load 
balancing and neither as a direct result of thread performance nor life cycle.

When an Internet request is accepted by the edge firewall, it is passed to the LTM for 
balancing. Using an RR algorithm, this request will be forwarded to the next HTTPd pool 
member in sequence. This is expected to achieve a mostly normalized pattern of load shared 
equally between nodes. Each HTTPd thread will use its configured algorithm (and byrequests  
method) to determine, on the fly, which application server is the best match for its new 
session. 

When Internet connections follow a pattern where time delay between requests exists, this 
approach may appear to function effectively. Once larger numbers of concurrent connections 
begin accessing the environment, however, multiple HTTPd threads will simultaneously 
determine that a single, or few, application server(s) are the best match. When this happens 
then all threads will balance the session to that same node, raising load from very low to 
very high in as little as a few seconds. The affected application server is then unlikely 
to match again for a period of time, causing new connections to all target a different host. 
This pattern cycles through the environment until either the first-impacted host again 
becomes the best match or there are no valid matches.  At that point, requests enter a 
waiting state.

The Solution
------------

The bad news is that there isn't really a solution for the debugging surface challenge in 
number 1 above. Any time that there are multiple balancing tiers, the debug surface is a 
challenge.

The good news is that avoiding roaming load can be solved in a few ways:

1. **Single HTTPd** - 
   If a single HTTPd server can handle the expected load and if ancillary HTTPd servers 
   are for HA only, then the LTM can be configured with weighted pool members such that 
   web01 is the preferred server, web02 is second, and so on. This preserves an HA 
   architecture but avoids a situation where multiple HTTPd nodes are competing for best 
   match.
1. **Dual LTM** - 
   This need not be multiple physical LTMs. Logically placing an LTM inline for 
   HTTPd-to-application traffic is effectively the same as having a single HTTPd server, so 
   only one algorithm and one control process is determining best match at any given time.
1. **Multi-Pool Application Servers** - 
   In the hybris example above, a second HTTPd server could be configured with BalanceMembers 
   192.168.0.3 and 192.168.0.4. Since pool members do not overlap, there is no way for a 
   single application server to be targeted by multiple HTTPd servers simultaneously. In 
   this model, traffic is effectively controlled by the LTM algorithm with the HTTPd 
   algorithm functioning as a logical secondary.
1. **Inter-Process Communication** - 
   This is the least-commonly implemented solution and requires that each balancing process 
   in a tier be in communication with every other. For example, when an HTTPd process 
   identifies an application server as best match, it broadcasts its choice to all other 
   processes, and those processes respond by not matching that node for a given period of 
   time.

Conclusion
----------

On the surface, this may appear to be an edge case, however, an investigation of the vast 
majority of ecomm environments reveals this, or similar, gaps. Whether or not these gaps 
ever impact customer traffic is a product of the business model, load patterns, and 
application thread performance - a matter of *when* not *if*.




