---
layout: post
title: Chef conference recap
date: '2013-05-02 21:43'
comments: true
author: Jason Smith
published: true
categories:
  - Chef
  - Automation
---
{% img right 2013-05-02-chef-conference-recap/opscode_wings.png 250 200  %}
DevOps and automation are all the rage now a days, and [Chef](http://opscode.com/chef)
is at the forefront. I spent Thursday and Friday of last week at
[ChefConf](http://chefconf.com) in San Francisco and heard some amazing
presentations. The presentations were all recorded and are available on
[YouTube](http://www.youtube.com/user/Opscode).


I wrote last week about a couple of keynotes that I attended, which you can
find [here](http://devops.rackspace.com/thoughts-from-chefconf-day-1.html).
This post shares some more of the presentations I was able to attend, and also
talks about the overall key points that all the speakers referenced.

<!-- more -->

One of the overall themes at ChefConf this year was how far Chef has come from
just 4 years ago and how many customer's are using Chef for their orchestration
needs. A few of the the statistics they shared with us are:

- 25,000+ users
- 1,300+ individual contributors
- 200+ corporate contributors
- 900+ community cookbooks
- 30+ local user groups
- Millions of downloads


### IT industrial revolution

We are all in the middle of an IT industrial revolution!  This was repeated
multiple times during the conference.  The first person I heard speak about it,
and who put the most emphasis on this was
[Glenn O'Donnell](http://www.forrester.com/Glenn-O'Donnell). His entire keynote
was based on how the advancements in cloud computing and automation are just as
important as the historical Industrial Revolution was.

Albert Einstein said:

>The significant problems we face today cannot be solved at the same level of thinking we were at when we created them.

So, taking into account Albert Einstein's theory, we have got to continue to
innovate and come up with new solutions for the problems faced by IT.

Businesses love industrialization because of the following points.

- Predictable
- Cost Effective
- Productive
- Managed Risk

There is too much risk in traditional IT, which is why we are now in the middle
of "The next wave of industrial revolution".

It is possible to industrialize IT, and make it run as smooth as a manufacturing
plant.  Admittedly this is a comparison I had not heard prior to reading
[Gene Kim's](http://en.wikipedia.org/wiki/Gene_Kim) excellent book
[The Phoenix Project: A Novel About IT, DevOps, and Helping Your Business Win](http://itrevolution.com/books/phoenix-project-devops-book/).

Put some discipline into your IT by following a couple principles.

- Use [ITIL](http://en.wikipedia.org/wiki/Information_Technology_Infrastructure_Library)
  as a guide for process but avoid the ITIL religion.
- Start with the "low hanging fruit". Change easy things first like incident
  response, change requests, configuration requests.
- Following processes is difficult for the traditional IT professional, it's
  time to break tradition.  Make sure there is a repeatable process for all your
  tasks.
- If the work isn't strategic to your business, why do it?

Hart wrote a post a while ago about *Agility* and traditional architecture versus
cloud architecture which can be found [here](http://devops.rackspace.com/modular-application-design.html).
In this post, he points out that there are services that handle mundane tasks
for you.  Why worry about running your own message queue, when you can have a
service take care of that for you and then your company can focus on your
application, and creating innovative features to provide a competitive advantage.

### Tooling

There was a lot of talk around additional tools to help with Chef.
[Berkshelf](http://www.berkshelf.com), [Librarian](https://github.com/applicationsonline/librarian) and others.

[Jamie Winsor](https://twitter.com/resetexistence) from [Riot Games](http://www.riotgames.com)
gave an incredible keynote on Berkshelf that you can find [here](http://www.youtube.com/watch?v=hYt0E84kYUI).
Jamie explained some of the benefits to using Berkshelf such as resolving and
fetching cookbook dependencies. Using Berkshelf you can keep track of all your
cookbooks in a local directory, **~/.berkshelf** by default. Berkshelf also
creates versioning of these files so in case you forget to check something into
Github you are not out of luck. Installation of Berkshelf is straight forward
and easy to follow. You can find all the instructions on Berkshelf's [site](http://berkshelf.com/).

[Foodcritic](http://acrmp.github.io/foodcritic/) was another tool that was
mentioned. Foodcritic solves for two things.

- To make it easier to flag problems in your Chef cookbooks that cause Chef to
  blow up when you attempt to converge. This is about faster feedback. If you
  automate checks for common problems, you can save a lot of time.
- To encourage discussion within the Chef community on the more subjective stuff
  such as what does a good cookbook look like? Opscode have avoided being overly
  prescriptive which by and large I think is a good thing. Having a set of rules
  to base discussion on helps drive out what we as a community think is good style.

Foodcritic is widely used for automated checking of cookbooks to make sure you
do not run into problems when deploying to production.

[Test Kitchen](https://github.com/opscode/test-kitchen#readme) is a framework
for running project integration tests in an isolated environment using Vagrant
and Chef. You describe the configuration for testing your project using a
lightweight Ruby DSL.

Test kitchen runs through several different kinds of tests, depending on the
configuration. First, it does a syntax check using knife cookbook test. This
does require a valid knife.rb with the cache path for the checksums stored by
the syntax checker. Second, it performs a lint check using foodcritic, and
will fail and exit if any correctness checks fail. For cookbook projects, it
provisions a VM and runs the default recipe or recipes set as "configurations"
(see below) in the Kitchenfile to ensure it can be converged. If a cookbook has
minitest-chef tests, it will run those as well. If the cookbook has declared
dependencies in the metadata, test-kitchen uses Librarian to resolve those
dependencies. Support for Berkshelf is pending. For integration\_test projects,
it provisions a VM and runs the integration tests for the project, by default
"rspec spec". In either cookbook or integration_test projects, if a **features**
directory exists, test-kitchen will attempt to run those tests using cucumber.

Test Kitchen also has built-in [OpenStack](http://openstack.org) support.

An example config for OpenStack:

```python

openstack do
  auth_url "http://172.0.0.100:5000/v2.0/tokens"
  username "bobby"
  password "p4ssw0rd"
  tenant "openstack"
end
```

### Community track

I've noticed a trend in the last few conferences I've attended. They have all
had some kind of an unofficial track. Wayne wrote about this on the
[Rackspace blog](http://www.rackspace.com/blog/reflections-on-openstack-summit-portland-inside-the-hallway-track/)
where he discussed the "Hallway Track". Opscode provided the same thing, but it
added even a little more at ChefConf. They provided a "Community Track", which
included rooms that were dedicated to allow conference attendees the opportunity
to interact with presenters and ask them any questions they had.

These type of unofficial tracks are just as important in my opinion as the official
tracks. This is where the community members meet together and discuss new features,
and future plans for the projects they are working on.

ChefConf was incredible this year, and, as it continues to grow and more companies
become part of the DevOps movement, we will continue to see great participation
at these conferences and an increasing interest in orchestration tools and automation.

Hopefully, I'll see you at next year's ChefConf!
