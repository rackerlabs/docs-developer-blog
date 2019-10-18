---
comments: true
date: 2012-09-14T07:00:36.000Z
layout: post
author: Mike Sisk
title: Configuring PTR records using the Rackspace Cloud DNS API
categories: []
---

_This is a guest post by Mike Sisk, a Racker working on DevOps for Rackspace's new cloud products. You can read his blog at [https://mikesisk.com](https://mikesisk.com) or follow _[@msisk](https://twitter.com/msisk)_ on Twitter._

I'm going to show you how to setup a PTR record in Rackspace Cloud DNS for a Cloud Load Balancer using the command-line utility cURL.

<!-- more -->

I'm using a Rackspace Cloud production account below; when you try it with your account change the account number and authentication token to yours.

A few notes about cURL: this is a command line utility found on Mac and most Linux machines. You can also use other tools called "REST Clients". One popular one is an extension for Firefox and Chrome located [here](https://restclient.net).

Here's a quick reference to some of the options I'll be sending with cURL in the examples below:
	
  * -D Dump header to file (- sends to stdout)

	
  * -H Extra header(s) to send

	
  * -I Get header only

	
  * -s silent (no progress bars or errors)

	
  * -X Request method (GET is default)


The first thing we need to do is get an Authentication Token:

    
    $ curl -s -I -H "X-Auth-Key: auth-key-for-account" -H "X-Auth-User: username" https://auth.api.rackspacecloud.com/v1.0


This will return just the header from the request (note the -I option) and the one we need is the value after "X-Auth-Token:"

Let's list the domain so we can grab its ID (I've obscured my Authentication Token below with $TOKEN):

    
    $ curl -s -H "X-Auth-Token: $TOKEN" https://dns.api.rackspacecloud.com/v1.0/636983/domains {"domains":[{"name":"sisk.ws","id":3325158,"created":"2012-07-20T18:04:11.000+0000","accountId":636983,"updated":"2012-07-31T18:40:22.000+0000","emailAddress":"mike.sisk@rackspace.com"},{"name":"wikirr.com","id":3174423,"created":"2012-02-28T19:26:35.000+0000","accountId":636983,"updated":"2012-07-21T21:58:41.000+0000","emailAddress":"ipadmin@stabletransit.com"},{"name":"wikirr.net","id":3314413,"comment":"This is a test domain created via the Cloud DNS API","created":"2012-07-11T14:54:00.000+0000","accountId":636983,"updated":"2012-07-11T14:54:03.000+0000","emailAddress":"mike.sisk@rackspace.com"}],"totalEntries":3}


Ok, that's a little hard to read. But I can see the domain ID in question I need.

    
    $ curl -s -H "X-Auth-Token: $TOKEN" https://dns.api.rackspacecloud.com/v1.0/636983/domains/3325158 | python -m json.tool
    {
            "accountId": 636983, 
            "created": "2012-07-20T18:04:11.000+0000", 
            "emailAddress": "mike.sisk@rackspace.com", 
            "id": 3325158, 
            "name": "sisk.ws", 
            "nameservers": [
                {
                    "name": "ns.rackspace.com"
                }, 
                {
                    "name": "ns2.rackspace.com"
                }
            ], 
            "recordsList": {
                "records": [
                    {
                        "created": "2012-07-20T18:05:14.000+0000", 
                        "data": "108.166.119.217", 
                        "id": "A-8591849", 
                        "name": "sisk.ws", 
                        "ttl": 300, 
                        "type": "A", 
                        "updated": "2012-07-31T18:39:25.000+0000"
                    },
                {
                        "created": "2012-07-31T18:40:21.000+0000", 
                        "data": "66.216.68.19", 
                        "id": "A-8633106", 
                        "name": "www.sisk.ws", 
                        "ttl": 300, 
                        "type": "A", 
                        "updated": "2012-07-31T18:40:21.000+0000"
                    }, 
                    {
                        "created": "2012-07-20T18:04:11.000+0000", 
                        "data": "dns1.stabletransit.com", 
                        "id": "NS-7882349", 
                        "name": "sisk.ws", 
                        "ttl": 300, 
                        "type": "NS", 
                        "updated": "2012-07-20T18:04:11.000+0000"
                    }, 
                    {
                        "created": "2012-07-20T18:04:12.000+0000", 
                        "data": "dns2.stabletransit.com", 
                        "id": "NS-7882350", 
                        "name": "sisk.ws", 
                        "ttl": 300, 
                        "type": "NS", 
                        "updated": "2012-07-20T18:04:12.000+0000"
                    }
                ], 
                "totalEntries": 4
            }, 
            "ttl": 300, 
            "updated": "2012-07-31T18:40:22.000+0000"
        }


