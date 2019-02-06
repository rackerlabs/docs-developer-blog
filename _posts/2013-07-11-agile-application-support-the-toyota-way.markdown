---
layout: post
title: 'Agile application support: The Toyota way'
date: '2013-07-11 11:14'
comments: true
author: Kyle Claypool
published: true
categories:
  - General
---

Agile. Scrum. Extreme programming. RAD. Lean. These terms all represent a
departure from the traditional Waterfall development process in favor of a more
rapid, iterative approach to application development. For companies with
large-scale web applications, there are significant benefits to the agile
methodology, but it also presents significant challenges.

When every minute of downtime represents significant lost revenue and increased
support costs, it stands to reason that application support should be just as
agile as application development. Among other things, this means tearing down l
ong-standing walls between teams, and getting all business units working together
toward common goals.

<!-- more -->

{% img center 2013-07-11-agile-application/reagan.png %}
<p style="font-size: 70%; text-align: center">Image courtesy of the Reagan Library and Michael Evans</p>

With agile development, those walls were primarily between the developers and
the business group or end customer. Feedback was rarely solicited, and documentation
was valued far more than collaboration.

Agile support has its own set of walls. Developers and ops managers are constantly
at odds. “Worked in Dev - it’s Ops’ problem now” is not an uncommon sentiment.
Ops often have similar opinions of developers.

The principles that have made agile development a success can (and should!) be
carried through to the support of production applications. Start thinking in
terms of individuals and interactions, rather than systems and silos. I don’t
care what you call it - lean, agile, DevOps, Kaizen, whatever - implementing
these principles is critical to the health of your application (and support team).

### Bringing lean principles to agile support

Years ago, we built an online training system for some automotive clients, and
did some work with Toyota. We created systems and Standard Operating Procedures
(SOPs) - not for manufacturing, but for automotive and collision repair. Agile
support for vehicles, if you will.

Toyota had partnered with DCR Systems, a chain of collision repair shops whose
mission was to reinvent the entire business model - literally designing the
building and everything in it for maximum efficiency. The results were impressive:
a 60% reduction in repair time and a significant improvement in customer
satisfaction while reducing overhead such as facility size by 30% or more. In
other words, they were doing significantly more with less, and making customers
happier in the process.

So, what does development support have to do with collision repair? Surprisingly,
there are a lot of similarities:

* A customer comes to you with a problem - in this case, they smashed their car.
* You open a ticket for the bug fix, and gather some information on what went wrong.
* Next, your team begins to take things apart, looking to identify the extent
  of the problem and any related issues this problem may have caused or exposed.
* You draw up a work order for the repair, allocating specific resources and team
  members to the project.
* You complete the repair, go through a rigorous QC process to ensure there won’t
  be any re-work, and make sure everything looks as good as new.
* If you run a traditional shop, systems are lacking. Diagnosis is rushed,
  repairs run 3x longer than expected, and the customer is calling daily asking
  when the repair will be done. Systems are only loosely defined and “that guy”
  is the only one who can perform a critical task in the process, inevitably
  becoming a bottleneck to the entire system. The whole process is frustrating
  and stressful and exhausting (for you AND your customers).

DCR Systems tore the collision repair model apart and rebuilt it from scratch to
address these shortcomings. Many of their principles can be carried over to the
application support process:

### Create your application support plan before you have an application

This should be common sense. If you fail to plan, you plan to fail. DCR built
brand-new facilities specifically designed for efficient, lean workflows. They
created a blueprint for success before ever breaking ground.

{% img center 2013-07-11-agile-application/process.png %}

Do your developers follow consistent coding standards? Consistent standards for
logging errors and exceptions? Do they name variables, functions and classes
uniformly? Are they commenting and documenting their code? Remind your team
throughout the development process that each of them will be involved in the
support process. Not just supporting their own code, but the code written by
their peers.

Beyond the development process, what does the support workflow look like? Have
you ever mapped it out in a flow chart? This can be an eye opener. Map out your
support process, beginning with a bug being reported and ending with notifying
all involved parties that the fix has been implemented and the ticket closed.

Get as detailed as possible. What tools are being used to diagnose problems?
Who is involved (list positions, not just “Bob”) at each step?  Now, pick 3 to
5 recent bugs and see how well they fit into the ideal workflow you’ve defined.
Keep an eye out for the following:

