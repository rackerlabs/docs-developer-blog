---
layout: post
title: 'Thoughts from ChefConf: Day 1'
date: '2013-04-26 8:00'
comments: true
author: Jason Smith
published: true
categories:
  - Chef
  - Automation
---
{% img right 2013-01-09-cooking-with-chef/chef_logo.png %}
Hello from Sunny San Francisco! Today is day 1 of ChefConf, a Devops focused convention. Developers and Engineers come to ChefConf to learn about Opscode's latest features and learn from their peers. Below I'll talk about a few of the sessions I attended today. 
<!-- more -->

## Keynote Presentations
### Opscode
We started the day off with some great keynote presentations.  The first two were by Opscode CEO Mitch Hill, and Opscode CTO, Chris Brown.
Mitch discussed the rebranding that Opscode has just gone through.  They launched a newly desiged [website][1]today with their new company motto, "Code Can", which you can read more about on their [blog][2]. Below are just a few of the things 'Code Can' do:

* Code can accelerate your business
* Code can scale
* Code can drive innovation
* Code can safeguard your business

Mitch also talked about how just a few years ago we (IT) were the back room engineers and got blamed for everything that went wrong, with very little recognition for anything that went right. Today IT is 'at the tip of the spear'.  We are the decision makers, every part of the company and business relies on IT. 

CTO Chris Brown began by quoting [The Phoenix Project][3] 

> “In ten years, I’m certain every COO worth their salt will have come from IT. Any COO who doesn’t intimately understand the IT systems that actually run the business is just an empty suit, relying on someone else to do their job.”

Then continued by talking about some of the improvements since last year's ChefConf. Just a few of which are:

- Rebuilding chef-server 
    - Rebuilt in erlang + postgresql
- Scale
	- Built a 10,600 node cluster all backed by **one** chef server to test scaling capabilities.
- Documentation
	- Completely rewritten [documentation][4]
	- Broad set of resources specifically to help [learn chef][5]
- Expanded Enterprise support for even more architectures
	- Solaris, AIX, and many more
- Using knife-essentials to treat Chef server like a filesystem available on [github][6]

He finished up by showing a live demo of their new Private Cloud webUI and knife features.

### Facebook

[Phil Dibowitz][7] shared how Facebook is using Chef to manage their enormous infrastracture with only 4 Devops engineers!
A few of the important questions that need to be asked at the beginning of implementing an SCM (Software Configuration Management) system.

- What is scale? 
	- How many homogeneous systems can you maintain?
	- How many heterogeneous systems can you maintain?
	- How many people are needed?
	- Can you safely delegate delta configuration changes?
  
To answer each of these he explained the process Facebook went through, and how they decided on Chef.
The solution must have the following.

- Distributed system (everything on client (duh!))
- Deterministic (The system configured how you want on every run)
- Idempotent (only necessary changes)
- Extensible (Tied into internal systems)
- Flexible (No dictated workflow)

To test each of the steps outlined above they setup a Chef 11 server and registered around 7,000 nodes. The CPU idle never went below 70%. This proved Chef can successfully be used for large scale deployments.
They now manage way over 17,000 nodes with a team of only 4 people. They are able to do this by allowing developers to make changes in their cookbooks which overwrite the global attributes. For example defining the sysctl.conf settings through cookbooks.
There were many other amazing sessions I was able to attend today, and I look forward to tomorrow.
Stay tuned for another post containing more next week!

[1]:	https://www.opscode.com/
[2]:	https://www.opscode.com/blog/2013/04/25/introducing-the-new-opscode-brand-code-can/
[3]:	https://www.barnesandnoble.com/w/the-phoenix-project-gene-kim/1115141434?ean=2940016781068
[4]:	https://docs.opscode.com/
[5]:	https://learnchef.opscode.com/
[6]:	https://github.com/jkeiser/knife-essentials%23readme
[7]:	https://twitter.com/ThePhilD