The default output of the API is JSON, but it also supports XML if you send it another header. The little bit of Python on the end just sends the output though a parser to format it for humans. You can see I have already created an A record for the www address. The PTR we're creating below is essentially the reverse of that to map the IP address to www.sisk.ws.

Through the control panel I had already created a Cloud Load Balancer on this account. We need its ID for the PTR record, so let's list the load balancer though its API:

    
     $ curl -s -H "Accept: application/json" -H "X-Auth-Token: $TOKEN" https://dfw.loadbalancers.api.rackspacecloud.com/v1.0/636983/loadbalancers/47219 | python -m json.tool
    {
          "loadBalancer": {
              "algorithm": "LEAST_CONNECTIONS", 
              "cluster": {
                  "name": "ztm-n09.dfw1.lbaas.rackspace.net"
              }, 
              "connectionLogging": {
                  "enabled": false
              }, 
              "contentCaching": {
                  "enabled": false
              }, 
              "created": {
                  "time": "2012-07-31T18:36:34Z"
              }, 
              "id": 47219, 
              "name": "Test1", 
              "nodes": [
                  {
                      "address": "108.166.119.217", 
                      "condition": "ENABLED", 
                      "id": 114445, 
                      "port": 80, 
                      "status": "ONLINE", 
                      "type": "PRIMARY"
                  }
              ], 
              "port": 80, 
              "protocol": "HTTP", 
              "sourceAddresses": {
                  "ipv4Public": "64.49.225.5", 
                  "ipv4Servicenet": "10.183.248.5", 
                  "ipv6Public": "2001:4800:7901::9/64"
              }, 
              "status": "ACTIVE", 
              "updated": {
                  "time": "2012-07-31T18:36:44Z"
              }, 
              "virtualIps": [
                  {
                      "address": "66.216.68.19", 
                      "id": 3925, 
                      "ipVersion": "IPV4", 
                      "type": "PUBLIC"
                  }, 
                  {
                      "address": "2001:4800:7901:0000:290c:0b6b:0000:0001", 
                      "id": 9041755, 
                      "ipVersion": "IPV6", 
                      "type": "PUBLIC"
                  }
              ]
          }
      }


Ok, that returns a lot of stuff. The thing we need from this output is the ID, 114445 and the ipv4 Public IP, 64.49.225.5.

Now that we've collected all the required information, the next step is calling the Cloud DNS API with a POST operation to create the PTR record and associate it with the Load Balancer. First thing I did was create the following JSON data in a text editor:

    
    {
    "recordsList" : {
    "records" : [ {
    "name" : "www.sisk.ws",
    "type" : "PTR",
    "data" : "66.216.68.19",
    "ttl" : 56000
    }, {
    "name" : "www.sisk.ws",
    "type" : "PTR",
    "data" : "2001:4800:7901:0000:290c:0b6b:0000:0001",
    "ttl" : 56000
    } ]
    },
    "link" : {
    "content" : "",
    "href" : "https://dfw.loadbalancers.api.rackspacecloud.com/v1.0/636983/loadbalancers/47219",
    "rel" : "cloudLoadBalancers"
    }
    }


This lists all the data we need to create the PTR record. In this example I also added the IPV6 address, too. Let's give it a try:

    
    $ curl -D – -X POST -d '{
    "recordsList" : {
    "records" : [ {
    "name" : "www.sisk.ws",
    "type" : "PTR",
    "data" : "66.216.68.19",
    "ttl" : 56000
    }, {
    "name" : "www.sisk.ws",
    "type" : "PTR",
    "data" : "2001:4800:7901:0000:290c:0b6b:0000:0001",
    "ttl" : 56000
    } ]
    },
    "link" : {
    "content" : "",
    "href" : "https://dfw.loadbalancers.api.rackspacecloud.com/v1.0/636983/loadbalancers/47219",
    "rel" : "cloudLoadBalancers"
    }
    }' -H "Content-Type: application/json" -H "X-Auth-Token: $TOKEN" https://dns.api.rackspacecloud.com/v1.0/636983/rdns


