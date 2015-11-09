---
layout: post
title: "OpenStack Marconi API"
date: 2013-07-29 12:10
comments: true
author: Oz Akan
published: true
categories:
- Marconi
- OpenStack
---
## What is Marconi?

Marconi is an open source message queue implementation that utilizes a RESTful HTTP interface to provide an asynchronous communications protocol, which is one of the main requirements in today’s scalable applications. Using a queue as a communication layer, the sender and receiver of the message do not need to simultaneously interact with the message queue. As a result, these can scale independently and be less prone to individual failures.

Marconi supports publisher-subscriber and producer-consumer patterns. In this post, I will focus on producer-consumer patterns, and, under the section "Python Way," I will give an example using the python requests library.

<!-- more -->

Let's begin with terminology and curl samples.

## Terminology

* `Queue` is a logical entity that groups messages. Ideally, one queue is created per work type. For example, if you want to compress files, you would create a queue dedicated for this job. Any application that reads from this queue would only compress files.
* `Message` is stored in a queue and exists until it is either manually deleted by a recipient or automatically deleted by the system based on a TTL (time-to-live) value.
* `Worker` is an application that reads one or many messages from the queue
* `Producer` is an application that creates messages in a queue.
* `Claim` is a mechanism to mark messages so that other workers will not process the same message.
* `Publisher - Subscriber` is a pattern where all worker applications have access to all messages in the queue. Workers cannot delete or update messages.
* `Producer - Consumer` is a pattern where each worker application that reads the queue has to claim the message in order to prevent duplicate processing. Later, when the work is done, the worker is responsible for deleting the message. If message isn't deleted in a predefined time, it can be claimed by other workers.
* `Message TTL` is time-to-live value and defines how long a message will be accessible.
* `Claim TTL` is time-to-live value and defines how long a message will be in claimed state. A message can be claimed by one worker at a time.

## cURL Way

Since there is nothing abstracted in curl and it's available on all linux servers, I find curl is a good tool to experiment with RESTful interfaces. I like keeping these commands handy.

### Get Authentication Token

If you run Keystone middleware with Marconi, then you will have to get an authentication token to use with the following calls.

First, I assign a username and an API key to shell variables as a way to make getting a token just a copy-and-paste process.

    $ USERNAME=my-username
    $ APIKEY=my-long-api-key
    $ echo $USERNAME
    my-username
    $ echo $APIKEY
    my-long-api-key

Let's do curl magic to populate the TOKEN variable.

##### Request

    $ TOKEN=`curl -s https://identity.api.rackspacecloud.com/v2.0/tokens -X 'POST' -d '{"auth":{"RAX-\
    KSKEY:apiKeyCredentials":{"username":"'$USERNAME'", "apiKey":"'$APIKEY'"}}}' -H "Content-Type: application/json" \
    | python -c "import sys,json;print json.loads(sys.stdin.readlines()[0])['access']['token']['id']"`

Check if ```TOKEN``` value is set

    $ echo $TOKEN
    0998e7a6des3344f91184f213eaacbe7

Do a quick check if TOKEN works, by listing the queues we have.

##### Request

    $ curl -i -X GET https://test.my-marconi-server.com:443/v1/queues -H "X-Auth-Token: $TOKEN"

##### Response

    HTTP/1.1 204 No Content

We don't have a queue yet, so we got the expected ```204 No Content``` result. If there was a problem with the TOKEN, we would get ```401 Unauthorized```.

### Get Node Health

Let's see if there is a service we can talk to.

##### Request

    $ curl -i -X GET https://test.my-marconi-server.com:443/v1/health -H "X-Auth-Token: $TOKEN"

##### Response

    HTTP/1.1 204 No Content

Here, we get a 204 response, even though it may seem like something is wrong with the service. This call is intended to see if service can reply back. So, a 204 response is a good sign. This may be an indication that Marconi is brief, to the point and doesn't like chatter.

