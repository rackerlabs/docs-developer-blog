---
layout: post
title: OpenStack Miniconf at Pycon AU 2013
date: '2013-07-19 10:15'
comments: true
author: Ed Leafe
published: true
categories:
  - Python
  - OpenStack
---

Friday was the pre-conference day, with two miniconfs: one for Django, and the other for OpenStack. While I'd love to spend some time digging deeper into Django, I figured that given my background as an OpenStack developer, the **OpenStack miniconf** was for me.

<!-- more -->

There were probably 40 people or so in attendance, and it was a good mix of those who were completely new to OpenStack, those who have looked into it a bit and wanted to learn more, and those who either were core developers or (in my case) a former core dev. **Tim Serong** from **OpenSUSE** opened up the day with the talk "**WTF is OpenStack?**", which was an excellent introduction for those who had heard a lot about this "cloud" stuff. The presentation included the classic spoof by The Onion about "[that Cloud thing][1]" (with apologies to **Robert Collins** of **HP**, who really - does - totally know what that is). He covered all the projects within OpenStack, and how they work together.

Robert Collins then followed with a talk on "**Deploying OpenStack using OpenStack**", which tackled the issue that although OpenStack allows you to automate the provisioning of cloud resources, installing OpenStack itself is a terribly manual process. His solution is "[TripleO][2]", which stands for "Openstack On Openstack". It sounds similar to the [iNova][3] project from Rackspace, but with several differences. From the ReadMe:

> TripleO is the use of a self hosted OpenStack infrastructure - that is OpenStack
> bare metal (nova and cinder) + Heat + diskimage-builder + in-image orchestration
> such as Chef or Puppet - to install, maintain and upgrade itself.

**Christopher Yeoh** of **IBM** was next, and gave an excellent overview of the changes coming in **v3** of the Nova API. The current v2 API was smartly designed by making only a precious few critical parts part of the core API, and making everything else an extension to this core. The problem is that some of the implementation details that seemed wise at the time are starting to show some cracks, both with consistency in naming and in the connection to the core Nova code. Nova v3 API addresses these problems by removing the requirement that extension name matches the class name, allowing for cleaner (and thus more consistent) extension naming.  Extensions now must be derived from a common base class; this was optional in v2. Overall, it was apparent that the people working on the v3 API had learned the lessons that the v2 experience offered, both good and bad, and that as a result the v3 API will be much more consistent and robust.

After lunch Tim Serong gave a talk on the state of OpenStack development on OpenSUSE. They are doing some interesting stuff with Crowbar for deployment, and have spent a lot of time on their internal CI processes. I didn't take very extensive notes, as this is an area that I have little experience and/or interest in, but it was obvious that Tim is passionate about this, and that they are doing some excellent work at OpenSUSE.

Next up was Robert Collins again, this time talking about testing, covering both improvements in the tools themselves (e.g., the [testtools][4] module), as well as his work in creating a test runner runner. No, that wasn't a stutter - this is a script to run a test runner, such as Jenkins in this case. With the growth of projects in OpenStack, it can take a very long time to run the tests, which is done when a change is first proposed for review, and then again when it has been approved to ensure that no conflicts have creeped in while the change was in the review process. In order to speed this up, his test runner runner breaks the tests into several parallel processes, and then aggregates the results. This means that the time required to run all the tests  can be reduced greatly, depending on the number of parallel processes. It also provides for test randomization, which can help reveal hidden test inter-dependencies.

Next up was a talk on how to get involved in OpenStack development, which covered the basics of where you can find bugs to work on, or blueprints to contribute to, as well as the review process and Gerrit. **Michael Still** from **Rackspace** was supposed to give this talk, but the birth of his child was a bit more important, so Robert Collins stepped up and did the talk for him. This was more of a review session for me, but it had a lot of useful information for those who were new to OpenStack development.

That was the last talk; after that was the hackfest, which had the goal of getting participants to find a fairly simple bug, fix it, and submit it for review. In practice, though, most of the time was spent helping people get [Devstack][5] up and running on their machines. Those of us who were OpenStack 'veterans' helped where we could, and in the process I had some great discussions with people about OpenStack, so even though we never got to fix any bugs, I believe that the people there who were new to OpenStack got a lot out of that time.

Finally was the bar track! Many of the miniconf attendees, myself included, retired to one of the many bars here at [Wrest Point][6], and enjoyed a cold beer after a long day of learning about OpenStack.


[1]: https://www.google.com.au/url?sa=t&amp;rct=j&amp;q=&amp;esrc=s&amp;source=web&amp;cd=2&amp;cad=rja&amp;ved=0CD4QtwIwAQ&amp;url=http%3A%2F%2Fwww.theonion.com%2Fvideo%2Fhp-on-that-cloud-thing-that-everyone-else-is-talki%2C28789%2F&amp;ei=bWbXUf7nIImJlQXD6oEY&amp;usg=AFQjCNEcXkmkrmnlbsB6LMJ536qQoxH9UQ&amp;sig2=RkUAKTpzWfXZk_nnqb4kJA&amp;bvm=bv.48705608,d.dGI
[2]: https://github.com/tripleo/incubator
[3]: https://www.rackspace.com/blog/how-rackspace-re-wrote-the-cloud-with-openstack-continuous-delivery/
[4]: https://pypi.python.org/pypi/testtools
[5]: https://devstack.org
[6]: https://www.wrestpoint.com.au/