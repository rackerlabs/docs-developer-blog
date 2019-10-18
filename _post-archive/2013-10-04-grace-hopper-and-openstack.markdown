---
layout: post
title: Grace Hopper and OpenStack
date: '2013-10-04 08:56'
comments: true
author: Anne Gentle
published: true
categories:
  - OpenStack
  - Events
---

This is my first time going to the Grace Hopper Celebration of Women in Computing. I've never been to a conference where they take over men's bathrooms to give women fewer lines! There are over 4500 people registered for the conference in Minneapolis. I'm so proud that Rackspace is a sponsor this year as it shows real dedication to adding more women at all levels of our organization. Niki Acosta has a great <a href="https://www.rackspace.com/blog/think-big-drive-forward-inspiration-from-the-grace-hopper-celebration-for-women-in-computing/">post on the Rackspace Blog</a> talking about how great it is to be here. I know this past year has been a great one for me personally as a woman at Rackspace. Adding Diane Fleming as an API writer on OpenStack followed by Dana Bauer as a development community manager makes our team plain fun. And our fellow teammates like to remind others, "we're not just gents you know."<!-- more -->
 
<a href="https://www.flickr.com/photos/50061538@N05/sets/72157631705761394/"><img class="size-medium wp-image-2094 alignleft" style="margin: 10px;" alt="ghc2012-osday" src="https://justwriteclick.com/blog/wp-content/uploads/2013/10/ghc2012-osday-300x193.jpg" width="300" height="193" /></a>

On Saturday OpenStack is participating in the open source day. OpenStack provides open source cloud computing software for computing, storage, and networking and is backed by a non-profit Foundation. Iccha Sethi came up with the idea that OpenStack should participate in Grace Hopper this way. We have been working on growing an inclusive diverse contributor base for years now, because even very extroverted people get tired of talking to each other all the time. Actually, since OpenStack has an in-person Summit each six months to plan features going into the next release, we get to talk to each other quite a bit. And we want to hear from all sorts of different perspectives, it makes our software more interesting to work on. Plus we were all noticing the overwhelming number of guys at our Summits, so we're working on outreach. And, we want to be good at onboarding and welcoming new contributors, so this workshop is a step in that direction too.
 
Our theme for the workshop at Grace Hopper is "Learn about OpenStack and the Open Cloud - connect, network, contribute," but participants are welcome to branch out however they like.
 
<a href="https://www.openstack.org/"><img class="alt= alignright" alt="" src="https://c0179577.cdn1.cloudfiles.rackspacecloud.com/learn-about-openstack-badge.png" width="140" height="180" /></a> 

To set up the workshop, I spun up 20 cloud servers on the Rackspace Cloud using an image with <a href="https://devstack.org">devstack</a> already set up with a non-root user. I ran stack.sh, then unstack.sh, and made an image of the instance in that state. At the workshop, we'll hand out IP addresses and passwords for participants to use devstack for a commit. As a backup plan, I do have Virtualbox instructions using an Ubuntu 12.04 ISO and a devstack.ova file that Ryan Lane created for Lyz Krumbach Joseph and Anita Kuno's use at a CodeChix workshop. Happily Lyz <a href="https://princessleia.com/journal/?p=8526">posted her write up</a> and I was able to use a lot of their materials as a starting point. They also had 32-bit ISO and OVAs on the ready for laptops with 32-bit processors. All of these are on a USB stick, just in case we need them.
 
Based on our experience with a recent Rackspace hackathon, I set up an <a href="https://etherpad.openstack.org/ghc-os">Etherpad</a> for all the participants to access on the day of the event. All the instructions are there as well as on <a href="https://a19e999582c631963c00-293d532ca4b5ec51129fea2cd359dfa9.r73.cf2.rackcdn.com/OpenStackWorkshopGHCOpenSourceDay_print.pdf">a handout</a>. Please feel free to use these materials if you do any workshops of your own.
 
Reviewers, I hope you'll be on the lookout for patches from newcomers. Newcomers, I hope you enjoy working on OpenStack as much as I do. Grace Hopper, here we come!
