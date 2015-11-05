---
layout: post
title: "Your JVM – The Importance of Sizing"
date: 2015-11-07 10:00
comments: true
author: Jonathan Hurley
published: false
categories:
    - Ecommerce
--- 

In the good old days the measure of a programmer was efficiency - how much functionality 
could be packed into how much space. Languages like *C* keep code close to the machine 
and require close attention to, and strong understanding of, machine operation for 
performance and code execution.

Much like with the catapult, new methods have come along for launching higher-delivery 
projectiles at high speeds, but, when it comes to hurling a VW beetle the length of a 
football field, sometimes the old ways are still the best. The importance of efficiency in 
code has been maligned, and largely obfuscated, by modern delivery mechanisms; however, its 
effect remains critical to the performance of complex large-scale applications.

<!-- more -->
 
How to crash efficiently
------------------------

Languages that execute code via a virtualization layer (like Java uses the Java 
Virtual Machine (JVM)) bring a host of risks and benefits to the table. One of these soft 
features is the additional abstraction from actual machine execution that is inherent in 
the architecture. Among other uses, this provides the programmer, or friendly neighborhood 
SysOp, a protective buffer from crashing the parent host.

Note: The following code samples illustrate possible problems, so don't *really* run them!

Executing the following C code on a Linux system wold give you a new appreciation of  the 
power and responsibility of direct access to buffers, for example:

```
  #include <unistd.h>

  int main(void)
  {
      while(1)
          fork();
  }
```

So a JVM will never crash? Five minutes of creative development will demonstrate otherwise! 
The following Java code can result in the marvelously familiar out-of-memory errors and 
inevitable interruption:

```
  public class Crash {
      public static void main(String[] args) {
          Object[] o = null;

          while (true) {
              o = new Object[] {o};
          }
      }
  }
```

So a JVM will never crash the OS? It may take closer to 7 minutes, but also not true. See 
the following Java Code example:

```
public class BadDay {
   public static void main(String[] args) throws java.io.IOException {
      while(true) {
         Runtime.getRuntime().exec(new String[]{"java", "-cp", System.getProperty("java.class.path"), "BadDay"});
      }
   }
}
```

If both models can bring down a server, then is there a real difference? Yes and no – the 
difference is really a product of programmer habits, methodology, and soft education, 
rather than of the architecture or capabilities of one language over another.
 
Habits
------

Programmers are lazy (sorry, programmers). It’s the guiding tenant of everyone who enters 
the technology ecosystem. If finding an easier way wasn’t the goal, then why spend 1m 
man-hours building a software mousetrap?

Consider the Uber application. Fundamentally, it operates under the principle that it’s too 
complicated, or time consuming, to find a driving service, and that riders and drivers 
can be connected via a simple interface. The outcome is that lazy riders, almost certainly 
including its programmers, expend less effort in accomplishing A-to-B.

So it’s a good thing? It certainly can be, but the habit doesn’t stop at entrepreneurial 
chauffeur services.

Cogitate on the purpose of garbage collection (GC) in programming languages. Well, useless 
objects accumulate in memory and have to be cleaned up. That's common sense. No question, 
but compare garbage collection in native C to Java, and it becomes rapidly apparent that the 
more modern, Java found a lazy way to accomplish A-to-B. Programmers not being required to 
contemplate and implement garbage collection has saved countless man-hours. However, another 
outcome also entered the picture – programmers started to not care about “how”. So what, 
the JVM takes care of GC already, right?
 
Methodology
-----------

Whether paid by lines of code (in a programmer-perfect world), project delivery cost, 
delivery timeline, or any other number of metrics, every programmer is developing code 
against a specific requirement target. Unless coding the shutter control algorithm for 
Discovery’s camera system, operational efficiency and execution footprint are not overly 
likely to be at the top of the list of requirements. That’s not inherently wrong. 
Businesses have different priorities, and modern computing systems have moved mountains to 
reduce the importance of efficiency. The upshot is the *write code that works* approach to 
projects and a focus on results. That being said, a program that creates 10% more objects 
to accomplish the same operation is likely to result in less efficient GC. 

Soft Education
--------------

One of the most significant shifts in software programming over the past decade or two is 
the integrated development environment (IDE). From syntax highlighting to tab completion, 
these powerful tools help developers to be better at being lazy as well as reducing time 
to delivery. Both are very important in a results-first approach. Another critical 
side-feature of the IDE is the increased ease with which large project teams can collaborate.

Collaboration – that’s definitely a good thing, isn’t it? When it comes to programming 
security systems for an island-bound dinosaur park, collaboration certainly helps to reduce 
the dependency on a single developer. Unfortunately, fluid collaboration also carries a 
significant risk – obfuscation.

In object-oriented programming (OOP), the tools of collaboration rise to the surface with 
ease - one widget object needs to combine with another widget object to create a 
super-widget object. Everyone wants a super-widget, after all, so what’s the problem? 
Provided that the two widgets are able to communicate, there is really no need for either 
development team to wonder as to how the respective sub-programs actually work, nor at 
their efficiency, but a chain is only as strong as its weakest link.
 