* Where does the most time pass? Are requests getting hung up by a specific
  person or team?
* Could the support process be streamlined by involving QC and Ops team members
  earlier in the development process?
* Are there any patterns emerging, where refactoring part of the code or
  upgrading hardware would immediately reduce recurring support costs?
* Are you wasting a lot of time looking for tools that are scattered all over
  the place, when there are more efficient tools available?
* Is QC integrated throughout the process, or tacked on to the end?

### Tear down walls and eliminate bottlenecks

DCR took this one very literally. They found that one major bottleneck was
constantly pulling cars into and out of repair bays. In a crowded space with
parts and tools scattered haphazardly, how do you move a disassembled car from
one station to the next?

Their solution was revolutionary: cars were put on tracks that could be pushed
through the shop with minimal effort, without having to start the car. Walls
between bays (even the paint booth!) were easily raised and lowered, allowing
the car to move through the process as if on an assembly line.

{% img center 2013-07-11-agile-application/car.png %}

Your walls may be between your dev team and your ops team. Maybe your developers
don’t have access to the production environment to monitor application health.
Maybe your sysadmins have never been involved in the development process. Maybe
the business unit, dev team, and ops all operate largely in a vacuum, each
regarding the other two with suspicion and thinly-veiled animosity. Every
departmental wall in your organization destroys unity and engenders a “not our
problem” mentality.

### Optimize your environment

This goes a little deeper than ensuring that your caffeinated beverage of choice
is placed for optimal efficiency. For DCR, this meant clearly defining the purpose
for each repair bay, and then placing the right parts and tools (and ONLY the
necessary tools) within optimal reach.

{% img center 2013-07-11-agile-application/tools.png %}

What does this mean for your company? First, take a look at your physical
environment. Is there evidence of silos between divisions, based purely on office
locations? Could you improve efficiency and collaboration simply by putting dev
and ops teams closer together?

What about your tools? Do your developers have access to everything they need
to diagnose application errors? Do they have to hunt through numerous [log files][1]
and bother sysadmins to get the information they need? Are there better tools
out there that could automate, aggregate, and simplify these things?

### Make performance numbers public

What’s the best way to improve performance? Display current performance very
publicly, color-coded to show the good, the bad, and the ugly. If your key
performance indicators (KPIs) are visible throughout the office, it creates a
new degree of urgency:

{% img center 2013-07-11-agile-application/metrics.png %}

Just as importantly, a status board that shows all green creates a sense of
pride. Your application is running at an all-time high load and all systems are
performing perfectly? Awesome! Your team just reduced the average ticket time
by 15%? Time to celebrate. Which brings me to...
Incentivize process improvement

Lean principles only work when there is a culture of continuous improvement
within a company. When every person is empowered to make (or at least propose)
changes, truly great things happen.

Toyota has legendary stories about this sort of culture. The Kaizen principle
states that if a change will save more than two seconds each time a task is
performed, it’s worth evaluating. According to Toyota lore, one of the women
who made tea in the company cafeteria once received the company’s highest honor
for cutting costs by tracking tea consumption by day and time and reducing the
amount being wasted.

Does your company culture reward its employees for saying “I think there’s a
better way for us to do this,” or do people hesitate to stick their necks out?
The DCR Systems culture rewards ingenuity publicly. If someone proposes an
improvement that gets adopted, they may receive a gift card to take their spouse
out to eat, or might get to take a half day that Friday. Imagine having this
conversation with your supervisor:

Dev: Where’s Tom?
Supervisor: Oh, you know that idea he had to modify the structure of database
calls to perform better under heavy loads? Well, it’s saving us a bunch of time
and money, so I gave Tom the afternoon off. He and his wife are having dinner at
(insert fancy restaurant name here).

You can bet that’ll start to change your culture.

### About the author

[Kyle Claypool][2] is a technology marketing consultant for Stackify, an
[application and server monitoring service][3] that facilitates agile application
support. Kyle writes and speaks about the intersection of marketing and technology.

[1]: http://www.stackify.com/11-ways-to-tail-a-log-file-on-windows-unix/
[2]: https://twitter.com/kyleclaypool
[3]: http://www.stackify.com