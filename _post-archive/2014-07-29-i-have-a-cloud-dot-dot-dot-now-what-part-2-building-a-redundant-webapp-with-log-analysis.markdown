---
layout: post
title: >-
  I Have A Cloud...Now What? - Part 2: Building a Redundant Webapp with Log
  Analysis
date: '2014-07-29 11:40'
comments: true
author: Mike Metral
published: true
categories:
  - cloud-servers
  - OpenStack
bio: |
  Mike Metral is a Solution Architect at Rackspace in the Private Cloud R&D
  organization. Mike joined Rackspace in 2012 to help establish OpenStack as
  the open standard for cloud management.
  You can follow Mike on Twitter @mikemetral and Github as metral
---

[Project Touchstone](https://github.com/metral/touchstone) is intended to serve as a reference of actual usecases & examples for cloud applications in the Rackspace ecosystem.

In this blog post, we will be continuing with our "I Have a Cloud...Now What?" series, and build out a redundant & scalable webapp that also showcases how one can easily organize & analyze the logs their apps produce in a novel & informational manner.

<!-- more -->

## Architecture
To set the scene, we will be reviewing how to build the [Logging project](https://github.com/metral/touchstone/tree/master/logging), a webapp that that allows a
user to cycle through a simple hello world app being served amongst numerous webapp hosts, and view their logs through the usage of the tools Elasticsearch + Logstash + Kibana.

Note, many intricate decisions were made for the Logging project itself and the technologies chosen
are not prescriptive, but nevertheless, the following is the proposed architecture for the Logging
webapp:

{% img https://raw.githubusercontent.com/metral/touchstone/master/logging/extras/logging.jpg %}

## Enabling Orchestration
With the architecture laid out, we now focus on how to coordinate & construct our stack.

If you followed [Part 1](https://developer.rackspace.com/blog/i-have-a-cloud-dot-dot-dot-now-what-part-1-building-a-3-tier-webapp/) of this series, you'll remember that we can organize & orchestrate the provisioning of the
cloud infrastructure through [Rackspace's Cloud Orchestration](https://www.rackspace.com/blog/cloud-orchestration-automating-deployments-of-full-stack-configurations/)
aka the [Heat](https://wiki.openstack.org/wiki/Heat) project from OpenStack.

Lets examine a snippet of the template used to create the Logging stack, that differs from the Encoder stack,
in the Rackspace Public Cloud. The full template can be found at [https://git.io/kdlx2g](https://git.io/kdlx2g).

```
resources:

  load_balancer_frontend:
    type: "Rackspace::Cloud::LoadBalancer"
    properties:
      name: "lb-frontend"
      nodes:
      - addresses: [get_attr: [frontend_server1, privateIPv4], get_attr: [frontend_server2, privateIPv4]]
        port: 80
        condition: ENABLED
      port: 80
      protocol: HTTP
      algorithm: "LEAST_CONNECTIONS"
      virtualIps:
      - type: PUBLIC
        ipVersion: IPV4
      healthMonitor:
        attemptsBeforeDeactivation: 3
        delay: 10
        timeout: 120
        type: HTTP
        path: "/"
        statusRegex: "^[234][0-9][0-9]$"
        bodyRegex: ""

  ...

  webapp_nodes1:
    type: "OS::Heat::ResourceGroup"
    properties:
      count: 2
      resource_def:
        type: "Rackspace::Cloud::Server"
        properties:
            flavor: 2 GB Performance
            image: { get_param: image }
            user_data:
                str_replace:
                    template: |
                        #!/bin/bash
                        apt-get update && apt-get install curl -y
                        curl -sKS -L https://raw.github.com/metral/touchstone/%branch%/logging/server_userdata/webapp.sh | sudo bash /dev/stdin %branch%
                        curl -skS -L https://raw.github.com/metral/touchstone/%branch%/logging/server_userdata/rsyslog_client_webapp.sh | sudo bash /dev/stdin %branch% %rsyslog_server_ip%
                    params:
                        "%branch%": { get_param: branch }
                        "%rsyslog_server_ip%": { get_attr: [rsyslog_server, privateIPv4] }
```

As you can note, we are defining [Rackspace resource types](https://docs.rackspace.com/orchestration/api/v1/orchestration-devguide/content/GET_resource_type_list_v1__tenant_id__resource_types_Stack_Resources.html#GET_resource_type_list_v1__tenant_id__resource_types_Stack_Resources-Response)
for the rsyslog\_server and load\_balancer made available via Orchestration.

A new set of resource types are being introduced in this stack: Rackspace::Cloud::LoadBalancer & OS::Heat::ResourceGroup.
Respectively, they instantiate a Rackspace Cloud Load Balancer and a set of identical and related webserver nodes that we can create as a logical resource grouping.

## Synopsis
Again, we will be setting up a redundant hello world webapp that
feeds into a log aggregator and then filters, stores & allows for the
visulization of the logs.

## Webapp Flow
  * When the user visits the webapp, they will be presented with a simple Hello World page which displays the hostname of the webapp server that fulfilled the request
  * Behind the scenes, the Cloud Load Balancer is cycling through 2 frontend nodes tasked with receiving HTTP requests
  * The frontend nodes each manage a pair of 2 webapp servers that it cycles through when forwarding the incoming requests, for a total of 4 webapp servers
  * The webapp then renders a page with the hostname of the server that is processing the request to demonstrate the redundancy taking place, which in a real-world example would all be serving identical content
  * The Cloud Load Balancer also monitors the health of the frontend + webapp combo by insuring that these nodes in the load balancing layer are not erroring out with HTTP status codes of 5XX - if they do, they are pulled from the load balancing pool
  * The frontend & webapp nodes are simultaneously feeding all of their raw, noteworthy logs (i.e. Nginx + Gunicorn/Django) to an rsyslog server which functions as a central log aggregate
  * The rsyslog server then passes the raw logs to an ELK stack (Elasticsearch + Logstash + Kibana) which filters, stores and provides visualization for the logs based on some basic logic releveant to the logs collected
    * i.e.
        * Logstash filters the Nginx & Gunicorn access-logs to parse relevant request header information
        * Logstash then passes the filtered logs to Elasticsearch, where they are stored
        * Kibana communicates with Elasticsearch to provide a visualization layer to view the parsed logs
  * If one wishes, you can easily increase the number of frontend & webapp nodes used by modifying the heat template to make the initial architecture even more redundant

## Rackspace Cloud Services Used
  * Cloud Servers
  * Cloud Load Balancers
  * Service Network
  * Orchestration (OpenStack Heat)

## Test Drive
If you'd like to instantiate the Logging job right now, you can do this from
the [heat client](https://docs.rackspace.com/orchestration/api/v1/orchestration-getting-started/content/Install_Heat_Client.html) by issuing the following to run on the Rackspace Public Cloud or see the Demo section below to see how its intended to function:

```
heat stack-create logging \
--parameters="branch=master" -u "https://raw.github.com/metral/touchstone/master/logging/public_cloud.yaml"
```

You can monitor the status of the heat deployment by viewing the stack_status
property via:

```
heat stack-show logging
```

Once the stack has completed, you can retrieve the output value of the
ELK stack and the Load Balancer, which are both the globally accessible IP addresses for the respecitive resource.

i.e.

```
{
    "output_value": "104.130.12.141",
    "description": "The public IP address of the ELK stack"
    "output_key": "elk_public_ip"
},
 {
    "output_value": "23.253.147.207",
    "description": "The public IP address of the load balancer",
    "output_key": "lb_public_ip"
}
```

By constantly refreshing the IP of the load balancer, you'll see it cycle
through the different webapps as denoted by their respective hostnames.
`https://<lb_public_ip>`

To view the ElasticSearch server, visit its address at port 9200. i.e.

`https://<elk_public_ip>:9200`

To view the Kibana dashboard, visit its address at port 8080 with the following
path:

`https://<elk_public_ip>:8000/index.html#/dashboard/file/logstash.json`

## Demo
When you deploy the Logging project you'll be presented with an app that functions as such in both the webapp and Kibana dashboard:

{% img i-have-a-cloud-dot-dot-dot-now-what-part-2-redundant-logging/logging.gif %}

## Log Analysis

The ElasticSearch + Logstash + Kibana (ELK) stack is a really extensive way to
filter, store and analyze your log files. In the logging project we are feeding
the access and error logs from Gunicorn (the app server for the Django HelloWorld project) as well as the access and error logs for the Nginx server into the ELK stack.

Here are examples of the functionality that you can gain from the ELK stack:

* Filter & tagging custom formats in Logstash and viewing it in ElasticSearch, i.e.
gunicorn-access, gunicorn-errors and nginx logs:
    {% img i-have-a-cloud-dot-dot-dot-now-what-part-2-redundant-logging/gunicorn_access.png %}
    {% img i-have-a-cloud-dot-dot-dot-now-what-part-2-redundant-logging/nginx.png %}
    {% img i-have-a-cloud-dot-dot-dot-now-what-part-2-redundant-logging/webstack_error.png %}

* Querying for custom fields parsed, i.e. The user agent of the Cloud Load
  Balancer health monitor and HTTP status codes of 500 when a server error was
  introduced:
    {% img i-have-a-cloud-dot-dot-dot-now-what-part-2-redundant-logging/kibana_500.png %}

* Viewing the extensive list of parsed fields that both syslog + logstash +
  custom formatting accomplish:
    {% img i-have-a-cloud-dot-dot-dot-now-what-part-2-redundant-logging/kibana_500_detail.png %}

## Conclusion
Hopefully this post has given you the ability to gain insight into how easy it is to scale your
application out as well as enable redundancy. All while simultaneously processing
all of your important data in an easy, custom & comprehensible manner.
