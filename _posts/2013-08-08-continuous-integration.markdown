---
layout: post
title: Continuous integration success depends on automation
date: '2013-08-09 08:00'
comments: true
author: Aliza Earnshaw
published: true
categories:
  - General
---

Continuous delivery — the ability to ship new and awesome features, updates and
patches to your customers more frequently — is key to getting ahead of the
competition, and staying there.

Getting to continuous delivery of quality code that actually works in production
relies on continuous integration: a system for testing code incrementally and
frequently.

Continuous integration is both a toolchain and a discipline. It’s less about the
specific tooling, though, and more about the practice of continually integrating
changes so the system can catch errors and failures while they’re still small
and manageable. Your continuous integration system is what gives your team enough
confidence in its code to ship frequently.

<!-- more -->

The continuous integration system is necessarily complex, spanning the development,
test and staging environments. For the sysadmin, provisioning, configuring and
maintaining these environments — and making sure they accurately reflect the
production environment — can look like a Sisyphean task.

Automation is the key to cutting this task down to size. Just as automation makes
server provisioning and patch management easier and more reliable, it can enable
you to help your development team deliver code faster.

### Automating continuous integration reduces risk

What scares people most about shipping code frequently is the risk of breaking
things. And it’s a realistic fear: Most software is complex, often reaching into
multiple parts of the organization. What looks like a small error at first can
have far-reaching consequences.

Let’s look at each dimension of complexity:

* Speed. Shipping fast scares people because it poses the risk of inadequate testing.
* Lots of changes to lots of pieces. Every change brings with it the risk of
  breaking something, and frequent changes that affect multiple things bring
  even more risk.
* Many people. Fast changes, and lots of them, are challenging enough with just
  one person or group involved. It gets even harder when multiple people are
  introducing changes, because every person has the opportunity to introduce error.

Continuous integration mitigates these risks by testing every new iteration of
your code, instead of testing once a day, or once a week. That limits the damage
that can be done if something breaks. Testing incrementally also makes it easier
to identify and remediate errors.

Automation plays an important role here, by eliminating — or at least vastly
reducing — the opportunity for people to cause errors.

With the risk threshold lowered, it becomes much easier to test frequently. Some
organizations get to the point where they’re testing and deploying many times
per day, resulting in cleaner code — and ultimately, faster release to customers.

### IT operations: Stage manager for continuous integration

Every system and sub-system in the continuous integration flow has to be monitored
and kept consistent over multiple testing cycles — consistent not only to itself,
but to every other piece, and to the production environment.

Automation makes consistency much easier to achieve, and every piece of continuous
integration can be automated:

* Building the dev and test environments
* Configuring each environment
* Maintaining correct configuration for each environment
* Remediating configuration drift
* Scaling up as needed

With every piece automated, you’ve set the stage for testing code both incrementally
and reliably. Sure, you might want to spot-check manually once in a while. But
without automating the vast majority of your testing, it’s almost impossible to
realize the full benefits of continuous integration.
