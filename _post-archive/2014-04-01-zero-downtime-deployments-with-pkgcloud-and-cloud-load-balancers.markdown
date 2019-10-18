---
layout: post
title: Zero downtime deployments with pkgcloud and Cloud Load Balancers
date: '2014-04-10 12:00'
comments: true
author: Ken Perkins
published: true
categories:
  - node.js
---

I've been spending a lot of time working on more practical examples with [pkgcloud][0], and one of the ones that I think will appeal broadly is the ability to deploy your code as part of a zero-downtime deployment strategy.

<!-- more -->

### What are Zero-Downtime deployments?

Ask a dozen dev-ops people, and you'll probably get [10 different answers][1]. The most likely consistent attributes to them is that you can deploy with negligable impact to your traffic. **No dropped connections**, no errors during downtime, **No 502/500/etc errors** from your Load Balancer.

My opinion is that the specific mechanism you use to achieve this is less important than the motivation for why you want this. I assert that having the ability to **ship any change**, **at any time**, and the confidence that it won't impact your users will empower your developers to do what they do best; write awesome code.

In this example, Zero-downtime deployment means having a set of application servers that are behind a Load Balancer that are rotated in and out during your deployment, allowing you to deploy your code transparently to your users:

##### Buyer Beware
There are a number of concerns to be aware of before adopting any zero-downtime rolling deployment approach:

1. Does your app have an integrated versioning/cache-busting approach?
2. Are your app-servers stateless or do they require sticky sessions?
3. How do you deploy your app to your app servers?
4. Do you have the ability to roll-back effortlessly?
5. Can your app have different versions served to clients concurrently?

#### Theory
Let's assume you have 4 app servers behind a load balancer, named `web-01`, `web-02`, `web-03`, and `web-04`. We want to deploy to half of them, and the deploy to the other half, using the load balancer to manage the process.

1. Mark `web-01` and `web-02` as `draining` on the Cloud Load Balancer
  - This prevents new incoming connections, you can read more on the [Rackspace Cloud Load Balancer Documentation][2].
2. When your app is done with current requests, mark `web-01` and `web-02` as `disabled`
3. Deploy your app to `web-01` and `web-02`
4. Verify your app as appropraite
5. Mark `web-01` and `web-02` as `enabled`

Then, simply repeat this process for `web-03` and `web-04`.

#### Example

This example uses Rackspace's [Cloud Load Balancers][3] and [pkgcloud][0] to manipulate your nodes. We'll start at the point where you've already pre-validated the code you want to deploy using whatever unit/integration or build tests your app may have.

We're going to use three npm packages for this example, `pkgcloud`, `async`, and `underscore`. Async is being used for control-flow. Underscore will purely be for convenience methods.

```javascript
var pkgcloud = require('pkgcloud'),
    async = require('async'),
    _ = require('underscore');
```
First, lets create a `pkgcloud` Load Balancer client:

```javascript
var client = pkgcloud.services.loadbalancer.createClient({
    apiKey: '1234567890', // your api key here
    username: 'foo-bar-baz', // username as well
    region: 'ORD',
    provider: 'rackspace'
});
```

Once we have our client, the first thing we'll need is a health check. This  will allow us to always start from a known condition, which is a critical step in having confidence in your deployment process. A **go/no-go** if you will.

```javascript
function ensureStatus(loadBalancerId, callback) {
    client.getLoadBalancer(loadBalancerId, function(err, lb) {
        if (err) {
            callback(err);
            return;
        }

        // We don't want to to do anything if we're not in a known state to begin with
        if (lb.status !== 'ACTIVE') {
            callback(new Error('Load Balancer status not active'));
            return;
        }

        // check the status of each nodes. We want all of our nodes enabled
        // before we begin rotating nodes in and out
        if (_.any(lb.nodes, function(node) {
            return node.condition !== 'ENABLED';
        }) {
            callback(new Error('All nodes must be condition:ENABLED to deploy');
            return;
        }

        // If you want to any app specific validation, you could call out to that here

        // If we meet a minimum validation, lets callback with no errors
        callback();
    });
}
```

Next, we'll need a function that allows us to update a node to a specific condition. We'll use this function for both rotating in, as well as rotating out.

