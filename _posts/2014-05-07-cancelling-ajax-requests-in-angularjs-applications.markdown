---
layout: post
title: Cancelling Ajax requests in AngularJS applications
date: '2014-05-07 10:00'
comments: true
author: Satheesh Kumar
published: true
categories:
  - General
---

When we, at Rackspace were working on a data visualization dashboard which uses
[AngularJS](http://angularjs.org/) framework, we needed to abort requests.
Fortunately, AngularJS has amazing built in services of which
[$http](http://docs.angularjs.org/api/ng/service/$http) and
[$resource](http://docs.angularjs.org/api/ngResource/service/$resource) helped us
make these XHR(Ajax) requests much simpler. There are many resources to figure
out which might be better for your use case. I’m going to describe how I
implemented aborts in $resource and $http in an unified way which increased the
performance and showed correct data.

<!-- more -->

Large web applications require lots of information to operate. Whether that’s
navigating between menus and tabs or just clicking around, the application has
to make a lots of Ajax requests to fetch data from the server. Often times the
application ultimately doesn’t need all the requests made as it might not be
relevant. These requests can potentially trip up the UI as the server may be
slow that one request overtakes another making the application process or show
stale data. So we need to be able to abort old requests to make the application
faster, responsive and show correct information.



### Abort using timeout property

Initially, we discovered that when creating a $resource or $http you can set a timeout property in the config object which you can use to abort requests.

```bash
>timeout — {number|Promise} — timeout in milliseconds, or promise that should abort >the request when resolved.
```

So we created a ResourceHelper service which exposes apis to create a $resource with an aborter promise set on the timeout property. This aborter promise can be used to abort the request. Like below,

```javascript
function createResourceInstance(url, options, aborter) {
  return $resource(url, options || {}, {
   'get': {
     method: 'GET',
     timeout: aborter.promise
  }});
}

function resourceHelper(url, options) {
  var aborter = $q.defer(),
  resource = createResourceInstance(url, options, aborter);
  return {
   getResource: function() {
     return resource;
   },
   /**
   * Recreates the resource instance.
   */
   renew: function() {
     aborter = $q.defer();
     resource = createResourceInstance(url, options, aborter);
   },
   /**
   * Aborts current requests and recreate abortable resource.
   */
   abort: function() {
    aborter.resolve();
    this.renew();
   }
  };
 }
```
The above may work for simple cases but as you can see, there is one main issue with this, we have to store the url, config and the options (depending on the $resource) in the closure and on abort, recreate the same $resource with a new aborter promise set on the timeout property of the config object so it can be aborted again. Also when your $resource has many actions like say update, save, etc. which uses PUT, GET, etc. you are essentially aborting all of them.

### Abort using promises


The previous implementation worked but there’s still room for improvement and I wanted a better way to abort requests as recreating $resource every time a request is aborted was not efficient. After considering other options like contributing to AngularJS codebase, using a [decorator](http://docs.angularjs.org/api/auto/object/$provide#decorator) (which is great), I discovered the power of promises, promises make engineer brains work better! Here is a great [video](https://www.youtube.com/watch?v=XcRdO5QVlqE) on promises by Christian at Ng-conf. Instead of setting the $promise in the timeout property in the internal config, the solution I came up with uses a promise as a wrapper around the $promise returned when we create a $resource or $http.  This wrapper promise is used to abort requests.

```javascript
function createResource(config) {
 var actions = config.actions || {},
 resource,
 outstanding = [];

 resource = $resource(config.url, config.options, actions);

 Object.keys(actions).forEach(function(action) {
   var method = resource[action];

   resource[action] = function() {
    var deferred = $q.defer(),
    promise = method.apply(null, arguments).$promise;

    abortablePromiseWrap(promise, deferred, outstanding);

    return {
      promise: deferred.promise,

      abort: function (){
       deferred.reject('Aborted');
      }
    };
   };
 });

 /**
 * Abort all the outstanding requests on
 * this $resource. Calls promise.reject() on outstanding [].
 */
 resource.abortAll = function () {
  _.invoke(outstanding, 'reject', 'Aborted all');
  outstanding = [];
 };

 return resource;
 }
```

Let me explain in detail, a resource is created with possibly many actions which is executed usually with options as arguments. Like before when I create a resource, instead of just returning the $promise I return an object with the promise (wrapper promise) and abort apis. In the case of a $resource, because the actions (which when executed returns a $promise) are already created when a $resource is instantiated, I had to feature override them to return the promise/abort apis object.

There is no need to recreate the whole $resource object by caching all the options, url, etc. rather each time a resource action is called, a new wrapper promise is created that can be resolved when original $promise is resolved or aborted by just rejecting it. The $resource created stays the same till the application dies, we are only dealing with the wrapper promise. Also the individual actions defined in the config of $resource can be aborted with out impacting other actions. In case we need to abort all when moving away from a page, etc., we can use the abortAll api which calls reject on all the wrapper promises stored in outstanding [].

Will get to $http after going over the function abortablePromiseWrap().

```javascript
function abortablePromiseWrap (promise, deferred, outstanding) {
  promise.then(function() {
   deferred.resolve.apply(deferred, arguments);
  });

  promise.catch(function() {
   deferred.reject.apply(deferred, arguments);
  });
  /**
  * Remove from the outstanding array
  * on abort when deferred is rejected
  * and/or promise is resolved/rejected.
  */
  deferred.promise.finally(function() {
   array.remove(outstanding, deferred);
  });
  outstanding.push(deferred);
}
```

The above function which takes in the original promise, deferred(wrapper promise) and outstanding array, simply sets up how the returned abortable wrapper promise behaves when it is resolved or rejected.

If all your API’s are RESTful you don’t have to worry about $http. For our application in the case of $http, I wanted a similar functionality, but since the usage is just $http(config); which  returns a promise, it’s hard to reuse the service say by passing different params/POST different data when the rest of the config is the same(like same url, cache config, etc.). So I created a httpRequester which returns execute and abortAll apis and functions very similar to the createResource above. Similar to calling $resource’s action method defined which returns the object, you can call execute on httpRequester. Similar to reusing the $resource you can reuse $http passing in different options using the execute method on httpRequester instance, interpolation does the magic.

```javascript
function httpRequester(config) {

 // Have a reference to original URL to reuse.
 // Only url changes sometimes when used once, the params get
 // added to it, other config remains the same.
 var interpolateUrl = config.url,
 outstanding = [];

 return {
  /*
  * Abort all outstanding requests
  */
  abortAll: function() {
    _.invoke(outstanding, 'reject', 'Aborted all');
    outstanding = [];
  },
  /*
  * Executes the $http call with config
  */
  execute: function (options, params, data) {
   var uri, promise, deferred;
   config.url = interpolateUrl;

   //handle both absolute and relative paths
   //for query options interpolation
   if (_.str.startsWith(config.url, 'http')){
     uri = Util.disuniteHttp(config.url);
     config.url = uri.protocol + Util
           .interpolate(uri.url, options);
   } else {
     config.url = Util.interpolate(config.url, options);
   }

   _.extend(config, params, data);

   deferred = $q.defer();
   promise = $http(config);

   abortablePromiseWrap(promise, deferred, outstanding);

   return {
    promise: deferred.promise,

    abort: function() {
     deferred.reject('Aborted');
    }
   };
  }
 };
}
```

### Conclusion

All the api calls/ajax requests for our application go through this service which also gives us an opportunity to add other additional features. For example, this is an appropriate place to add/configure a cache for the application to avoid making the same calls to the server. I added the cache, which can be configured for individual resource/http requests, all you need to do is pass in a cache config object as well in addition to the config for resource/http. Our application uses [angular-cache](http://jmdobry.github.io/angular-cache/) which is a feature-packed replacement for the built in Angular cache.


```javascript
  return {
    createResource: function(config) {
      return createSageResource(config);
    },
    createHttpRequester: function(config) {
      return httpRequester(config);
    }
  };
```

Finally, I just exposed both the apis in the service like above. In a large data visualization application like ours, we make many Ajax calls for various quick user interactions, navigating away from a page, etc. and this service was much needed to abort calls which were no more relevant, cache required calls, etc. This made the application much faster, show correct information and very responsive to user input.
