---
layout: post
title: Building A Burstable DR
date: '2015-11-09 00:00'
comments: true
author: Jonathan Hurley
published: true
categories:
  - database
  - architecture
---

When it comes to the battle cry of E-Commerce, "we're losing $1m per minute" is the clear
winner, but a strong second is certainly "we want a disaster recovery solution". There are
numerous benefits to disaster recovery and business continuity planning, especially
speaking as the recipient of those 4am emergency calls. Traditional DR, with routing
changes, cutover plans, scaled-down performance, and questionable technical tasks, is a
well-traveled path in the industry, and it is very much inline with the expectations of
most organizations even today. In the rapid-fire world of E-Commerce, this approach offers
several challenges and misses a few key opportunities to take advantage of warm-side
management.

<!-- more -->

Risks and Challenges
--------------------

DR discussions, in a cutover model, fit like a glove for business discussions, with easy to
understand milestones, familiar objectives, and a steadfast repetition certainly belonging
in the "+" column. In the "other things to consider" column, there are some key items:

* **architecture** - Cutover models hearken back to big iron architecture of SPARC, Cray, and
   their ilk, designed to run for decades without real downtime or hardware failures and
   with software updates performed transparently inline and online. Many of these big-rigs
   continue to hum along even today, steadfastly watching the tide of commodity hardware
   rise. On paper, that rising tide has clear cost savings that have driven its
   overwhelming adoption and keep it an attractive option, to say nothing of being a key
   component in making virtualization feasible. There's one cost that isn't often reflected
   on that paper, though: commodity hardware is built with failure as a baked-in part of
   the ecosystem. Under the old regime, a mammoth and complex cutover was generally
   acceptable because the likelihood of it ever actually executing (in a non-verification
   scenario) was very low. In today's world, however, end users care about experience
   first, last, and only. With that in mind, modern DR strategies must account for the
   user experience. For E-Commerce, more specifically, this means that interruption and
   cutover times are simply not a part of a successful solution.
* **data loss** - The scary monster of IT rears its head again but this time it's a hydra of
   different data points:
   * **cart** - a user who loses some or all of the items added into cart will be a frustrated
      user and may choose not to, or be unable to, re-add all items resulting in lost sales.
   * **session** - on the modern Internet, users expect that sites know names, preferences,
      billing and shipping addresses, past orders, and the whole host of data-mining soft
      benefits. Accessing a site that has lost this session ability might as well be
      targeting users from 1999.
   * **sale** - there are two important parts to sale - processing and verification, either of
      which could be delayed, or fully interrupted, by cutover operations.
   * **records** - from fraud to Facebook, today's Internet runs on historical data and, if a
      site loses that data, then the best case is frustrated users and the worst is a
      massive interruption to business operations.
* **R?O** - During DR discussions a few R?O acronyms take the stage, and for E-Commerce the
   requirements are often even more aggressive than most others:
   * **RTO** - the recovery time objective is essentially "as low as possible (within cost
      parameters)", because every business needs 0sec RTO until there's a price tag.
   * **RPO** - the recovery point objective inherits from session expectations. Ideally, the
      recover point maintains the user experience or is, at least, minimally disruptive.
   * **RPO** - the recovery performance objective begs the question "what percentage of
      decreased performance is acceptable?"
   * **RBO** - the roll-back objective defines whether the business continuity planning is to
      run from DR continuously or to be able to operate for a defined duration before
      initiating a roll-back to original production.
* **cost** - There are actually two costs for the business:
   * **operating** - having idle hardware is a sunk cost, twice-over really since
      infrastructure is a sunk cost in the first place. A business that can make use of
      its DR infrastructure during non-DR operation will have happier shareholders.
   * **readiness** - hand-in-hand with RPointO above, the time and cost to keep Production
      running and in the development cycle is one thing, but ensuring that DR is
      representative of that moving target is an additional pipeline that is often
      overlooked, leading to technical debt.

Opportunities
-------------

So a cutover model is a dog's breakfast in today's marketplace, but what other options
exist to avoid this path of tears and heartbreak? The simplest concept to understand is
cost.  Cost has nice hard numbers that look good on spreadsheets and translate across
technical and non-technical business divisions. Eliminating the increased cost of DR is not
realistic, but those costs can be shifted into other operational line items to reduce the
conceptual "DR cost" sticker:

1. **DR as Perf** - depending on the RPerfO, DR should be representative of some percentage
   performance baseline against Prod. With that in mind, the environment makes an inviting
   target for testing future-Prod performance. This does necessarily incur technical debt
   during each testing cycle when DR/Perf is running a different codebase than Prod. This
   means that a cutover during one of those periods needs to account either for business
   acceptance that users will experience code potentially not ready for Prod or for having
   a Perf-to-DR continuity plan that results in Prod-consistent versions. The latter reduces
   RPerfO risk but moves out the RTO target.
