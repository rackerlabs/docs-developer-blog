---
layout: post
title: 'I Have A Cloud...Now What? - Part 1: Building a 3-tier Webapp'
date: '2014-07-24 12:26'
comments: true
author: Mike Metral
published: true
categories:
  - cloud-servers
  - OpenStack
---

When we meet with customers, a constant set of questions we get asked goes something
like this: "OK, now that I have access to a cloud, what do I do with it? How can
I make sure I take full advantage of my cloud? How do I
properly architect my webapps to leverage the resources cloud makes available to me?"

All of these questions are great and merit a worthy answer. However, the truth
is that talking about it can only get you so far - insert [Project Touchstone](https://github.com/metral/touchstone):
a collection of mini projects meant to extensively showcase how one should architect,
consume, organize and orchestrate real-world web stacks on the infrastructures provided by the Rackspace Public & Private cloud.

<!-- more -->

## Architecture
For this first blog post, lets begin by seeing how we would architect your typical [3-tier webapp](https://en.wikipedia.org/wiki/Multitier_architecture#Web_development_usage). To set
the scene, we will be reviewing how to build the [Encoder project](https://github.com/metral/touchstone/tree/master/encoder), a webapp that that allows a
user to submit a video file and convert it to the AVI, MKV, OGG and WEBM formats.

Note, many intricate decisions were made for the Encoder project itself and the technologies chosen
are not prescriptive, but nevertheless, the following is the proposed architecture for the Encoder
webapp:

{% img https://raw.githubusercontent.com/metral/touchstone/master/encoder/extras/encoder.jpg %}

## Enabling Orchestration
With the architecture laid out, we now focus on how to coordinate & construct our stack. We can organize & orchestrate the provisioning of the
cloud infrastructure through [Rackspace's Cloud Orchestration](https://www.rackspace.com/blog/cloud-orchestration-automating-deployments-of-full-stack-configurations/)
aka the [Heat](https://wiki.openstack.org/wiki/Heat) project from OpenStack. By doing so, we can leverage capabilities which allow for a self-configuration of the web services, in a repeatable fashion, that also allows for expansion further down the road.

Orchestration for our stack is described using the
[YAML](https://en.wikipedia.org/wiki/YAML) format,
and as an example, we'll examine a snippet of the template used to create the Encoder's stack
in the Rackspace Public Cloud. The full template can be found at [https://git.io/MEpetw](https://git.io/MEpetw).

```
resources:

  frontend_server:
    type: "Rackspace::Cloud::Server"
    properties:
      flavor: 2 GB Performance
      image: { get_param: image }
      name: { get_param: frontend_server_name }
      user_data:
        str_replace:
          template: |
            #!/bin/bash
            apt-get update && apt-get install curl -y
            curl -skS -L https://raw.github.com/metral/touchstone/%branch%/encoder/server_userdata/frontend.sh | sudo bash /dev/stdin %webapp_ip% %branch%
          params:
            "%webapp_ip%": { get_attr: [ webapp_server, privateIPv4 ] }
            "%branch%": { get_param: branch }

  webapp_server:
    type: "Rackspace::Cloud::Server"
    properties:
      flavor: 2 GB Performance
      image: { get_param: image }
      name: { get_param: webapp_server_name }
      user_data:
        str_replace:
          template: |
            #!/bin/bash
            apt-get update && apt-get install curl -y
            curl -skS -L https://raw.github.com/metral/touchstone/%branch%/encoder/server_userdata/webapp.sh | sudo bash /dev/stdin %rax_username% %rax_apikey% %data_master_ip% %mysql_pass% %use_snet% %branch%
          params:
            "%rax_username%": { get_param: rax_username }
            "%rax_apikey%": { get_param: rax_apikey }
            "%data_master_ip%": { get_attr: [ data_master_server, privateIPv4 ] }
            "%mysql_pass%": { get_param: mysql_pass }
            "%use_snet%": { get_param: use_snet }
            "%branch%": { get_param: branch }
```

As you can note, we are defining [Rackspace resource types](https://docs.rackspace.com/orchestration/api/v1/orchestration-devguide/content/GET_resource_type_list_v1__tenant_id__resource_types_Stack_Resources.html#GET_resource_type_list_v1__tenant_id__resource_types_Stack_Resources-Response)
for the frontend and webserver nodes made available via Orchestration.

In addition to resource types, we can define properties such as the flavor
hardware profile to utilize for the VM. We can even extend the resources by retrieving parameters such as the default VM image to use,
the names of the servers, as well as pass in custom init scripts with
parameters of other Heat resources that execute
after the VM has been instantiated - this showcases the ability to create
relationships with other components established in the template.

Heat can do so much more, and I encourage you to spend some time in the
[developer docs](https://docs.openstack.org/developer/heat/) to see the power
that it can wield.

## Synopsis
Given that our architecture, environment and tools are established, lets move on to the specifics of the encoder project. Again, we want to setup a webapp that encodes a provided video file into the following formats:

  * [AVI](https://en.wikipedia.org/wiki/Audio_Video_Interleave)
  * [MKV](https://en.wikipedia.org/wiki/Matroska)
  * [OGG](https://en.wikipedia.org/wiki/Ogg)
  * [WEBM](https://en.wikipedia.org/wiki/WebM)

## Webapp Flow
  * When the user visits the webapp, they are presented with the ability to upload a video file
  * The user will select a video file already available & stored locally on their computer
  * The video file will then be uploaded to the object storage service provided by Rackspace Cloud Files
  * Upon a successful upload, the webapp will create an encoding job request that will be entered into the MySQL database for tracking
  * The encoding job is the passed off to the Gearman Job Server for processing
  * Once the Gearman Job Server receives the job request, it will locate an available Gearman Job Worker to perform the encoding job
  * The Gearman Job Worker then utilizes the [FFmpeg](https://www.ffmpeg.org/) encoding library to convert the user's video into the available formats
  * Once the video has been encoded into each format by the Gearman Job Worker, it will upload the encoding to Rackspace Cloud Files
  * All the while, the webapp will be providing a means to view the status of the encoding job as well as publicly accessible URL's of each encoding format as they become available for consumption
  * Because video conversion is so exhaustive on the CPU, we want to create an email alert that notifies us when the load average on the Gearman Job Worker passes a certain threshold, as this is an indication that special attention is required. To do so, we incorporate [Monitoring as a Service](https://www.rackspace.com/blog/using-cloud-monitoring-on-your-rackspace-private-cloud/)

## Rackspace Cloud Services Used
  * Cloud Servers
  * Cloud Files
  * Service Network
  * Orchestration (OpenStack Heat)

## Test Drive
If you'd like to instantiate the Encoder job right now, you can do this from
the [heat client](https://docs.rackspace.com/orchestration/api/v1/orchestration-getting-started/content/Install_Heat_Client.html) by issuing the following to run on the Rackspace Public Cloud or see the Demo section below to see how its intended to function:

```
BRANCH=master ; EMAIL='<your-user>@<your-email-provider.com>' ; USE_SNET=true; \
heat stack-create encoder \
--parameters= "rax_username=$OS_USERNAME;rax_apikey=$OS_PASSWORD;email=$EMAIL;branch=$BRANCH;use_snet=$USE_SNET"\
-u "https://raw.github.com/metral/touchstone/$BRANCH/encoder/public_cloud_encoder.yaml"
```

You can monitor the status of the heat deployment by viewing the stack_status
property via:

```
heat stack-show encoder
```

Once the stack has completed, you can retrieve the output value of the
frontend_url, which is the globally accessible IP address of the Encoder
webapp, from the `heat stack-show encoder` information to access the webstack.

i.e.

```
{
    "output_value": "23.253.147.207",
    "description": "The landing page url for the Encoder webapp",
    "output_key": "frontend_url"
}
```

## Demo
Since the specifics of the webapp itself are beyond the intent of
this blog post, you should now have the necessary information to understand how
you would carry out a similar stack. Therefore, when you deploy the Encoder
project you'll be presented with an app that functions as such:

{% img i-have-a-cloud-dot-dot-dot-now-what-part-1-building-a-3-tier-webapp/encoder.gif%}

## About the Author
Mike Metral is a Solution Architect at Rackspace in the Private Cloud R&D
organization. Mike joined Rackspace in 2012 to help establish OpenStack become the open standard for cloud management.
You can follow Mike on Twitter [@mikemetral](https://twitter.com/mikemetral) and Github as
[metral](https://github.com/metral)
