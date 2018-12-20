---
layout: post
title: Using Heat with Rackspace Private Cloud
date: '2014-11-03 23:59'
comments: true
author: Walter Bentley
published: true
categories:
  - Private Cloud
  - OpenStack
bio: 'Walter Bentley is a Rackspace Private Cloud Solutions Architect with a background in Production Systems Administration and Solutions Architecture. In the past, always being the requester, consumer and advisor to companies to use technologies such as OpenStack, now promoter of OpenStack technology and Cloud educator. Twitter @djstayflypro'
---

One of the **HOT**est new projects released within the previous release of OpenStack is the Heat project.  Described as a main line project part of the OpenStack Orchestration program because Heat alone is not the complete orchestration capability being developed by the community, my gut tells me we have more projects based on orchestration coming soon.  Setting some base ground work on what Heat provides capability wise is important.  This is covered in two quick topics, what is orchestration and what is a stack?

<!-- more -->

####What is Orchestration?
See orchestration as a way to automate the manual steps that you take to install a supporting application software or to provision infrastructure resources to support your applications. Imagine your business team asking IT to stand up servers, where each server needs to run a separate support software (Apache, JBoss and MySQL). Of course, the next request from the business team is that they need this task done for every new code release in multiple test environments. This one simple task just turned into an Infrastructure support engineer's nightmare. As we all know, especially me, personally, after 15 years of Production support, most engineers do not have the time to reproduce this task and would much rather give the business team the ability to do it themselves *(with IT oversight, of course…LOL)*. The ultimate solution? Create scripts/templates in order to automate the business request and develop it to be consumed in a self-service model. This, in essence, is the definition of Orchestration.

####What is a Stack?
Consider a technology stack as something similar to lego blocks. Generally the idea of layering on technology components is to create a collection of objects. In our case, the technology components could include instances (VMs), networks, subnets, routers, ports, router interfaces, security groups, autoscaling rules and etc. Stacks could also surely include software dependencies or the custom applications themselves.  Every lego block design has to have a base.  From a Private cloud perspective that base will always be your computing resources from your OpenStack cloud.  This is where Heat can give you an automation edge to get started down your orchestration journey.

####What is Heat?
As mentioned before Heat is a main line project part of OpenStack and composed of an orchestration engine used to launch multiple composite cloud applications based on templates in the form of text files.  These text files should be treated like code…this is how the term "Infrastructure as Code" was born.  The template format supported by Heat is called **HOT** (aka Heat Orchestration Template).  As with all other OpenStack components, the functionality offered by Heat is available via a ReST API and/or python CLI.

The template standard, HOT, is built around a standardized template definition called YAML.  Honestly, it is one of the easiest template formats to read and learn.  See the following link for more details around the HOT template specification and structure:

[HOT Template Specification](http://docs.openstack.org/developer/heat/template_guide/hot_spec.html)

Once a template is executed within your RPC environment, it is then defined as a stack.  Execution of that stack will provision the resources configured in the template and report on the status.  Please keep in mind that removing a stack will also remove the resources provisioned, such as instances created, unless you tell Heat to abandon that stack.

Below is a simple example of how to create a new Heat stack via the CLI:

    $ heat stack-create <name of stack> --template-file=<hot template name>.yaml \
    --parameters=“key_name=<pub key name>;flavor=<flavor type>;image=<glance image id>; \
    network=<neutron network id>;vol_size=<volume size>”

or you can provide an environment file with all the parameters pre-populated in it.  Such an example would look like this:

    $ heat stack-create <name of stack> --template-file=<hot template name>.yaml \
    --environment-file=<path/name of env file>.yaml


Heat has six main sub-functions used to create, test, run, update and remove stacks created.

**Some basic Heat CLI commands:**

    heat stack-create – create the stack
    heat stack-delete – delete the stack(s)
    heat stack-list – list the user’s stacks
    heat stack-preview – preview what will be created in a stack
    heat stack-show – shows details about the stack
    heat stack-update – update an existing stack

**Some basic Heat API commands:**

    POST  /v1/{tenant_id}/stacks - Create stack
    DELETE  /v1/{tenant_id}/stacks/{stack_name}/{stack_id} - Delete stack
    GET  /v1/{tenant_id}/stacks- List stack data
    POST /v1/{tenant_id}/stacks/preview - Preview stack
    GET  /v1/{tenant_id}/stacks/{stack_name}/{stack_id} - Show stack details
    PUT  /v1/{tenant_id}/stacks/{stack_name}/{stack_id} - Update stack

Using Heat, you can quickly bridge the gap around automating many Infrastructure needs within your Private cloud built on OpenStack. Within one HOT script, an engineer could programmatically code the creation of the 3 tiered stack and hand that template over to the business units to be executed within their designated tenant(s). Or even better, use external automation tools such as Ansible Tower to expose that template for execution.

Thus far, working with Heat has been a very positive experience. Dependable, Heat even has an added quality assurance feature: it qualifies the template before officially executing it. I look forward to seeing what additional functionality will be built into Heat and any other new OpenStack projects. Personally, I have my eye on Ceilometer, knowing the power it can create when paired with Heat *(orchestration + resource consumption metrics = autoscale)*.

Also, please make sure to watch my Webinar on Heat to see three short demos of how you can use Heat running on Rackspace Private Cloud:
[https://www.brighttalk.com/webcast/11427/129795](https://www.brighttalk.com/webcast/11427/129795)

**More information about the Heat CLI and API can be found below:**

[Heat client documentation](http://docs.openstack.org/cli-reference/content/heatclient_commands.html)
[API reference](http://developer.openstack.org/api-ref-orchestration-v1.html)

**Example Heat templates can be found on my GitHub repository:**
[https://github.com/wbentley15/openstack-heat-templates.git](https://github.com/wbentley15/openstack-heat-templates.git)