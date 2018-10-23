---
layout: post
title: High Load in E-Commerce (pt 1)
date: '2015-11-13 10:00'
comments: true
author: Jonathan Hurley
published: true
categories:
  - database
---

### The Illusion

The number of Thanksgiving evenings that have been ruined by the phrase "we didn't load
test for this" is incalculable.

The real challenge of being prepared for a CyberMonday is caused by a misconception - load
testing is designed to generate hits, views, or raw load. What this strategy misunderstands
is that *1000 concurrent connections* is not the same as *1000 concurrent page views*.
Instead, it is an amalgamation of multifaceted behaviors that drive load in specific,
often non-overlapping, directions. Properly load testing for an ecomm flood requires accurate
metrics of *normal* traffic and a multiplier like the following data points:

* How many concurrent visitors are expected?
* What is the daily conversion rate?
* Are there hot-spots, such as new or sale items?
* Does order management (OMS) share servers with other functional components?
* How quickly can resources be added into the environment?
* And probably the most difficult question of all - what is acceptable loss?

<!-- more -->

### Acceptable Loss

ECommerce is about one thing - money. Just like any money-making business, there is a
break-even point after which every sale is conceptually profit. During heavy load scenarios,
it is common to encounter situations where one or more of the following difficult decisions
must be made:

* **You can convert some of the orders all of the time** - if there is a high confidence
level that 75% of the current traffic would accomplish 100% performance, then the best
option is sometimes to throttle incoming connections. This means that for some percentage
of users, 25 in this example, the experience will not be as positive as hoped. Some lower
percentage will not return, resulting in lost sales. A theoretical maximum lost sale value
of 25% of visitors beats an actual loss of 50%, if the environment is dropping cart data.
* **Shoot the puck, Mario** - users who add items to cart, sit at an order completion
page, or simply idle on the home page all have 1 thing in common: they are wasting a thread.
In preparation for, or as a response to, heavy load it is sometimes appropriate to be more
aggressive with the thread life cyle and to limit TCP ttl, thread duration, and a host of
other tunables to prevent thread aging. Load testing should be used to determine an optimal
lifecycle under load, and plans should be prepared to achieve that reality.
* **Something is better than nothing** - it will not be universally true, but the vast
majority of ecomm environments have the option to present static catalog data rather than
an outage or maintenance page. In this scenario, although orders are not converting, the
perception is that the business is remaining active and alive. It also offers options for
managing order queueing in pursuit of long-response conversion.
* **No rest for the wicked** - one of the most common trends in ecomm, especially following
any significant load event, is to extend sales and marketing; it is therefore prudent to
plan for d+1 days of load duration. In general, if one of the above difficult decisions has
not already been reached, then day d+1 will be more of the same.

### The Red Herring

During high load scenarios, it is very common for technology teams to be mislead by a number
of metrics including system load, TCP resets, database I/O performance, concurrent threads,
and so on. In any given situation, some or all of these will be relevant. However, it is
very uncommon for any one to be the root cause and even more uncommon for there to be a
single, isolated cause.

For example, if users are not able to add items to a cart and the application servers
periodically spike load then dissipate, then there must be a problem with the application.
Potentially. You might also considering the following options:

1. Is the database is at its maximum number of threads, causing it to refuse new cart
  transactions?
1. Is there a balancing distribution issue resulting in load roaming?
1. Are the failing adds even unique sessions?

The delicate balance of proper investigation against timely response is consistently at
odds with business requirements, and, especially during holiday load peaks, the added stress
of a C-suite bridge line or email thread can throw the entire process into disarray. As a
result, it is advisable to have pre-packaged responses to generic issues like the
following scenarios:

*  customers can add to cart but can't checkout
*  5% of customers are receiving an outage page
*  conversions are processing but customers are not being notified
*  shipping label processing is off the rails

None of these incidents, or many others, require an actual solution in the moment. Instead,
the most effective peak responses often take the form of asking the question: how can x be
cached until the application can be fixed? For example, if conversions are completing but
notification is failing, can a static "order received" response be provided then followed,
sometimes days later, by an actual order confirmation as expected. The answer is most
commonly that such a solution would have needed to be developed and tested months ago. This
is not inherently wrong. So start developing. Right now.

### Do Our Customers Hate Us?

It's possible but far more likely that customers are following one of the most prevalent
high load mannerisms in all of ecomm - F5. Under load, an application can manifest numerous
behaviors that customers are not used to experiencing, sometimes as simple as an extra
second or two of response time. On today's Internet, visitors consider a site unresponsive
after five to seven seconds of delay. Any teenager will tell you that the real cutoff is closer
to two or three.

So what? If the site isn't broken, does a second or two really matter? No, not
if the application can handle three to five times actual load and be intelligent enough to
drop duplicates. This is, of course, a tongue-in-cheek response - it shouldn't and almost
certainly can't. When a visitor reaches their timeout, which is personally defined by each
individual, the tendency is to take one of two actions: refresh the browser or close it and
reload. For most sites these actions have the same result - the visitor now has two active
threads. There is room for variance, but generally an application will react to this
situation by attempting to complete both threads based on load. Unfortunately, one of the
threads will almost certainly end as soon as it completes.

Discussing how to kill duplicate threads more quickly will be a subject for a later time,
but avoiding them altogether would be a good trick.

### The Kansas City Shuffle

It is important to recognize that, when combating Internet behavior, the application is
fighting a battle of perception and not performance. If Widget Co. visitors receive a
sub-two second response 360 days per year and on the remaining 5.25 days visitors receive
a four second response, then the site is "broken". If Competitor Co. visitors, however,
receive a four second response every day, then the site is "working". There are two
important takeaways: know what users are expecting, and deliver it.

Obviously no ecomm company desires, nor intentionally delivers, slower performance under load.
The performance, however, is not the issue. Rather, it is the perception of performance that
must be achieved. One counter-intuitive strategy is to map high load responsiveness and take
steps to deliver that performance every day, instead of the more common *best performance
possible* approach. This will be effective where the delta between normal and high load
performance is small. Another option is to build a static, cacheable application that is
served first. For example, if 60% of high load page views do not convert, then having a
fully cached site delivered to those 60% within a response window means that those visitors
are far less likely to spawn refresh sessions.

An additional aspect of perception over performance is queueing. When a customer submits
an order two things are expected - order confirmation and, eventually, the ordered product.
There's not much that can be done about the latter; if the product can't be produced or
delivered, then the company won't be in business for long. The former, fortunately, can be
delivered with a bit of forethought. During high load scenarios, processing an order can
take minutes or longer, during which customers are often watching a loading screen or,
worse, seeing a blank page. An effective strategy to avoid this situation is to have an
order queueing system that accepts the order but performs post-processing to actually
complete and send to shipping. This approach provides immediate feedback to the customer
without increasing actual load or time against the OMS.

### Conclusion

EComm designers are wrong twice - once when anticipating load and performance and again
when trying to solve it. That's ok. They say, "No plan of operations extends with certainty beyond
the first encounter with the enemy's main strength." Yes, the customers are definitely the
enemy.

Effective performance during high load is the direct product of three factors:

1. Try to think of each thing that could go wrong, and solve it
1. Have the flexibility to react to all of the situations not covered by #1
1. Know when, and how, to throw in the towel

Good luck.
