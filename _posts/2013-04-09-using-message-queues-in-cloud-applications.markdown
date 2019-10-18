---
layout: post
title: Using Message Queues in Cloud Applications
date: '2013-04-11 08:00'
comments: true
author: Hart Hoover
published: true
categories: []
---
{% img right pillars/pillar.png 160 160 %}
In Wayne Walls' [recent post on parallel computing](https://www.rackspace.com/blog/pillars-of-cloudiness-no-1-parallel-computing/), message queues are mentioned as a way to achieve parallel computing in an application. In this post, we will dive into the different message queues out there and how to implement a message queue in an application.<!-- more -->

##Which queue do I use?

There are several queues to choose from, each with benefits and drawbacks.

###RabbitMQ
The most popular is [RabbitMQ](https://www.rabbitmq.com/), due to multiple operating system support (even Windows!) and a plethora of [clients and tools](https://www.rabbitmq.com/devtools.html) that support RabbitMQ. RabbitMQ is written in Erlang and implements a common standard: the Advanced Message Queuing Protocol (AMQP). RabbitMQ queues messages on a central server, making it easy to deploy but a bit more interesting to scale.

###ActiveMQ

Apache [ActiveMQ](https://activemq.apache.org/) is a message broker written in Java together with a full JMS client. However Apache ActiveMQ is designed to communicate over a number of protocols such as AMQP, [Stomp](https://stomp.github.io/) and [OpenWire](https://activemq.apache.org/openwire-version-2-specification.html) together with supporting a number of different [language specific clients](https://activemq.apache.org/cross-language-clients.html).

###ZeroMQ

[ZeroMQ](https://www.zeromq.org/) is typically deployed for clustered systems and/or supercomputing. It is a sockets library for messaging and is extremely fast. It gives you sockets that carry atomic messages across various transports like in-process, inter-process, TCP, and multicast. You can connect sockets N-to-N with patterns like fanout, pub-sub, task distribution, and request-reply. ZeroMQ does not follow a broker pattern like RabbitMQ or ActiveMQ, meaning ZeroMQ does not run on a single server or cluster of servers. A wealth of information about ZeroMQ is available in ["Code Connected Volume 1 - Professional Edition" by Pieter Hinjens](https://zguide.zeromq.org/page:all), the CEO of iMatrix.

###Marconi

[Marconi](https://wiki.openstack.org/wiki/Marconi) is a new OpenStack project to create a multi-tenant cloud queuing service. The aim is to create an open alternative to Amazon's SQS (producer-consumer) and SNS (pub-sub) services, for use in applications that run on OpenStack clouds. Marconi is currently in development.

###IronMQ

[IronMQ](https://www.iron.io/mq) is an easy-to-use highly available message queuing service. IronMQ is for the person that doesn't want to manage their own queue servers. They provide an endpoint where you create queues and messages with a highly available backend. IronMQ uses HTTPS to transport messages instead of AMQP.

##Getting Started with a Message Queue and Workers

Integrating a message queue makes your application more scalable, almost by default. With a message queue in place, you can scale worker servers as needed to perform tasks. Let's look at getting started with a message queue system. For this example, I am using RabbitMQ on Ubuntu 12.04. Since we also need a worker, I will be installing [Celery](https://celeryproject.org/) as well.

##Installing RabbitMQ and Celery

First you need to add the APT repository for RabbitMQ, then install the package itself:

```
##RabbitMQ
echo "deb https://www.rabbitmq.com/debian/ testing main" >> /etc/apt/sources.list
wget https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
sudo apt-key add rabbitmq-signing-key-public.asc
apt-get update
sudo apt-get install rabbitmq-server

##Celery
pip install celery
```

RabbitMQ should be running and ready to handle messages to our worker, Celery. Now we need to set up a Celery application to perform some work. Create a file called `tasks.py`:

```python
from celery import Celery

celery = Celery('tasks', broker='amqp://guest@localhost//')

@celery.task
def add(x, y):
    return x + y
```

In this file, we are defining a message broker (RabbitMQ) as well as defining a worker task that adds two numbers together. Next we need to make sure Celery is running, then try to run our task.

```bash
celery -A tasks worker --loglevel=info
```

```python
>>> from tasks import add
>>> add.delay(4, 4)
```

Celery can store results in a database (or other [backend systems](https://docs.celeryproject.org/en/latest/userguide/tasks.html#task-result-backends)) for lookup later. If you have multiple servers running workers looking for work from a Message Queue, you can truly see some scalability in your applications.
