---
layout: post
title: "Achieving Success by Successfully Delivering Success Notification"
date: 2015-11-07 10:00
comments: true
author: Jonathan Hurley
published: false
categories:
    - ecommerce
--- 

Defining Success
----------------

For most businesses, "success" can be succinctly defined as "delivering a store and 
processing customer orders". From a business perspective, that's the exact scope - it's 
how an E-Comm business makes its money.

From Online to Offline
----------------------

Although demonstrably enjoyable at holidays, surprises when it comes to product purchases 
are generally frowned upon. Imagine if, after swiping a credit card at the grocery, all of 
the bags disappeared and were probably, but not always, teleported to their destination 
with no indication of which it would be! In essence – Schrödinger’s groceries. To say the 
least, the novelty would wear thin quickly. This scenario (copyrighted, if technologically 
feasible at future date) is analogous to accepting an order in an e-comm application, but 
providing no feedback loop on its status afterward. Those bad old days are long gone, but, 
in their place, stands a new interaction model - real-time feedback.

<!-- more -->

Perception Beats Time
---------------------

The perception of real-time confirmation is functionally the sum of a series of processing 
operations:

1. Time required for fraud evaluation
2. Time required for inventory validation
3. Time required for credit confirmation
4. Time required to render and deliver confirmation

In general, minimizing the first three are part of any standard performance optimization 
exercise, if there is such a thing. These are easy to grasp concepts that translate well 
between technical and business teams, both in terms of discrete numbers (seconds of time) 
and business importance.

The perception of speed, however, is based not on real processing operations but on 
confidence. If a business had complete trust in each of its customer transactions and had 
infinite inventory, then simply placing an order would be equivalent to success with the page 
rendered and delivered immediately. In that model, the delivery time is a function 
only of page rendering and delivery in the environment as a whole. The necessity of a “trust 
but verify” world means that the operations must succeed but that actual confirmation 
need not be dependent on that success.

A Matter Of Distinction
-----------------------

A simplistic example is the difference between two phrases:

1. Your order has been received and is being processed
1. Your order has been processed and shipped

In the former, there is neither implied delivery nor success but only confirmation that the 
pertinent details of the order have been captured and handed off to the next step of the 
pipeline. The distinction may not hold up in court, but, when it comes to the perception of 
performance, the technicality can make all of the difference.

If an application is to not wait on the 3 order conversion dependencies above before 
providing a notification of capture, then where, when, and how will those tasks take place 
without risking the loss of order data? Enter the message queue (MQ).

Spring Clearing House
---------------------

Over simplified, an MQ application is responsible for capturing an order, conceptualized 
as an encapsulated distinct object, and then holding that order for a period of time before 
ultimately handing off the order for real processing. Another term that is sometimes used 
for this dynamic is *clearing house*. It is certainly possible and acceptable for the MQ 
handoff to take place immediately, or as close as possible, after receiving the order. One 
benefit that some frameworks achieve by holding orders for a period of time is to permit 
artificial scheduling so that orders are processed at times of low traffic or in 
conjunction with warehouse operations.

Consider this model:

1. Orders are accepted continuously and in real-time
1. Warehouses operate on a 3-part schedule rotating with a 60m overlap of shifts

Then, if MQ sends orders to warehouses at the beginning of each overlap, there is a 60m 
opportunity for a 2-shift focus on orders unprocessed from last shift as well as a 2-shift 
processing capacity for new orders.

The Human Element
-----------------

In similar fashion to perceived latency or failure in a website, which leads users to 
refresh or reopen pages, users who do not receive order receipt confirmation are much more 
likely to resubmit identical or similar orders, yielding three application challenges:

* **Detection** – programmatically, or through human interaction, detecting and determining 
when an order with similar properties (e.g. name, shipping address, item SKU, item count) 
is a duplicate versus an intentionally similar order
* **Drift** – two orders that are above a threshold of similarity but have drifted (e.g. two 
identical orders with one additional item in a second). This can occur when a user rethinks 
a cart item and makes a change between submissions.
* **Handling** – with identical orders the handling is more straightforward: do not process 
(or back-process) one of the two (or more) orders. In handling drift, however, intent is 
significant and is generally determined by time - the most recent order wins.

Message Received
----------------

The vast majority of customers will not have advanced degrees in systems analysis, and even 
those who do are unlikely to be sympathetic to the plight and complexity of managing the 
confirmation interaction model. The best option is to build a model that does not ask users 
to be concerned with its mechanics.


