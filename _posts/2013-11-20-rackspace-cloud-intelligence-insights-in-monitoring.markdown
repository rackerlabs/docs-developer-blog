---
layout: post
title: 'Rackspace Cloud Intelligence: Insights in monitoring'
date: '2013-11-20 15:55'
comments: true
author: Mary Stufflebeam
published: true
categories:
  - cloud monitoring
---

Drowning in data? You probably just started monitoring your application.
Modern applications overwhelm users with an avalanche of [metrics][1]
representing their functions and behaviors. Sysadmins are flooded with alerts
about their CPU or Network I/O crossing preset thresholds. Developers might be
watching a stream of application-level metrics like the gossip protocol activity
on a [Cassandra ring][2]. Overwhelmed, they’ll either turn off their
monitoring tool, spend weeks tuning it, or give up and accept the
unstructured noise.

Rackspace Cloud Monitoring currently samples about 40,000 metrics per second
across our cloud-hosted instance flavors. This data accumulates minute by
minute and more checks are enabled every day. There's a lot of data here—an
automated layer of intelligence over our cloud environments could really
[help][3].

<!-- more -->

Capturing meaningful insights, metrics, or measurements from real-world
systems is hard. Configuring those monitoring alerts to get the right
balance is [even harder][4]. The goal is to be notified only when something
is actually wrong, or about to be broken, and never when there is nothing to do.

Even after our industry’s many attempts to solve these problems, most
applications expose only the most minimal instrumentation. Most users
under-monitor and under-utilize the features of their monitoring systems
because the burden of understanding and configuring them is too high. So
instead of using these sophisticated tools, businesses tend to focus on the
simplest availability metrics and miss out on cost-savings,
bottleneck-eliminations, and other optimizations. This results in missed
warnings and things catching on fire!

{% img center /fire.gif Things catching on fire! %}

I joined the new Rackspace Cloud Intelligence team four months ago to help
analyze this abundance of monitoring data. I loved studying machine learning
at UC Berkeley, so I was excited to see more real-world applications of a
variety of awesome algorithms and statistical techniques. We are deriving
knowledge from the user's raw data and existing configurations to produce
high-value observations. This stands in contrast to products that present the
user with a feature-rich interface that requires deep understanding and
in-depth configuration. We're exploring a variety of approaches to the
challenges of turning the seemingly meaningless noise of real-world systems
into useful, actionable insights.

We want to know when and why things go wrong for our users and how to define
wrong. This is hard because it requires embodying human judgement in the
logic of software. An experienced sysadmin would be able to set up the
appropriate thresholds and conditions to monitor the health of his or her
specific environment. The primary objective of the Cloud Intelligence team
is to expose relevant information, like this sysadmin’s understanding, and to
help users resolve issues with their infrastructure.

There are lots of ways we could have chosen to approach this problem. We
started with two powerful sets of algorithms: [anomaly detection][5] and
[pattern recognition][6]. Each work well, but together they have some
promising implications. Putting this combination to work requires
careful engineering.

### Anomaly Detection

Our anomaly detection identifies abnormal spikes, dips, and jumps on the
metrics that you have configured in the cloud. An anomaly means more than
just going above or below a threshold—we capture abnormal occurrences by
understanding what is “normal” for your system.

{% img center /anomalies.png Anomalies in metrics %}

We started with a variation on [Bollinger Bands][7] because they’re simple
and provide relative definitions of high and low values per time series.
Traditionally, Bollinger Bands use the same number of points to calculate
the moving average and the moving standard deviation. We’ve found that using
a larger span of time for the standard deviation than the moving averages
works better. Using a smaller window for the moving average results in a
closer fit for the more recent values, which allows the algorithm to be more
robust to trends.

By using a larger window for the standard deviation, we capture the normal
amount of variation on each metric without it dropping to the minimum
standard deviation during short periods of constant values. This is a useful
statistical approach because users' systems and applications frequently
maintain steady states with intermittent periods of activity. We also apply
some additional analysis to the output of Bollinger Bands to filter out
periodic behavior or otherwise normal behavior.

### Pattern Recognition

Our pattern recognition algorithm finds similar behaviors across different
server instances in your environment. We start by smoothing the time series
by mapping to a set of discrete states via [first order differencing][8].
This way we get the movements between the points in the time series, which
captures change in the metrics regardless of raw magnitude.

{% img center /pattern.png 400 800 A pattern between two metrics %}

We determine a causal model for the observations made of your server over
time using a [belief network][9] that maps the observations to finite state
sequences. We then apply a vector similarity approach to a time series of
these states to determine which sequences are most similar to one another.

Vector similarity takes two vectors as input and outputs a score based on how
similar the vectors are. The flexibility in using a similarity approach is we
can define what the similarity actually means by changing our similarity
function. You can define a distance function F with input vectors x and y,
and it might look something like:

{% img center /cosine.png cosine similarity %}

This is a pretty common implementation of a similarity function that computes
the cosine between two vectors. You can think of this as the angle between
them. In this case, the closer the angles are, the more similar the state
sequences are. These state sequences capture most of the signal in the
metrics, so by comparing these we’re able to get pattern recognition with
less noise. Then it becomes a simple sorting exercise to find the ones with
the best similarity score. From there, we display the patterns in order of
relevance based on the score and how recently the pattern occurred.

### Usability

Making these algorithms useful is about more than statistics and machine
learning. The output has to be meaningful and actionable to users for every
type of analysis that we provide. This is why we're working hard to provide
users with the functionality they need to get meaningful information and
actionable insights based on learning their feedback. The methods we use
are always evolving in this rapidly changing space, so be sure to keep an
eye out for more news soon about Rackspace Cloud Intelligence.

Get started today. Set up checks in
<a href="https://mycloud.rackspace.com/">Cloud Monitoring</a> to get more
awesome metrics.



[1]: https://blog.twitter.com/2013/observability-at-twitter
[2]: http://www.datastax.com/docs/1.0/operations/monitoring
[3]: http://basho.com/monitoring-distributed-systems-new-approaches/
[4]: http://theoryandlogic.com/post/5890089120/the-ideal-monitoring-service
[5]: http://www.cs.umn.edu/tech_reports_upload/tr2007/07-017.pdf
[6]: http://www.cs.rit.edu/~rlaz/prec20092/slides/Overview.pdf
[7]: http://www.bollingerbands.com/
[8]: https://www.economics.utoronto.ca/osborne/MathTutorial/FODF.HTM
[9]: http://www.aiai.ed.ac.uk/links/bn.html