1. **DR as Prod** - this is a true hot/warm model, where DR is fully representative of Prod,
   from a code perspective, so code and functionality released to Prod is simultaneously,
   or very nearly simultaneously, released to DR as well.

But wait - #1, DR as Perf, clearly reduces cost by eliminating the need for an additional
performance environment. How exactly does keeping a warm copy online all the time reduce
any cost at all? Good question, and absolutely correct. Keeping a warm environment is purely
a cost increase on the surface. Reducing the cost, then, is an exercise in how to make use
of that environment to  keep it warm but to also give value back to the business. This is
similar in thinking to option #1 but should avoid the technical debt aspect. All well and
good in theory, but what would this look like in practice?

The Burstable DR
----------------

Referring to the architecture as "burstable DR" is a bit of intentionally misleading
terminology - admit that it sounds good anyway. This is because it is not DR itself that is
bursting at all. Instead, the bursting aspect comes into the picture by applying the warm
infrastructure to an existing environment, for the latter's burst requirements. Since the
model pursues a DR-as-Prod configuration, the most logical environment for burst support
would therefore be Prod itself. Continuing this exercise, using DR to burst Prod means
being able to run multi-site active Production, which placed fourth in the battle cry
survey.

There are some key considerations when designing a multi-site Production:

* **session** - Here it is again, that session mechanic that makes everything more difficult.
  In this case, sessions are commonly driven by stored data, e.g. user preference settings,
  so providing a consistent session experience across environments becomes a product of
  ensuring that user data is successfully mirrored between the sites. The good news is that,
  mechanically, the data is really read-only most of the time, so a multi-write architecture
  is not often a hard requirement.
* **cart** - Although big and scary on the surface, carts are actually very straightforward to
  solve for this model because the data is necessarily transient and also tied to the
  session tracking. Solve carts with the same machinery.
* **sales** - Now the big brother of "cart" in terms of scary. From fraud to inventory to
  shipping, it is critical that sale data be in lock-step between environments, with near-0
  tolerance for disruption. Enter from stage right: the message queue.
* **data direction** - There are two data directions for any application - data in and data out. Data out refers
  to things such as session. These are friendly, because the instance of change is low and
  the data can easily be cached and duplicated across sites. Data in encompasses everything
  else, especially sales, and is wholly focused on writes that modify the data. Here the
  challenge is that a write to site1 may conflict with a write to site2 but that each site
  may be unaware of the operations taking place in the other. So how can these be linked
  together for consistency?

Well that can actually be done, but it's traditionally prohibitively expensive for
medium-to-small businesses and even then remains hugely complex. What if, instead, all
writes queued up in the respective sites and then were processed by the logical (single)
master write system? This would permit data to be consistently enforced by a single point,
which has full knowledge of change.  This would also allow writes that are successful, by
the same token. The other good news is that this model makes use of the existing Prod
machinery - the logical pipeline for bursting is identical to the pipeline for normal
Production behavior.

On the subject of pipeline, here is an example, as a thought-exercise:

1. user accesses website
1. CDN
1. FW -> LB (VIP) -> LB (pool member)
1. Web Server (cache)
1. App Server (session owner)
1. user interaction -> data change (e.g. sale conversion)
1. App -> MQ
1. MQ caches the change, returns receipt of change
1. App -> web -> user => "update received and being processed"
1. <back-end> MQ -> database

In this pipeline there are essentially 2 points of real aggregation - CDN and database.
This means that the application can transparently scale horizontally within a site or
across sites, provided that respective MQ's have knowledge of the appropriate consolidated
database and that the CDN gains knowledge of active sites. Under the hood, the primary
database can transparently replicate data out to other sites or to copies for read-only
operation. This also opens the door to implementing DR procedure as a read-only site, if
such a model meets business objectives.

Fine, this all makes sense, but how does this model burst Production at all? Once the
architecture fits a model logically similar to this, the burst mechanic comes into the
picture via the logical "live" operator. For example, imagine that the DR LB devices have
a healthcheck for pool members that queries a url <site>/burst.html which normally fails
with content "no-burst". The LB will mark all members down, which means the VIP will be down,
and therefore the upper-tier CDN will not use that path for new sessions. Bursting then
becomes a product of changing the burst.html from "no-burst" to "burst", which marks up the
pool members, brings the VIP online, and activates the CDN path. This type of control allows
a business to go from Prod to Prod+ in a matter of minutes in response to load, e.g. Black
Friday.

Rounding Third
--------------

So that's the burstable DR - pretty cool. But wait - there's more! This discussion tackles
some of the specific topics of DR, but the exact same model can be used for numerous other
mechanics that take advantage of horizontally-scaled architecture, for example, blue/green
deployments.

Don't forget, with great flexibility comes great opportunity to screw up! Go forth, and prosper.
