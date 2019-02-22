---
layout: post
title: "Security automation: Lessons learned"
date: 2018-01-26 00:00
comments: false
author: Charles Neill
published: true
authorIsRacker: true
categories:
    - Security
    - Automation
---

There are many ways to approach the broad topic of "security automation". After
repeatedly trying new approaches, evaluating them against my assumptions and
goals, and modifying them as I learn new things, I've come up with a number
of helpful insights. I hope you find them useful in thinking about your own
security automation goals.

<!-- more -->

### What didn't work

#### 1) Behavior-driven development (BDD) frameworks

I first approached this space through the lens of several frameworks that try
to leverage behavior-driven development principles to automate security tests.
Ultimately, I believe this is a flawed approach. Behavior-driven tests often
look like "ensure the page loads and contains this text"; it's much harder
to write negative tests this way without giving a lot of context. For instance,
to test for XSS you'd have to either 1) write out individual tests for each
form or input ("ensure X form doesn't have XSS of Y type") or 2) abstract away
the details of what's going on under the hood so much that the test loses
meaning in its written form ("ensure the page doesn't exhibit any XSS issues").

Someone smarter than me may come along and figure out how to make this work,
but I suspect that it is a hammer looking for a nail.

#### 2) Installing many tools and managing their local environments

After realizing that existing frameworks didn't quite meet my needs, I started
writing something to manage a sort of local environment for installing all these
disparate security tools and to parse their outputs when executed. Maintaining
all these different Python virtual environments, Ruby versions, and so on
quickly grew unwieldy, and I realized that this was not the problem I really
wanted to spend time solving.

#### 3) Maintaining Jenkinsfiles for each project in a central repository

As I rethought my automation approach, I decided to focus on leveraging Jenkins
since it is a common component of many teams' build processes. I created a
Github repository for each project, under which I created branches containing
`Jenkinsfile`s that configured the tools to run for each code repository
relevant to the project.

This also became unwieldy, and it was a pain to iterate on. Updating the
pipelines across the board (for example, adding a new supported security tool)
required edits to many different repos and branches. While creating shared
libraries helped cut down on the boilerplate code required in each pipeline,
it would've required something like using or building a templating engine to
really make this an effective approach.

#### 4) Asking development teams to run security tools themselves

For security automation to be optimally useful to developers, it needs to be
easy to run the tools, get results, interpret those results, make changes, and
run the tools again. Unfortunately, there is often a fair amount of
domain-specific knowledge required to effectively use many security tools. I
realized at a certain point that just making the tools easier to execute was
only part of what I wanted to achieve. If developers can't interpret the results
as rapidly as they are generated, you're not really optimizing the overall
workflow - you're just hitting the bottleneck faster. In addition to results
that may be hard to parse, security tools may take much longer than a typical
build job will allow. A clear example of this is fuzz testing a web service.
This may generate and execute hundreds or thousands of requests, which is
impractical to force into a gate job.

------

Once I had decided that there was no easy plug-and-play solution, I embarked
on writing my own automation framework to try to overcome some of the obstacles
pointed out above.

### Lessons learned

#### 1) Use the right tools for the job

Trying to orchestrate the execution of numerous security tools, all written
in different languages, requiring different inputs, and providing different
output formats, can be a complicated process. Using the right tools and
mental models can help you overcome these obstacles. More on this below.

##### 1a) Wrappers & JSON output schema

Having a wrapper that converts tool output into a common format (preferably
JSON) makes it easier to interpret results in a standard way and to operate
on findings with one set of tooling. Dealing with all the myriad issue formats
produced by different tools will drive you mad and make your code ugly. Rather
than relying on a hidden "internal" data model, turn all your tool outputs into
a standard JSON format and operate on that. _(Don't forget to document your
output format!)_

##### 1b) Containerization