```javascript
function updateNodeCondition(lb, node, newCondition) {

    // we return a function here so we can use this inside of async.series
	return function (next) {
		node.condition = newCondition;
		console.log('Updating Node [' +
			node.address +
			'] to condition [' + node.condition + ']');

        // first lets update the node condition
		client.updateNode(lb, node, function (err) {
			if (err) {
				next(err);
				return;
			}

            // second, lets wait for the load balancer to tell us the change
            // has been completed, and we're back at active status
			lb.setWait({
				status: 'ACTIVE'
			}, 2500, next);
		});
	}
}
```

Given this helper function, rotating a node out is straight-forward.

```javascript
function rotateNodeOut(nodeAddress, lb, callback) {

    // first, lets find the address in our list of nodes
	var node = lb.nodes.filter(function (node) {
		return node.address === nodeAddress;
	})[0];

	if (!node) {
		callback(new Error('Unable to find requested node'));
		return;
	}

	if (node.condition !== 'ENABLED') {
		callback(new Error('Node must be condition:ENABLED before rotating'));
		return;
	}

	async.series([
		updateNodeCondition(lb, node, 'DRAINING'), // this stops new incoming connections
		waitForAppConnectionsToClose, // This would be your function to identify if connections are complete
		updateNodeCondition(lb, node, 'DISABLED') // move to disabled condition
	], callback);
}
```
There is one *magic function* in this section. It's the `waitForAppConnectionsToClose`. Basically, you'll want to do whatever is appropriate for your application to ensure you're ready for moving to disabled state. If you don't possess (or need) anything like that here, you could simply move straight to disabled status and remove this step.

Now, lets put it all together, and rotate out the first half of our app servers. We're going to use `10.0.10.1` through `10.0.10.4` for our four app servers.

```javascript
function rotateOutAndDeploy(ips, lb, callback {
    async.series([
        function(next) {
            // rotate out each ip in our array
            async.forEach(ips, function(address, cb) {
                rotateNodeOut(address, lb, cb);
            }, next)
        },
        function(cb) {
            // we're going to assume you have a callback based function to
            // deploy your code here. This could be an ssh command, or anything
            // where you actually push the code and restart your services
            deploy(ips, cb);
        }
    ], callback);
}
```

As before, we're going to use another *magic function* to handle the actual deployment; in this case it's `deploy`. There are so many ways you could do this, we're not going to address that in this example. The point is, you'll need some way of actually deploying your code to your nodes, whether it's scp, rsync, git, etc.

Finally, we need to be able to rotate back in.

```javascript
function rotateIn(ips, lb, callback {
    async.forEach(ips, function(address, next) {
        // we don't need a multi-step process here, so we can
        // just invoke the returned function with cb directly
        updateNodeStatus(address, lb, 'ACTIVE')(next);
    }, callback);
}
```

Now, lets run a full deployment!

### Voila

```javascript
function deploy(loadBalancerId, poolA, poolB, callback) {

    var lb;
    async.series([
        function(next) { ensureStatus(loadBalancerId, function(err, loadBalancer) {
            if (err) {
                next(err);
                callback;
            }

            lb = loadBalancer;
            next();
        },
        function(next) { rotateOutAndDeploy(poolA, lb, next); },
        function(next) { rotateIn(poolA, lb, next); },
        function(next) { rotateOutAndDeploy(poolB, lb, next); },
        function(next) { rotateIn(poolB, lb, next); },
        // lets make sure we return the load balancer to a known state
        function(next) { ensureStatus(loadBalancerId, next); }
         // this would be something you do post deployment
        function(next) { verifyDeployment(next); }
    ], function(err) {
        if (err) {
            callback(err);
            return;
        }

        console.log('W00t! Successful Deployment');
        callback();
    });
}
```

That's it! While it may seem like a number of steps, each of them are rather focused. It's the combination of these steps that will make your deployments a breeze.

### Final Thoughts

I hope this example sets you on the path towards Zero-downtime deployments. When you have confidence that you can ship code at any time of day without a significant impact to your existing users, it can be a great enabler.

[0]: https://github.com/pkgcloud/pkgcloud
[1]: https://www.google.com/search?q=zero+downtime+deployments
[2]: https://docs.rackspace.com/loadbalancers/api/v1.0/clb-devguide/content/Nodes-d1e2173.html
[3]: https://www.rackspace.com/cloud/load-balancing/


