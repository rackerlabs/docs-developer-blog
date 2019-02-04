---
layout: post
title: Using the Rackspace Service registry
date: '2012-11-07 22:33'
comments: true
author: Hart Hoover
categories:
   - General
---
{% img featured /rsr_logo.png Rackspace Service Registry %}

Rackspace recently
[announced the Rackspace Service registry](http://www.rackspace.com/blog/keep-track-of-your-services-and-applications-with-the-new-rackspace-service-registry/),
a platform that allows developers to build highly available and responsive
applications using a simple but powerful REST API. Currently it provides three
main functions:

* Service discovery -  Find which services are currently online/active and find
services based on different criteria. You can organize your services however best
fits your application deployment.
* A platform for automation – Service registry exposes an events feed, which
includes all of the events that have happened during the lifecycle of your
account (such as, a service comes online, a configuration value gets updated, and so on).
* Configuration storage – This enables users to store arbitrary configuration
values in our system and get notified via the events feed when a value gets
updated or deleted.

<!-- more -->

More information on the product is available from the
[API Guide](http://docs.rackspace.com/rsr/api/v1.0/sr-devguide/content/overview.html),
[Integration Guide](http://docs.rackspace.com/rsr/api/v1.0/sr-devguide/content/integration-instructions.html),
[Client libraries and tools](http://docs.rackspace.com/rsr/api/v1.0/sr-devguide/content/client-libraries-and-tools.html),
and [Release Notes](http://docs.rackspace.com/rsr/api/v1.0/sr-devguide/content/release-notes.html).

Here, I’d like to highlight the Node.js integration.

### Integrating the Rackspace Service registry into your Node.js application

The client is available in npm. To install, just use the npm command:

```
npm install service-registry-client
```

We then need to create a session. In order to create a session using the Node.js
client, we first have to instantiate a client to interact with the Rackspace
Service registry:

``` javascript
var Client = require('service-registry-client').Client;
var username = ''; // your username here
var key = ''; // your API key here
var client = new Client(username, key, 'us');
```

The region keyword argument above determines which Rackspace authentication URL
the client uses to authenticate. You can specify either `US` or `UK`. Now that
we’ve created a Client object, we can use it to work with the Rackspace Service
registry API. Creating a session is straightforward:

``` javascript
client.sessions.create(30, {}, function(err, seId, resp, heartbeater) {});
```

We also now have the session ID (let’s say it’s ‘seMkzI0mxC’), so we can start
adding services to the session:

``` javascript
client.services.register('seMkzI0mxC',
'serviceId',
{'tags': ['tag1', 'tag2', 'tag3']},
null, function(err, resp) {});
```

When creating a session using the Node.js client, the result contains the session
ID, response body (which contains the initial token required for heartbeating
the session) and a HeartBeater object. The HeartBeater object allows us to
automatically heartbeat the session by calling the `start()` method:

```javascript
heartbeater.start();
```

This causes the HeartBeater object to start heartbeating automatically using
the initial token. It heartbeats the session, gets the next token, and heartbeats
the session again continuously until the stop() method is called.

###Code Sample

Here is a short example of a web server that registers with the Cloud Service
registry on startup, and uses the HeartBeater object while it is running in order
to maintain the session:

``` javascript
var http = require('http');

var async = require('async');
var Client = require('service-registry-client').Client;

var username = ''; // your username here
var key = ''; // your API key here

var client = new Client(username, key, 'us');

http.createServer(function (req, res) {
res.writeHead(200, {'Content-Type': 'text/plain'});
res.end('Hello, world!');
}).listen(9000, '127.0.0.1');

async.waterfall([
function createSessionAndStartHeartbeating(callback) {
client.sessions.create(30, {}, function(err, seId, resp, hb) {
hb.start();
callback(null, seId);
});
},

function createService(seId, callback) {
var metadata = {'ip': '127.0.0.1', 'port': '9000',
'node_version': process.version};
client.services.register(seId, 'webService', {'metadata': metadata}, function(err, resp) {
callback(err);
});
}
],

function(err) {
if (err) {
console.log('An error has occurred.');
console.log(err);
}
});
```

### I want the preview!

The Rackspace Service registry is currently in a limited preview. To apply for
the preview, please fill out
[this short survey](https://surveys.rackspace.com/Survey.aspx?s=f3d6e51580ab4510a564487fafdafdfd)
with your contact information and use case, and we will determine your eligibility within 48 hours.
