---
layout: post
title: Ruled the Stack and Lived to Tell About It
date: '2015-05-29 23:59'
comments: true
author: Walter Bentley
published: true
categories:
  - openstack
  - architecture
---

Last week I had the privilege to attend the OpenStack Super Bowl, aka the OpenStack Summit, in Vancouver.  It was incredible just to be around so many other folks who also believe strongly in OpenStack.

So in between sessions, I stumbled across a friendly competition sponsored by Intel called, [Rule the Stack](https://01.org/openstack/openstacksummitvancouverbc2015/rule-stack-vancouver).  It was a competition to see who can build a fully functioning OpenStack cloud the fastest on (6) six physical servers.  My coworker had mentioned it to me a week earlier, but, frankly, I forgot about it.  I was focused on my two workshops and did not have extra time to plan.  Anyone who knows me would know I love a challenge and never turn one down.  Yes, of course you know I had to sign up to give it a go.

Before going much further, I wanted to fully disclose that I did not win the main prize in any way :D.  I watched the SUSE guys do it in 6 minutes (which is a whole other discussion).  Despite knowing I would not 'win' the competition, I went for it anyway.  For me personally, it was not about winning but was more about solving this real life puzzle in a real-life repeatable way.  The Intel guys appreciated my determined nature and awarded me as the ***'Most Determined'*** participant.

When dealing with OpenStack, one of the challenges is designing an architecture that can scale horizontally and make decisions based on the commodity hardware presented to you.  Holding true to the foundation OpenStack was originally built on, open cloud platform can run on any hardware (OEM or commodity or Open Compute).  This competition pushes you to make all those decisions.

Again, this struck a cord in my heart because this is what I do for a living and because  I believe the approach we take with RPC (Rackspace Private Cloud) makes solving those decisions very easy.

**The quick breakdown of the competition is:**

* You are provided with (6) six physical nodes consisting of (3) three different configurations.  Two node types had the same processor and memory but had a different number of drives.  Then the third node type had a different processor, more memory and TPM module (more details can be found on the Intel site above).
* Had to build using the Kilo release of OpenStack
* The process for building out your configuration was open to you to decide.  You could connect to the local network where the servers are connected via your own laptop or laptops provided.
* There was opportunity for bonuses, shaving time from your final clock time, and penalties could be given for unconfigured nodes or nodes that were not optimized for use.

As soon as I saw the node configurations, I knew exactly how I wanted it to be setup.  Keep in mind, I was not aiming for the fastest build but, rather the most complete flexible real life design.  Despite HA not being a requirement (although I am attempting to have that rule changed for Tokyo (wink wink)), my reference architecture did include a dual server control plane.  Also, I decided to include dual Cinder nodes and, of course, dual compute nodes.  My complete reference architecture is outlined below.

The next step was to determine how to utilize the (4) four VLAN networks part of the provided specs.  RPC asked for three individual network bridges and a management network.  Each node had two NICs, and the first NIC was bound to VLAN 11.  I sort of went back and forth with this decision for a while but finally settled in on one that worked.

![My reference architecture](http://www.hitchnyc.com/content/images/2015/05/rulethestack-ref.png)

At this point, I am all ready to go, but there is still one last decision to make.  How do I lay down the base OS on these servers?  Again, not totally concerned with speed, I wanted to use a way that could be repeatable, flexible and cover the most ground possible without requiring post-install configurations.  After a quick poll of my team, two contenders came to the forefront: Cobbler or MaaS.  I'm not going to say which one turned out to be the most complete option and how I did it, as it could be my secret weapon for Tokyo.  I will say is you would be shocked as to which one turned out to be the best option.

So everything is prepped and the clock starts.  Let’s just say the first time around was not pretty at all.  Did I give up then?  Of course not!  I just signed up to try again.  Second attempt was a bit better, but I literally ran out of time before the next participants arrived (at that point I was still building at the 2 hour mark).  Yes, the third attempt was running perfect, and, yet again, I was stopped because the previous participants had cut into my time slot a bit. My fourth, and final, attempt did the trick. This last attempt would have come in right under 1 hour and 30 minutes, but, unfortunately, I was literally being kicked out by security at the end of the session day on Thursday.

>**Pro tip:** *Sign up early and do not wait until the end of the Summit, as you will not be allowed a big enough time slot to finish.*

All and all, it was a great experience and one that I plan to repeat in Tokyo.  Special thanks go out to the Intel staff on hand in Vancouver - they were the best and very supportive/accommodating.  Just a great set of guys!  Congrats to the SUSE team who I have to assume were the winners in Vancouver.  Good thing mostly about this is...you get another chance to step up and show off your stuff in order to be crowned “Ruler of the Stack”.

**Tsuki ni anata o sanshō shite kudasai!** *(Translation: "See you in November!” per Google :D )*

![Spoils of war](http://www.hitchnyc.com/content/images/2015/05/rts-pic2.jpeg)