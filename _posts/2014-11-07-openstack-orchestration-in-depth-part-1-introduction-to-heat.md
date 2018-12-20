---
layout: post
title: 'OpenStack Orchestration In Depth, Part I: Introduction to Heat'
date: '2014-11-07 07:15'
comments: true
author: Miguel Grinberg
published: true
categories:
  - Private Cloud
  - Orchestration
  - AWS
bio: "Miguel Grinberg is a software engineer with a background in web technologies and REST APIs. He is the author of the book \"Flask Web Development\" from O'Reilly Media, and has a blog at http://blog.miguelgrinberg.com, where he writes about a variety of topics including web development, robotics, photography and the occasional movie review. Miguel works as a Software Developer with the Rackspace Private Cloud team. He lives in Portland, Oregon with his wife, four kids, two dogs and a cat. Follow @miguelgrinberg on Twitter."
---

With this article I begin a series of hands-on developer oriented blog posts that
explore OpenStack orchestration using
[Heat](https://wiki.openstack.org/wiki/Heat).

To make the most of this article, I recommend that you have an OpenStack installation where you can run the examples I present below. You can use our [Rackspace Private Cloud](http://www.rackspace.com/cloud/private/) distribution, [DevStack](http://devstack.org/), or any other OpenStack distribution that includes Heat.

<!-- more -->

What is Heat?
-------------

**Heat** is the main project of the OpenStack orchestration program. It allows
users to describe deployments of complex cloud applications in text files called
*templates*. These templates are then parsed and executed by the Heat
engine.

Heat was born as the counterpart to the [CloudFormation](http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/Welcome.html?r=7078)
service in AWS. It accepts AWS templates and provides a compatible API, but in recent OpenStack releases it has also began to grow outside of the shadow of CloudFormation, providing a nicer template syntax (the Heat Orchestration Template, or HOT) and new features not supported by its competitor.

Installing the Heat Client
--------------------------

As is common with all OpenStack services, low-level access to Heat is available through a [REST API](http://developer.openstack.org/api-ref-orchestration-v1.html). In most cases, however, working with a client is more convenient. There are two official Heat clients; a stand-alone command line client and a web-based client included with Horizon, the OpenStack dashboard project.

All the examples I present in this series of articles use the command line client, which you have to install on your computer. I am not going to show how to use the web-based client, but you should have no trouble figuring it out on your own as it is very simple.

The following commands create a Python virtual environment and install the Heat command line client in it, assuming you use `bash` or similar command prompt:

    $ virtualenv venv
    $ source venv/bin/activate
    (venv) $ pip install python-heatclient

For those working on Windows, the commands are slightly different:

    $ virtualenv venv
    $ venv\Scripts\activate
    (venv) $ pip install python-heatclient

Note that the above commands assume you have Python and `virtualenv` already installed on your system.

To verify that `heat` was installed successfully, just run the client without arguments to see its help message:

    (venv) $ heat
    usage: heat [--version] [-d] [-v] [-k] [--os-cacert <ca-certificate>]
                [--cert-file CERT_FILE] [--key-file KEY_FILE] [--ca-file CA_FILE]
                [--api-timeout API_TIMEOUT] [--os-username OS_USERNAME]
                [--os-password OS_PASSWORD] [--os-tenant-id OS_TENANT_ID]
                [--os-tenant-name OS_TENANT_NAME] [--os-auth-url OS_AUTH_URL]
                [--os-region-name OS_REGION_NAME] [--os-auth-token OS_AUTH_TOKEN]
                [--os-no-client-auth] [--heat-url HEAT_URL]
                [--heat-api-version HEAT_API_VERSION]
                [--os-service-type OS_SERVICE_TYPE]
                [--os-endpoint-type OS_ENDPOINT_TYPE] [--include-password]
                <subcommand> ...

Like the other OpenStack command line clients, the heat client needs to have access to your account credentials, which you normally have in a `OPENRC` file. For the examples in this article I assume that you have imported your `OPENRC` credentials into the environment, so that there is no need to include credentials as command line arguments.

A Basic Heat Template
---------------------

You are probably anxious to see how Heat works, so let's dive right into it. Below you can see a very simple HOT template:

    heat_template_version: 2013-05-23

    description: Simple template to deploy a single compute instance

    resources:
      my_instance:
        type: OS::Nova::Server
        properties:
          image: cirros-0.3.3-x86_64
          flavor: m1.small
          key_name: my_key
          networks:
            - network: private-net

As you can see in the example, HOT templates are written as structured [YAML](http://www.yaml.org/) text files. This particular example contains three top-level sections:

- `heat_template_version` is a mandatory section that is used to specify the version of the template syntax that is used. Most templates you are going to see out there will have `2013-05-23` as version, the first release. There is also a newer version labeled `2014-10-16` and introduced with the Juno release that contains a few minor changes and additions.
- `description` is optional, and it is used to provide a description of what the template does.
- `resources` is the most important section in a template, because this is where the different components are defined. In this first example, the only resource is called `my_instance`, and it is declared with type `OS::Nova::Server`, which is the type of a Nova compute instance. The `properties` sub-section identifies which image, flavor, public key and private network to use for the instance.

Are you ready to launch this template? Copy/paste the above text into your favorite text editor, edit the image, flavor, key and private network names to match your OpenStack installation, and save the file as `heat_1a.yaml`.

**Note**: If you are working with OpenStack Havana or Icehouse, then the private network needs to be specified as an `id` instead of a name. You can find the `id` of your network using the `nova net-list` or `neutron net-list` commands. In the Juno release both the name and the `id` are supported.

Once you have the template on disk, you can use the following command to create a *stack* from the template:

    (venv) $ heat stack-create my_first_stack -f heat_1a.yaml
    +--------+----------------+--------------------+----------------------+
    | id     | stack_name     | stack_status       | creation_time        |
    +--------+----------------+--------------------+----------------------+
    | ...    | my_first_stack | CREATE_IN_PROGRESS | 2014-11-05T18:10:40Z |
    +--------+----------------+--------------------+----------------------+

Heat then starts a background job that instantiates the resources declared in the template. In this case, that resource is just a compute instance. To query the status of this job, use the following command:

    (venv) $ heat stack-show my_first_stack

The output shows all the information for this stack, including its status, which will eventually be `CREATE_COMPLETE` (or `CREATE_FAILED` if there was an error).

Template Parameters and Outputs
-------------------------------

The template I presented in the previous section is extremely simple and not very useful. It is actually not very convenient to have to edit the template to match a particular OpenStack installation. Let's look at an improved version:

    heat_template_version: 2013-05-23

    description: Simple template to deploy a single compute instance

    parameters:
      image:
        type: string
        label: Image name or ID
        description: Image to be used for compute instance
        default: cirros-0.3.3-x86_64
      flavor:
        type: string
        label: Flavor
        description: Type of instance (flavor) to be used
        default: m1.small
      key:
        type: string
        label: Key name
        description: Name of key-pair to be used for compute instance
        default: my_key
      private_network:
        type: string
        label: Private network name or ID
        description: Network to attach instance to.
        default: private-net

    resources:
      my_instance:
        type: OS::Nova::Server
        properties:
          image: { get_param: image }
          flavor: { get_param: flavor }
          key_name: { get_param: key }
          networks:
            - network: { get_param: private_network }

    outputs:
      instance_ip:
        description: IP address of the instance
        value: { get_attr: [my_instance, first_address] }

This new version of the template adds two new top-level sections:

- `parameters` is used to declare a list of inputs that need to be provided by the user.
- `outputs` defines what attributes of the stack to export after it is deployed.

By using a `parameters` section, a template can be made generic. Each parameter is given a name and a type and, optionally, a description and a default value. The `get_param` function is then used to insert parameter values into resource properties. Looking at the other side, the `get_attr` function is used in the `outputs` section to extract desired attributes of the resources included in the stack.

To try this new template, save it as file `heat_1b.yaml` and launch it as shown before. Unless your system is identical to mine, you are probably going to get an error, because the parameter defaults that I defined will likely not match your OpenStack installation. However, since these settings are now parameters, you can specify appropriate values for your environment in the `stack-create` command without having to edit the template file. For example:

    (venv) $ heat stack-create second_stack -f heat_1b.yaml -P "key=my_key_name;image=Trusty"

In this example, the `key` parameter is set to `"my_key_name"` and the `image` parameter is set to `"Trusty"`, so those values will be used for this instantiation of the stack. For any parameters not included in the `-P` option, the defaults are used, which applies to `flavor` and `private_network` in this example. Note that parameters that do not have a default value defined must be included in the `stack-create` command, so it is a good idea to define defaults whenever possible.

Once the stack is created, the `stack-show` command includes the attributes requested in the `outputs` section:

    (venv) $ heat stack-show second_stack
    +----------------------+-------------------------------------------------------+
    | Property             | Value                                                 |
    +----------------------+-------------------------------------------------------+
    | ...                  |                                                       |
    | ...                  |                                                       |
    | outputs              | [                                                     |
    |                      |   {                                                   |
    |                      |     "output_value": "10.10.10.72",                    |
    |                      |     "description": "IP address of the instance",      |
    |                      |     "output_key": "instance_ip"                       |
    |                      |   }                                                   |
    |                      | ]                                                     |
    | ...                  |                                                       |
    | ...                  |                                                       |
    +----------------------+-------------------------------------------------------+

Conclusion
----------

In this article you saw how to create and launch simple Heat templates and how to code these templates generically using parameters and outputs. But this is a tiny portion of what you can do with Heat! Things start to get much more interesting when you use it to deploy complex applications that include web servers, databases, etc.

I hope this article served as a gentle introduction to Heat. There are two important links that will help you expand your understanding of HOT templates and complement what you have seen in this article:

- [HOT Template Specification](http://docs.openstack.org/developer/heat/template_guide/hot_spec.html): a formal description of the HOT template syntax.
- [OpenStack Resource Types](http://docs.openstack.org/developer/heat/template_guide/openstack.html): a detailed reference of all the supported resource types for HOT templates, including the properties and attributes that each provides.

Starting with the next article in the series, I'm going to show you the different ways in which you can deploy complex applications, which is Heat's bread and butter. I hope to see you then!