### Create a Queue

We will need to create a queue to post messages into. Queues are not created with the first message, so we need to send the request below to create a queue named "samplequeue".

##### Request

    $ curl -i -X PUT https://test.my-marconi-server.com:443/v1/queues/samplequeue -H "X-Auth-Token: $TOKEN" -H "Content-type: application/json" -d '{"metadata": "My Queue"}'

##### Response

    HTTP/1.1 201 Created
    Content-Length: 0
    Location: /v1/queues/samplequeue

### List Queues

So far we have one queue. Let's list our queues:

##### Request

    $ curl -i -X GET https://test.my-marconi-server.com:443/v1/queues -H "X-Auth-Token: $TOKEN"

##### Response

    HTTP/1.1 200 OK
    Content-Length: 140
    Content-Type: application/json; charset=utf-8
    Content-Location: /v1/queues

    {"queues": [{"href": "/v1/queues/samplequeue", "name": "samplequeue"}], "links": [{"href": "/v1/queues?marker=samplequeue", "rel": "next"}]}

### Post a Message

Because we have a queue named `samplequeue`, we can post a message to the queue. We will post a message with a TTL value of 300, and it will have a key-value pair in the body as `"event" : "one"`.

##### Request

    $ curl -i -X POST https://test.my-marconi-server.com:443/v1/queues/samplequeue/messages -d '
    [{"ttl": 300, "body": {"event": "one"}}]
    ' -H "Content-type: application/json" -H "Client-ID: QClient" -H "X-Auth-Token: $TOKEN"

##### Response

    HTTP/1.1 201 Created
    Content-Length: 93
    Content-Type: application/json; charset=utf-8
    Location: /v1/queues/samplequeue/51e840b61d10b20570d56ff4

    {"partial": false, "resources": ["/v1/queues/samplequeue/messages/51e840b61d10b20570d56ff4"]}

### Post Messages

Marconi supports posting 10 messages at the same time, so let's try to post two within the same request.

##### Request

    $ curl -i -X POST https://test.my-marconi-server.com:443/v1/queues/samplequeue/messages -d '
    [   
        {"ttl": 300, "body": {"event": "two"}},
        {"ttl": 60, "body": {"event": "three"}}
    ]
    ' -H "Content-type: application/json" -H "Client-ID: QClient" -H "X-Auth-Token: $TOKEN"

##### Response

    HTTP/1.1 201 Created
    Content-Length: 153
    Content-Type: application/json; charset=utf-8
    Location: /v1/queues/samplequeue/messages?ids=51e840e71d10b2055fd565fb,51e840e71d10b2055fd565fc

    {"partial": false, "resources": ["/v1/queues/samplequeue/messages/51e840e71d10b2055fd565fb", "/v1/queues/samplequeue/messages/51e840e71d10b2055fd565fc"]}

Above, if you check the response, you will see that Marconi returned two ID’s. It is always a good practice to post messages in batches, as network latency will be a smaller factor in overall performance compared to sending one message at a time.

### Get Messages

We can get 10 messages with a call.

##### Request

    $ curl -i -X GET https://test.my-marconi-server.com:443/v1/queues/samplequeue/messages?echo=true -H "X-Auth-Token: $TOKEN" -H "Content-type: application/json" -H "Client-ID: QClient"

##### Response

    HTTP/1.1 200 OK
    Content-Length: 461
    Content-Type: application/json; charset=utf-8
    Content-Location: /v1/queues/samplequeue/messages?echo=true

    {"messages": [
    {"body": {"event": "two"}, "age": 230, "href": "/v1/queues/samplequeue/messages/51e84e8b1d10b2055fd565fd", "ttl": 300},
    {"body": {"event": "two"}, "age": 3, "href": "/v1/queues/samplequeue/messages/51e84f6e1d10b20571d56f0e", "ttl": 300},
    {"body": {"event": "three"}, "age": 3, "href": "/v1/queues/samplequeue/messages/51e84f6e1d10b20571d56f0f", "ttl": 60}], "links": [{"href": "/v1/queues/samplequeue/messages?marker=9&echo=true", "rel": "next"}
    ]}

