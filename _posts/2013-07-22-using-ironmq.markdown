---
layout: post
title: Using IronMQ for delayed processing and increasing scale
date: '2013-07-23 08:00'
comments: true
author: Paddy Foran
published: true
categories:
  - General
---

{% img right 2013-07-23-using-ironmq/ironmq.png 200 %}
It’s an [established pattern](http://highscalability.com/blog/2012/12/17/11-uses-for-the-humble-presents-queue-er-message-queue.html)
to use message queues when building scalable, extensible, and resilient systems,
but a lot of developers are still unsure how to go about actually *implementing*
message queues in their architectures. Worse, the number of queuing solutions
makes it hard for developers to get a grasp on exactly what a queue is, what it
does, and what each solution brings to the table.

At [Iron.io](http://iron.io), we’re building [IronMQ](http://iron.io/platform/mq),
a queuing solution we’ve developed specifically to meet the specific needs of
today’s cloud architectures. In this post, we wanted to detail how to use queues
in your applications and highlight a couple of unique capabilities that IronMQ
provides (and which are not found in RabbitMQ and other non-native cloud queues).

One of the things that queuing does really, really well is *getting work out of
the way*. Queues are built to be fast ways to make data available for other
processes. That means that you can do more with your data, without making your
customer wait. When it comes to response times every second matters, so only
critical processing should take place within the immediate response loop. Queues
let you do processing on data and perform non-immediate tasks without adding
to your response time.

<!-- more -->

### A basic queuing example

To demonstrate the power of message queues and the advantages of pushing
non-essential processing to the background, we’re going to be build a simple
web application for gathering statistics about requests. We’ll show the basic
architecture of the application, talk about its strengths, and show a bunch of
code samples. Of course, if you want to check out the full source code, it’s
[available on Github](https://github.com/iron-io/rackspace-django-demo/).

#### The architecture

Our application is going to have a very simple architecture that affords us a
lot of performance benefits and a lot of flexibility:

* A **web server** is going to be receiving our requests and responding to them.
  This is just a demonstration server – the purpose is just to get the requests –
  but this architecture works no matter how complex your web server is. The web
  server is just going to place the request information on our queue.
* A **message queue** is going to receive information from the web server and
  store it as a message in the queue. This data will then be available for a
  separate, asynchronous process to consume and act on.
* A **worker server** is going to be retrieving messages off the queue and
  storing some analytics on the requests we’re receiving.

{% img center 2013-07-23-using-ironmq/architecture-1.png %}

It’s important to point out that your analytics processing is happening *outside*
of the request loop; this means you can do whatever expensive processing you want
(including hitting other APIs) and you’re not adding to the time it takes to get
a response to the user.

#### The web server

Our web server is going to be built on Django, but it’s easy enough to build in
any language or framework. We’re going to define middleware, but all that really
matters is that you send an authenticated POST request to IronMQ on every request,
containing the request data. Because our queue is the glue between our processes,
we’re creating a lightweight, implicit API based on the message structure. Any
process that adheres to the API can push messages to the queue or parse messages
from the queue.

Here’s the middleware we’re using:

	 from iron_mq import IronMQ
	 try:
	    import json
	 except:
	    import simplejson as json

	 class QueueRequestMiddleware:
	    queue = None

	    def __init__(self):
	        # instantiate our IronMQ client once
	        mq = IronMQ(host="mq-rackspace-ord.iron.io")
	        self.queue = mq.queue("requests") # set our queue

	    def process_request(self, request):
	        # push our request headers as a message to our queue
	        data = {}
	        for key in request.META.keys():
	            if key.startswith("HTTP_"):
	                data[key] = request.META[key]
	        self.queue.post(json.dumps(data))
	        return None # pass on to the next middleware/application

After we save this middleware, we need to include it in your Django application.
In your settings, add the `QueueRequestMiddleware` class to `MIDDLEWARE_CLASSES`.

After that’s done, your application will put the headers of every request into
a message and put it on your requests queue. After they’re there, we need to do
something with them.

#### The worker server

To understand how to process our messages, it’s important to clarify the
post-get-delete paradigm that IronMQ and a lot of other message queues use.
Essentially, you put the message on the queue (which is what our webserver does),
and one or more clients try to consume the message. To avoid multiple clients
getting the same message (we don’t want to process a request twice) each client
*reserves* a message for a set amount of time (1 minute by default in IronMQ,
but it’s configurable) when they pull it off the queue. This message won’t be
available for other clients to get until after the reservation has expired. This
means that the client needs to delete the message within that reservation period,
or another client will process the message. By requiring messages to be explicitly
deleted, we can guarantee each message will be processed once: as soon as a client
is done processing a message, it deletes it. If the client crashes while processing
the message, the message simply returns to the queue for another client to process.

Workers are just programs that run on your servers. They’re anything that pulls
a message off the queue and acts based on the data the message contains. Usually
workers are either run at an interval, regularly processing queues, or they’re
run as a daemon, continuously processing queues. These programs can be run on a
single server or a cluster of servers, but the basic idea is that they are what
acts on the data in your queue.

In our worker, we just want to store some basic information based on the request.
We’ll start simple and just count the number of requests. We’re storing our
information in [Redis](http://redis.io) using [redis-py](https://github.com/andymccurdy/redis-py),
but you could store it in whatever storage system you like.

	 from iron_mq import IronMQ
	 import redis
	 import time

	 mq = IronMQ(host="mq-rackspace-ord.iron.io")
	 q = mq.queue("requests")
	 r = redis.StrictRedis()

	 while True: # poll indefinitely
	    msg = q.get() # ask the queue for messages
	    if len(msg["messages"]) < 1: # if there are no messages
	        time.sleep(1) # wait a second
	        continue # try again
	    # if we made it this far, we have a message
	    r.incr("requests") # increment the number of requests
	    q.delete(msg["messages"][0]["id"]) # delete the message

That’s it! A very simple worker, but it serves its purpose: Redis is no longer
connected to your request loop. If Redis goes down or takes ten seconds to
respond (unlikely, but good to guard against), it won’t affect user requests.

#### Testing and measuring

Now that we have the code set up, what does adding analytics to our application
cost us? The answer should just be a single HTTP request to IronMQ. Depending
on where your servers are, this could vary. We’re running these tests from New
York, but you’d probably want to run them from your Rackspace servers. IronMQ
is deployed on Rackspace, as well as other major cloud providers, so if you
tell your client to store data in the Rackspace instance of IronMQ, you’ll have
very low latencies.

To test our application, we’re going to disable the middleware (commenting out
the `QueueRequestMiddleware` in our `MIDDLEWARE_CLASSES`) and run the
[siege](http://www.joedog.org/siege-home) benchmarking tool on the server:

	 siege -b -t10S http://localhost:8000

This assumes your app is running on localhost:8000. The URL we’re serving is
just a static page that does nothing but spit out text using Django. We’re
testing for the base Django functionality, so we want as little variation as
possible, which means limiting interaction with our database. Our output is as
follows:

	 Lifting the server siege...      done.

	 Transactions:		        3329 hits
	 Availability:		       99.25 %
	 Elapsed time:		        9.16 secs
	 Data transferred:	        0.06 MB
	 Response time:		        0.04 secs
	 Transaction rate:	      363.43 trans/sec
	 Throughput:		        0.01 MB/sec
	 Concurrency:		       14.82
	 Successful transactions:        3329
	 Failed transactions:	          25
	 Longest transaction:	        0.19
	 Shortest transaction:	        0.01

The important parts are the Response time, the Transaction rate, and the Longest
transaction.

* The response time is going to tell us our average response time in seconds
* The transaction rate is the number of transactions (requests) we can serve in a second
* The longest transaction will tell us how long the longest request took to be served

Now that we have base values, let’s uncomment the `QueueRequestMiddleware` in
`MIDDLEWARE_CLASSES` and run siege again. Here’s the new output:

	 Lifting the server siege...      done.

	 Transactions:		        1222 hits
	 Availability:		       98.71 %
	 Elapsed time:		        9.90 secs
	 Data transferred:	        0.02 MB
	 Response time:		        0.12 secs
	 Transaction rate:	      123.43 trans/sec
	 Throughput:		        0.00 MB/sec
	 Concurrency:		       14.78
	 Successful transactions:        1222
	 Failed transactions:	          16
	 Longest transaction:	        3.50
	 Shortest transaction:	        0.06

As you can see, we increased our response time by .08 seconds on average, and
at most 3.3 seconds, which means we can serve ~240 less requests in a second.
While this may seem like a lot, keep in mind that our base is just a static page;
adding a database behind the page will have similar effects. The good news is
that, because your message processing is done outside the request loop, this
performance hit is O(1): no matter how many different ways you want to analyze
your requests, this cost will remain constant. There are a lot of different
things you can do in the background, so this constant cost is a huge benefit.
It enables you to do all of the following outside the request loop:

* Image processing
* Sending emails/push notifications
* Generating reports
* Manipulating databases

### Extending our solution

Now that we’ve covered the basic functions every message queue can accomplish,
we wanted to point out one of the features we think makes IronMQ a cloud-native
queuing solution: push queues. We’ll be using this feature to fan out our request
messages to several *different* processors, each of which will store different
information about the request. This design allows you to build a modular,
discrete system that can be extended easily.

Push queues aren’t typically the best way to process a queue with regular, heavy
traffic; a pull queue is generally a better performance trade-off for that. But
because IronMQ uses webhooks to send push notifications, you can enable some
interesting interactions with other APIs without writing much (or sometimes any)
code.

#### The architecture 2.0

Our architecture doesn’t need to change much to fulfill our extra requirements:

* The **web server** is still just going to be pushing a single message per
  request, containing the request data.
* Our **message queue** is going to be turned into a *push queue* and we’re
  going to set up some new pull queues that our workers will consume. The push
  queue is going to automatically duplicate our message to each of our pull
  queues&mdash;again, outside of our request loop&mdash;so our workers will
  *each* get a copy of every request for them to process for their specific
  criterion.
* Our **worker** is going to be joined by another worker, processing the
  requests in a second way. These workers will run on the same server in our
  example, but they are completely independent&mdash;they can be run on the same
  machine or multiple machines.

{% img center 2013-07-23-using-ironmq/architecture-2.png %}

It’s important to understand that the worker processes are totally independent.
Multiple copies of each can be run, and each request will only be processed once.
If one crashes, the other won’t be impacted. If we want to add a third, we just
need to add a new pull queue to our push queue’s subscriber and add the worker.
This kind of modularity is extremely powerful and resilient in cloud applications.

#### The web server 2.0

Thanks to our design, the web server doesn’t change at all. Just the queue.

* Go into the Iron.io [HUD](https://hud.iron.io) and browse to your requests queue
* In the box labeled “Push Information”, select “multicast” for the Push Type.
* Leave Retries and Retries Delay at their default values.
* Hit “Update Queue”. You’ve turned the queue into a push queue.

Next we need to add some subscribers. Push queues just send HTTP POST requests
to your subscribers with the message data in the body. We want to use the IronMQ
[webhook URLs](http://dev.iron.io/mq/reference/api/#add_messages_to_a_queue_via_webhook)
to turn these POST requests into messages on new queues, effectively duplicating
the messages across several queues.

To build an IronMQ webhook URL, start with the base URL of
`https://mq-rackspace-ord.iron.io/1/projects/` and add your project ID. Then
add `/queues/`, then the queue name, then `/messages/webhook?oauth=`, and finally
your OAuth token. So, for example, let’s add a webhook endpoint for a `all_requests`
queue and a `ua_requests` queue. They’d look like this:

	 https://mq-rackspace-ord.iron.io/1/projects/PROJECT_ID/queues/all_requests/messages/webhook?oauth=OAUTH_TOKEN
	 https://mq-rackspace-ord.iron.io/1/projects/PROJECT_ID/queues/ua_requests/messages/webhook?oauth=OAUTH_TOKEN

Go ahead and add those (substituting in your project ID and token) in the
subscribers box in HUD. Now when you get a message added to the requests queue,
it is duplicated to `all_requests` and `ua_requests`.

#### The worker server 2.0

Now that requests is a push queue, we can’t pull messages off it. So change the
queue name in the original script to be `all_requests`, which will have a copy
of all the messages.

We’re also going to want a worker to consume the `ua_requests` queue and store
a running count of all the user agents the server is getting requests from and
the number of requests they’re sending. It’s a very simple modification of the
first worker:

	 from iron_mq import IronMQ
	 import redis
	 import time

	 mq = IronMQ(host="mq-rackspace-ord.iron.io")
	 q = mq.queue("ua_requests")
	 r = redis.StrictRedis()

	 while True: # poll indefinitely
	    msg = q.get() # ask the queue for messages
	    if len(msg["messages"]) < 1: # if there are no messages
	        time.sleep(1) # wait a second
	        continue # try again
	    # if we made it this far, we have a message
	    # separate the user agent
	    user_agent = msg["messages"][0]["body"]["HTTP_USER_AGENT"]
	    # increment the number of requests from the user agent
	    r.hincrby("user_agent_requests", user_agent, 1)
	    q.delete(msg["messages"][0]["id"]) # delete the message

And you’re done. Your application is now tracking analytics on request user
agents. Adding more criteria is as simple as adding another queue and another
worker to read off the queue.

#### Testing and measuring 2.0

Now that we’ve tripled the amount of data we’re extracting from our requests,
let’s verify it didn’t cost us anything in response time. As a reminder, our
values from before:

<table>
<tr>
  <td>Architecture Version</td><td>Response Time</td><td>Longest Transaction</td><td>Transaction Rate</td>
</tr>
<tr><td>1</td><td>0.12 secs</td><td>3.50</td><td>123 trans/sec</td></tr>
</table>

Here are the new values when running siege:

<table>
<tr>
  <td>Architecture Version</td><td>Response Time</td><td>Longest Transaction</td><td>Transaction Rate</td>
</tr>
<tr><td>1</td><td>0.12 secs</td><td>3.50</td><td>123 trans/sec</td></tr>
<tr><td>2</td><td>0.12 secs</td><td>0.41</td><td>127 trans/sec</td></tr>
</table>

As you can see, the change in our response time is within the range of normal
variation for the application. We managed to pull twice as much data out of the
request without increasing our response time in any noticeable way.

### Adapt as necessary

This pattern goes beyond just tracking analytics to your page; any data your
application receives that does not need to be processed immediately is a candidate
for background processing. By moving things out of the request loop, you keep
your user experience responsive and snappy while keeping your code scalable and
clean.

### Resources

We created a demo application that shows off the patterns above for increasing
scale but pushing tasks to the background. This includes the first model where
workers are just polling a queue as well as more sophisticated patterns that push
to multiple queues.

Want the code for the demo app? You can find it
[on Github](https://github.com/iron-io/rackspace-django-demo/). Sign up for
[IronMQ](http://www.iron.io/mq) and get millions of API requests free each month.

### About the author

Paddy is a Python and Go developer at Iron.io, where he works as a Developer
Experience Engineer. He works with customers, the community, and Iron.io's
engineering teams to make their products enjoyable and easy to use, while still
providing scalable, flexible, and elegant solutions. He believes in an Open Web,
cloud computing, webhooks, and unicorns.