Using containerization can help you avoid the pitfalls of managing the runtime
environments required for different tools. For example, you might need to run
tools written in Python, Ruby, and Java to test a project written in a different
version of Python than that required by your tool(s). Writing bash (or similar)
scripts to handle installation and updates of such tools will drive you crazy.
Build small container images that you can quickly spin up, regardless of
environment and update quickly as new versions of the tool and language are
released.

##### 1c) Open source prisons

Don't blindly use off-the-shelf tools before evaluating critically whether
they really meet your needs. There are a number of "security automation
frameworks" out there, but I've found that many of them boil down to an
opinionated way of executing a set of tools that the author of the framework
thinks are important. Many of these "frameworks" are really prisons of the
author's own design.

This is not to say "never evaluate off-the-shelf tools". In fact, much of what
I have learned in my security automation journey has come from trying existing
open source tools and finding them wanting. You can learn a lot from going down
the same path others have taken before you. Just be careful not to shape your
goals based on what is easily available to you already.

#### 2) Document relentlessly

If you don't document the heck out of your solution, no one will know how to
use it, and adoption will be slow and painful. If you don't keep your docs
up-to-date, you will waste lots of time answering one-off questions.

If, on the other hand, you commit to keeping updated documentation to describe
your solution, developers might actually _like_ using it!

__What should you document?__

- How to use any associated APIs (including the authentication process, example
  requests and responses, and the data model)
- Reasoning behind standards (PCI-DSS v3.1 mandates use of TLS 1.1 or higher
  to protect against attacks on earlier protocol versions)
- Expectations and constraints (you must fill out form A before doing scan B)
- What to do with results (for example, provide an SSL configuration file that
  resolves common issues, list suggested frameworks for doing user input
  validation and cleanup, and so on)
- Who to talk to (X team owns decisions about exceptions, and Y team will help
  you develop mitigation strategies)


#### 3) Compartmentalize different activities

There are many different kinds of security tests you might want to automate.
Get a clear idea of what tools and processes will be relevant for you. You might
consider the following test types:

- Finding access secrets
- Running static analysis tools
- Analyzing general host security
- Analyzing SSL security
- Analyzing web application responses
- Testing web front-ends for XSS vulnerabilities
- Testing web APIs for various classes of vulnerabilities

There are no right or wrong answers here. But you should ask yourself: "how will
this process differ from other processes, and how will I tie it all together?"
For example, analyzing source code implies somehow acquiring that source code
(say, by cloning a repository), while analyzing a web endpoint requires sending
an HTTP request (or multiple HTTP requests) to an endpoint currently running
the software you want to test.

In general, I believe it's easiest to mentally group the activities that
reference individual primitives (such as Github repositories or URLs). Once you
handle static source code, then you can move on to web application endpoint
testing, for example.

Thinking about how findings are reported by different tools, and particularly by
tools that serve similar functions, can help you design your data model. Pay
attention to how findings are grouped. For example, do findings contain links to
all the affected endpoints (common for host scanning tools)? Is there a file or
git commit that is associated with multiple findings? Thinking about this early
can save you headaches in the long term.

#### 4) Clarify your outputs

What are you looking to get out of this "security automation" of yours? Faster
test results? More fine-grained analysis of defects? Cross-referencing issues
across different projects? PDF reports for leadership? Come up with a list of
outputs you _could_ produce, and then ask yourself, "why?" or "so what?". Let's
look at an example.

_"Report all issues for a given team across all their projects"_

__Why?__

This lets leaders know which projects inside their team need the most security
help. It also helps with identifying common issues that should be addressed
through training or documentation.

If you can't answer the "why" or "so what" with a succinct, convincing
statement, leave it out! Also, if you can't identify a particular stakeholder
who this output is designed for, axe it!

### Conclusions

Thoughtfully assembling a pipeline of security tooling is a challenging
problem. This post doesn't attempt to give you all the answers (your questions
and goals may well differ from mine!), but I hope it can help you avoid some
of the pitfalls I have stumbled upon.