If we wait for 60 seconds (or one full minute), we will see 2 messages instead of 3 as messages with a TTL value of 60 seconds will expire.

We can also get a specific message by providing the message ID.

##### Request

    $ curl -i -X GET https://test.my-marconi-server.com:443/v1/queues/samplequeue/messages?echo=true&ids=51e84e8b1d10b2055fd565fd -H "X-Auth-Token: $TOKEN" -H "Content-type: application/json" -H "Client-ID: QClient"

##### Response

    HTTP/1.1 200 OK
    Content-Length: 261
    Content-Type: application/json; charset=utf-8
    Content-Location: /v1/queues/samplequeue/messages?echo=true

    {"messages": [
    {"body": {"event": "two"}, "age": 230, "href": "/v1/queues/samplequeue/messages/51e84e8b1d10b2055fd565fd", "ttl": 300}
    ]}

### Claim Messages

Claiming a message is similar to marking a message so it will be invisible when another worker wants to claim messages. By default, 10 messages are claimed. In the sample request below, we will get 2 messages claimed as we use pass 2 as limit.

##### Request

    curl -i -X POST https://test.my-marconi-server.com:443/v1/queues/samplequeue/claims?limit=2 -d '
    { "ttl" : 60,
      "grace": 60}
    ' -H "X-Auth-Token: $TOKEN" -H "Content-type: application/json" -H "Client-ID: QClient"

##### Response

    HTTP/1.1 200 OK
    Content-Length: 306
    Content-Type: application/json; charset=utf-8
    Location: /v1/queues/samplequeue/claims/51e852d01d10b2056dd5703c

    [{"body": {"event": "two"}, "age": 5, "href": "/v1/queues/samplequeue/messages/51e852cb1d10b20571d56f10?claim_id=51e852d01d10b2056dd5703c", "ttl": 300},
    {"body": {"event": "three"}, "age": 5, "href": "/v1/queues/samplequeue/messages/51e852cb1d10b20571d56f11?claim_id=51e852d01d10b2056dd5703c", "ttl": 120}]


### Delete Message

##### Request

    curl -i -X DELETE curl -i -X POST https://test.my-marconi-server.com:443/v1/queues/samplequeue/messages/51e852cb1d10b20571d56f10?claim_id=51e852d01d10b2056dd5703c -H "X-Auth-Token: $TOKEN" -H "Content-type: application/json" -H "Client-ID: QClient"

##### Response

    HTTP/1.1 204 No Content

204 is a valid response, which validates that there isn't a message with the given message and claim ID. However, it doesn’t necessary indicate that the message is deleted.

## Python Way

Curl provides a convenient way to test the Marconi RESTful interface, but it does not provide the tool to develop an application. Now, let’s see how these requests would be used in an application written in Python.

Most applications will have a logic similar to this:

* One or many producers posts messages to a queue
* Many consumers read the queue, and claim a message when available
* Consumer processes the message
* Consumer deletes the message