I just typed in the commands and pasted in the above JSON file between the single-quote marks after the -d. In the Cloud DNS API commands that create stuff are asynchronous -- what we get back is a URL to check to see the status of the job.

This is what we get back from the above POST:

    
    {"request":"{\n  \"recordsList\" : {\n    \"records\" : [ {\n      \"name\" : \"www.sisk.ws\",\n      \"type\" : \"PTR\",\n      \"data\" : \"66.216.68.19\",\n      \"ttl\" : 56000\n    }, {\n      \"name\" : \"www.sisk.ws\",\n      \"type\" : \"PTR\",\n      \"data\" : \"2001:4800:7901:0000:290c:0b6b:0000:0001\",\n      \"ttl\" : 56000\n    } ]\n  },\n  \"link\" : {\n    \"content\" : \"\",\n    \"href\" : \"https://dfw.loadbalancers.api.rackspacecloud.com/v1.0/636983/loadbalancers/47219\",\n    \"rel\" : \"cloudLoadBalancers\"\n  }\n}","status":"INITIALIZED","verb":"POST","jobId":"f99c1203-b42a-44c4-885f-c80bd7e3aba0","callbackUrl":"https://dns.api.rackspacecloud.com/v1.0/636983/status/f99c1203-b42a-44c4-885f-c80bd7e3aba0","requestUrl":"https://dns.api.rackspacecloud.com/v1.0/636983/rdns"}


Let's check the job status:

    
    $ curl -s -H "X-Auth-Token: $TOKEN" https://dns.api.rackspacecloud.com/v1.0/636983/status/f99c1203-b42a-44c4-885f-c80bd7e3aba0 | python -m json.tool
          {
              "callbackUrl": "https://dns.api.rackspacecloud.com/v1.0/636983/status/f99c1203-b42a-44c4-885f-c80bd7e3aba0", 
              "jobId": "f99c1203-b42a-44c4-885f-c80bd7e3aba0", 
              "status": "COMPLETED"
          }


These jobs complete quickly, so by the time you check it's usually done. If the system is under a lot of load, or it's a really big job (like updating hundreds of records) it might take a few minutes.

Ok, let's see what the PTR record looks like. First, keep in mind the PTR record lives with the device, not the domain record. So doing a list of the domain won't show us the PTR. We have to list it from the device like this:

    
    $ curl -s -H "X-Auth-Token: $TOKEN" https://dns.api.rackspacecloud.com/v1.0/636983/rdns/cloudLoadBalancers?href=https://dfw.loadbalancers.api.rackspacecloud.com/v1.0/636983/loadbalancers/47219 | python -m json.tool
          {
              "records": [
                  {
                      "created": "2012-07-31T20:16:32.000+0000", 
                      "data": "66.216.68.19", 
                      "id": "PTR-239719", 
                      "name": "www.sisk.ws", 
                      "ttl": 56000, 
                      "type": "PTR", 
                      "updated": "2012-07-31T20:16:32.000+0000"
                  }, 
                  {
                      "created": "2012-07-31T20:16:35.000+0000", 
                      "data": "2001:4800:7901:0:290c:b6b:0:1", 
                      "id": "PTR-239720", 
                      "name": "www.sisk.ws", 
                      "ttl": 56000, 
                      "type": "PTR", 
                      "updated": "2012-07-31T20:16:35.000+0000"
                  }
              ]
          }


Ok, looks good. Let's test it:

    
    $ host www.sisk.ws
    www.sisk.ws has address 66.216.68.19
    $  host 66.216.68.19
    19.68.216.66.in-addr.arpa domain name pointer www.sisk.ws.


Looks good -- that's what we expect to see. To compare, let's see what it looks like with the root of the domain, which is pointing to a first generation cloud server that doesn't support PTR records:

    
    $ host sisk.ws
    sisk.ws has address 108.166.119.217
    $ host 108.166.119.217
    217.119.166.108.in-addr.arpa domain name pointer 108-166-119-217.static.cloud-ips.com.


For more information on the Rackspace Cloud DNS API, refer to our [API documentation](https://docs.rackspace.com/cdns/api/v1.0/cdns-devguide/content/index.html).
