---
layout: post
title: "Repose Ninja - WSGI Middleware On The JVM"
date: 2015-10-01 00:01
comments: true
author: Damien Johnson
bio: >
  Damien is a software developer at Rackspace that is currently working on
  the open source Repose project. He graduated from the University of Texas at
  Austin in December of 2013, and has been delivering fanatical results at
  Rackspace ever since!
published: true
categories:
- Repose
- API Management
- WSGI
- Java
- Python
- Jython
- JVM
authorIsRacker: true
---

![The unicorn of the sea]({% asset_path repose_logo.png %})

This is the second in a series of posts written by the [Repose][repose] Ninja
on Duty. Special thanks to [Jim Baker](https://github.com/jimbaker/): author of
the [Fireside][fireside] project, Jython core contributor, and integral braniac
in the effort to support the WSGI specification through Servlet technologies.

If you have ever had the pleasure of evaluating [Repose][repose], you may have
noticed that, while it provides an incredibly powerful foundation, it is
missing that one all-important feature that you need. While the [Repose][repose]
team does its best to handle all common and reasonable use-cases, there are an
infinite number of problems for which [Repose][repose] is a solution. Therefore,
it is impossible to predict and develop features to solve every problem.
Luckily, [Repose][repose] is built on a pluggable architecture that any
developer can leverage to solve the problem of the day.

In this post, I will expand upon the previous post in this series by diving
deeper into the [Repose][repose] extensibility model and explaining how
[Repose][repose] plans to make that model more developer friendly in the future.

<!-- more -->

# The Repose Extensibility Model
It is important to note that Repose was designed with extensibility in mind.
Built on top of Java's Servlet technology, Repose supports loading and running
custom Servlet Filters. These filters have full access to the HTTP request and
response, and may perform any processing that is desired. They are even able to
utilize services provided by Repose, such as the configuration service or
datastore service, with the help of Spring. This is a great start, but there are
still apparent shortcomings.

One such shortcoming has to do with managing the lifecycle of your code. As a
filter, construction, deconstruction, initialization, and destruction are
generally handled by a servlet container. In the case of Repose, the servlet
container only actually manages one filter -- the Repose PowerFilter. The
PowerFilter, in turn, manages all of the filters which compose Repose. What
this means is that the lifecycle of custom filters are tied to the lifecycle
of the PowerFilter, but the PowerFilter has additional control over other
filters. To be more specific, the PowerFilter will destroy all filters and
create new ones any time the system model configuration is changed, or an
artifact in the artifact directory is changed. For code that is meant to be
long-running, this behavior potentially poses an issue. To combat this issue,
Repose uses services. As you might expect, a service is simply a long-running,
shared component. At the time of writing this post, Repose does not support
custom services, but is expected to in the relatively near future.

Another shortcoming is that developing a filter requires knowledge of a Java
Virtual Machine (JVM) language. At first thought, it may seem like I'm saying
that knowing the Java programming language is a requirement to develop for
Repose, however that's far from the case. Quite a few languages are actually
supported on the JVM, though it seems to be a little known fact among developers
lacking experience with the JVM; take, for example, JRuby and Jython, which are
the JVM implementations of Ruby and Python respectively.

Which brings us to the JVM itself, a topic which can, and has, inspired a vast
number of debates, books, and blog posts. To keep it brief, Repose runs on the
JVM, and there is no practical way around it. As a consequence, any extension of
Repose will also run on the JVM. This means that a Repose operator may have to
adjust JVM settings to meet their needs, and a developer should understand the
constraints that the JVM imposes.

Finally, filter development in Repose must adhere to the Java Servlet
specification. Originally, this constraint was meant to provide a well-known
interface to filter developers. Over time, however, the Repose team has noticed
that what developers really want is freedom. The freedom to easily manipulate
any part of an HTTP request or response. The freedom to write a filter
in the language developers are most comfortable with. The freedom to use
existing middleware even when it does not adhere to the Servlet spec. To achieve
that end, the Repose team is investigating a number of solutions, one of which
is the topic of this post: allowing Python WSGI middleware to run as a filter in
Repose.

# Jython or: How I Learned to Stop Worrying and Love The JVM
As a major OpenStack shop, Rackspace employs some of the most talented
Pythonistas on the planet. It would make sense, then, to have those developers
write Python code rather than Java code. Yet, as mentioned above, it would
appear that the Repose project is trying to force Java onto any poor developer
who needs more out of the software. Of course, that's not the case. We've
already noted that there are a number of JVM languages that would suffice for
the purpose of extending Repose, but I'd like to say a few more words about one
that stands out for its synergy with OpenStack: Jython.

So what does Jython give us? Well, it allows us to write Python code.
And that code will run alongside Java code without any problems (most of the
time). We can even import and extend Java classes in Jython code! It also gives
us Java bytecode. Which means, we can run our Python code on the JVM! We can
even import and run Jython code from a pure Java context without knowing the
difference! Although that requires using a tool like jythonc which builds the
intermediary .class file that Java expects. In other words, Jython gives us
fairly seamless integration between Java and Python. Perhaps even more
importantly, it gives us a bridge between the Java and Python communities, and
all of the brilliant minds that have been doing great work in each.

For reading this far, I'd like to commend and reward you. So let's talk
performance. Will Jython run faster than CPython? Will it run faster than Java?
These are great questions that I am wholly unqualified to answer. Even so, for
you, dear reader, I'll give it a shot. For practical purposes, Jython matches
CPython and Java in speed. There are, of course, areas where Jython outperforms
or underperforms, but that is to be expected. An interesting thing to note is
Jython's dynamic language properties and how those properties interplay with
Java's JIT compilation. I suspect that, in the future, we'll see convergence in
performance between these three languages.

To learn more about Jython in its current and future state, check out [this
terrific talk by Jim Baker at PyCon](https://youtu.be/hLm3garVQFo).

# Bridging the Gap between WSGI and Servlet Specifications
This is where things get interesting. The Servlet spec and WSGI spec were born
from two very different environments and, as a result, expect very different
interactions. While I won't go into the history for each, I will give brief
descriptions.

Let's start with the Servlet spec. The Servlet spec defines a Java component
that dynamically processes web requests. A Servlet, and any associated Filters,
are run in a Servlet container (e.g., Jetty) which handles much of what is
defined in the spec. The container will wrap incoming requests in Java objects
representing the Servlet spec abstractions. These objects are then passed on
through a filter chain to the servlet. There is no theoretical limit to the
number of filters which can be defined in a chain, making the filter chain a
terrific place to add auxiliary support or extensions to a web service. As one
might expect, filters are often used to filter out requests that should not
reach the servlet. The servlet itself is the endpoint, where the business logic
for a web service lives. Thanks to Java's type system, working with requests and
responses in a servlet environment is just like working with any other Java
library. That is, interactions with web requests and responses are simply method
calls on request and response objects.

Now onto the WSGI spec. The WSGI spec defines a standard interface for Python
web applications. This interface bears a striking resemblance to CGI in that
there are no unique objects created. Instead, a WSGI app needs only to accept
the correct input (an environment dict and a callback function) and reply with
valid output. As a result, WSGI middleware looks almost identical to WSGI apps
-- there is no distinct abstraction like what the Servlet spec provides with
Filters and Servlets. Middleware will, however, need to be passed a reference to
a subsequent WSGI component. I should mention that WSGI apps are also managed.
Where Servlets have a Servlet container, WSGI apps have WSGI servers.

Due to the differences described above, we're left with a few problems to solve
to achieve interoperability between Repose, a Java Servlet platform, and WSGI
middleware. First is the language barrier, which has been addressed. We can use
Jython to bridge Java and Python. More technically, Jython allows Python code
to run alongside Java code on the JVM. Once we start using Jython, importing
and using Java Servlet classes is trivial, and calling WSGI-compliant apps is
even simpler. With the language barrier out of the way, let's look at the spec
barrier.

To start, since Repose will be passing Servlet objects, we'll have to convert
those into the format a WSGI app expects. The naive solution would be to copy
all of the data out of the Servlet objects into a dict which gets passed to a
WSGI app. Of course, that can get expensive, and there really isn't a need.
Instead, we can build a lazy, caching map adapter, which will take WSGI CGI-like
keys and return the corresponding value from a Servlet request or response. To
get into the weeds, check out the [RequestBridge class](https://github.com/jythontools/fireside/blob/refactor/jext/src/main/java/org/python/tools/fireside/RequestBridge.java) in [Fireside][fireside].

Another issue to be addressed is the difference in control flow. Again, since
we're constrained by Repose, we have to do a bit of work. While the bridge
described above allows our WSGI code to read from Servlet objects, we still
have to write to them. Normally, in WSGI apps, we simply callback to the
start_response callable to set the status code and headers, then return an
iterable which provides our body from the call into our app. Effectively,
the flow in a WSGI app is a series of composed functions. In Servlet spec
land, however, we must mutate the response object. We're given some structure
in the form of the FilterChain doFilter method and the Servlet service method,
but really, these methods only exist to define an interface. To reconcile these
two approaches, we must write a bridge which understands both specifications
and can translate between the two. The approach that was taken in Fireside
wraps a WSGI app with a Servlet Filter, which will provide a callback to the
WSGI app, mutate the Servlet objects depending on the result, and then return
control to the caller of the Filter. To get a more complete picture, and to do
so more concisely than I could here, take a look at [servlet.py](https://github.com/jythontools/fireside/blob/refactor/fireside/servlet.py)
in [Fireside][fireside].

# Wrap-Up
Before I conclude, I have to take this opportunity to recommend that you go
check out Repose if you haven't yet! It's not a silver bullet, but it can do
quite a bit, and it's getting better every day. Running WSGI middleware is just
one of many enhancements Coming Soon&trade;.

If you have any questions, would like to know more, or would like to get
involved in the this effort, please feel free to
[send me an email](mailto:damien.johnson@rackspace.com?subject=WSGI%20Middleware%20On%20The%20JVM)
and/or [check out the Repose project!](https://github.com/rackerlabs/repose)

[repose]: http://www.OpenRepose.org/
[fireside]: https://github.com/jythontools/fireside