Below, I created 3 classes. ```Queue_Connection``` handles http calls. ```Producer``` handles queue creation and posts messages to the queue. ```Consumer``` claims messages from the queue and deletes afterwards.

    import requests
    import json

    username = 'my-user'
    apikey = 'my-api-key'
    url = 'https://test.my-marconi-server.com:443'

    class Queue_Connection(object):

        def __init__(self, username, apikey):
            url = 'https://identity.api.rackspacecloud.com/v2.0/tokens'
            payload  = {"auth":{"RAX-KSKEY:apiKeyCredentials":{"username": username , "apiKey": apikey }}}
            headers = {'Content-Type': 'application/json'}
            r = requests.post(url, data=json.dumps(payload), headers=headers)
            self.token = r.json()['access']['token']['id']
            self.headers = {'X-Auth-Token' : self.token, 'Content-Type': 'application/json', 'Client-ID': 'QClient1'}

        def token(self):
            return self.token

        def get(self, url, payload=None):
            r = requests.get(url, data=json.dumps(payload), headers=self.headers)
            return [r.status_code, r.headers, r.content]

        def post(self, url, payload=None):
            r = requests.post(url, data=json.dumps(payload), headers=self.headers)
            return [r.status_code, r.headers, r.content]

        def put(self, url, payload=None):
            r = requests.put(url, data=json.dumps(payload), headers=self.headers)
            return [r.status_code, r.headers, r.content]

        def delete(self, url, payload=None):
            r = requests.delete(url, data=json.dumps(payload), headers=self.headers)
            return [r.status_code, r.headers, r.content]


    class Producer(Queue_Connection):

        def __init__(self, url, username, apikey):
            super(Producer, self).__init__(username, apikey)               
            self.base_url = url

        def queue_name():
            def fget(self):
                return self._queue_name
            def fset(self, value):
                self._queue_name = value
            def fdel(self):
                del self._queue_name
            return locals()
        queue_name = property(**queue_name())


        def queue_exists(self):
            url = self.base_url + '/v1/queues/' + self.queue_name + '/stats'
            if self.get(url)[0] == 200:
                return True
            return False

        def create_queue(self, payload=None):
            url = self.base_url + "/v1/queues/" + self.queue_name
            res =  self.put(url, payload)
            if res[0] == 200:
                print '%s created' % self.queue_name
            elif res[0] == 204:
                print 'A queue named %s is present' % self.queue_name
            else:
                print 'Problem with queue creation,'

        def post_messages(self, payload):
            url = self.base_url + '/v1/queues/' + self.queue_name + '/messages'
            res = self.post(url, payload)
            if res[0] == 201:
                return json.loads(res[2])['resources']
            else:
                print "Couldn't post messages"

    class Consumer(Queue_Connection):

        def __init__(self, url, username, apikey):
            super(Consumer, self).__init__(username, apikey)                
            self.base_url = url

        def claim_messages(self, payload, limit=1):
            url = self.base_url + '/v1/queues/' + self.queue_name + '/claims?limit=' + str(limit)
            res = self.post(url, payload)
            if res[0] == 200:
                return json.loads(res[2])
            else:
                print "Couldn't claim messages"     

        def delete_message(self, url):
            url = self.base_url + url
            res = self.delete(url)
            if res[0] == 204:
                print "Message deleted"


    """ create a Producer instance """
    pub = Producer(url, username, apikey)
    pub.queue_name = 'testqueue'

    if not pub.queue_exists():
        print "Creating queue", pub.queue_name
        pub.create_queue({"metadata": "My Queue"})

    """ create and post two messages """
    data = [{"ttl": 60,"body": {"task":"one"}},{"ttl": 60,"body": {"task":"two"}}]
    for message in pub.post_messages(data):
        print "message: ", message

    """ create a Consumer instance """
    con = Consumer(url, username, apikey)

    """ define ttl and grace times for the claim """
    data = {"ttl":60, "grace":60}
    con.queue_name = 'testqueue'
    messages = con.claim_messages(data, 2)
    for message in messages:
        print "task : ", message['body']['task']
        print message['href']

    """
    do something with the messages
    when done delete
    """

    for message in messages:
        con.delete_message(message['href'])


This is a very primitive example. A real application would require us to handle exceptions but this should give you an idea of how queuing works

I believe the effort to start using queues in an application is well worth the benefits. With Marconi, we have queue as a service. This means someone manages it for us, and we just enjoy the benefits. In a matter of weeks, a Python client will be ready, making it even easier to talk to Marconi.

Happy queuing.