What does any of this have to do with JVM sizing?
-------------------------------------------------

The logical size of a JVM is a combination of several metrics, including the following:

* *Minimum Heap*
* *Maximum Heap*
* *Permanent Space (max)*
* *External Operations*
* *Garbage Collection*

One of this author’s most common arguments opportunities for collaborative discussion 
involves the phrase “max heap is ___ MB, so why does the system keep running out of memory?”
The truth is that there is no single setting, nor value, that enforces a maximum JVM size, 
other than the combined physical memory and swap space of its host OS. So could any JVM  
runaway and take all of the system memory? No, but it’s most common for JVM application 
servers to be sized based on the expected JVM size plus a small amount for the OS overhead.

What’s the point of setting the 2 dozen flags for the JVM if none of them control the 
memory footprint? The purpose is to set boundaries, similar to having multiple file systems 
divided across partitions on a server. When developing the “thunderdome.java” application, 
competition to the death would be an exciting feature. For all other applications, it’s 
important that the heap not clobber the permanent space in its quest for one more MB. The 
most important distinction is between conceptually guaranteed space versus a limit.  

The Kit and Caboodle
---------------------

JVM reliability, as a product of not being killed by OOM, is critical to any business 
practice. That’s all well and good, but even the most stable applications need to be 
restarted at times, so what does this have to do with memory efficiency?

A strong recommendation by the modern JVM community is to run with equivalent settings 
for minimum and maximum head (Xms and Xmx). That’s because front-loading the largest memory 
resource of the JVM at start means avoiding the slow, and potentially unreliable, growth 
from min to max. In addition to that benefit, this type of configuration also means that 
restarting the JVM requires full memory allocation before the JVM, and its applications, 
become functional. The gap between a 512M and 1GB head seems, and on modern systems 
typically is, trivial. Consider, however, the time required to statically assign and address 
4GB versus 8GB of RAM. Add in a bit of overhead for paravirtualization in the modern market 
place and JVM heap size starts to look really important to maintenance operation planning.

No matter how well written, tested, and supported the application, there is almost always 
a risk of unexpected crashes and performance degradation. That’s what a thread dump is for, 
right? In many cases, yes. While we’re considering time-to-recovery of an application, let’s 
add in the difference between dumping 4GB of addressed memory to file against the same 8GB 
above. The beefy 8GB application is starting to look very time-expensive under pressure, 
precisely when time costs are most critical.
 
Compartmentalize the Complexity
-------------------------------

If an E-Commerce store could be efficiently run in BASIC, then there would probably be a 
market demand. Lacking the latter, it could be that more complex but comprehensive frameworks, 
such as Java, are in demand because they solve the needs of the former.

Just because the goal, and comprehensive operation, of an application is very complex, 
however, does not necessitate that a single application thread perform all functions. For 
example, it would be very straightforward to write code to perform catalog search 
optimization. Since the owner of SOLR already did that with their SOLR application, there is 
seldom need to reinvent that wheel. The same principle can be applied for other operational 
components. Probably true, but why?

Density is a very important modern computing concepts: how many VMs can fit on a hypervisor? 
How many products can squeeze into the database? How many concurrent visitors can pack into 
the application? In large part, density is about vertical scaling. For many aspects of the 
architecture, this is a critical sub-topic. When targeting an efficient JVM, however, there 
is a break-even point unique to each application after which vertical scaling on the host 
system (like adding memory resources to the heap) have diminishing incremental returns. 

It’s at that point, or ideally right before, that the application begins to scale 
horizontally instead. From a purely load-based perspective, this is very simple: *One more 
user is beyond the threshold, so it’s time to add another server*. This same thought-exercise 
can be applied to JVM scaling as well: *One more MB of heap will be inefficient, so it’s time 
to add another JVM instance*.

The distinction, however, is that non-load-based horizontal scaling for the JVM means a 
division of labor. Imagine an application for ordering widget1 and widget2 from a catalog. 
At first, a single JVM can efficiently manage the entire order process. As the 
market for widgets expands it becomes necessary to distinguish between visitors and 
conversions (sessions that are only browsing the catalog versus sessions that are in 
the process of placing an order). Extending the thought-exercise further, when demand becomes 
so great that a single JVM cannot manage the catalog for both widget1 and widget2, then an 
optimization can be sought for more specific functional compartmentalization focused on each 
widget individually.
 
Bring ‘em home, Casey
---------------------

As the vehicles to develop and deliver software solutions become more complex, which shows 
no sign of slowing, the surface for introducing inefficiencies continues to expand. Doomsday 
predictions aside, the most important question to ask during the development and support 
lifecycles is “why?”:

* Why does the software require 8GB of RAM instead of 4GB?
* Why does it take 45 minutes to restart the cart application?
* Why is it so hard to find the source of a problem from a thread dump?
 
TL;DR – start as small as possible without compromising performance, then try to perform 
when smaller than that.
 
Good Luck!