---
layout: post
title: 'OpenStack Orchestration In Depth, Part II: Single Instance Deployments'
date: '2014-11-14 07:15'
comments: true
author: Miguel Grinberg
published: true
categories:
  - Private Cloud
  - Orchestration
bio: "Miguel Grinberg is a software engineer with a background in web technologies and REST APIs. He is the author of the book \"Flask Web Development\" from O'Reilly Media, and has a blog at http://blog.miguelgrinberg.com, where he writes about a variety of topics including web development, robotics, photography and the occasional movie review. Miguel works as a Software Developer with the Rackspace Private Cloud team. He lives in Portland, Oregon with his wife, four kids, two dogs and a cat. Follow @miguelgrinberg on Twitter."
---

Welcome to the second part of my series on OpenStack orchestration with Heat. In the [previous article](/blog/openstack-orchestration-in-depth-part-1-introduction-to-heat) I gave you an introduction to Heat orchestration. All the examples I showed you were simple and not terribly useful, as they were only intended to introduce the structure of the HOT (Heat Orchestration Template) syntax.

In today's article, I'm going to elevate the complexity quite a bit, demonstrating some of the tricks you can use with Heat to perform deployments of single instance applications. As with the introductory examples, you are encouraged to try my examples on a [Rackspace Private Cloud](http://www.rackspace.com/cloud/private/), [DevStack](http://devstack.org/) or any other OpenStack installation that includes Heat.

<!-- more -->

## GitHub Repository

Before I begin, I want to give you the location of a GitHub repository I created for the example templates:

[https://github.com/miguelgrinberg/heat-tutorial](https://github.com/miguelgrinberg/heat-tutorial)

In this repository, you can find all the templates I present in this and the other articles in the series. I have tested these templates on the Juno release of OpenStack, but I expect they will also work on the Icehouse release.

## Deploying an Application on First Boot

The [cloud-init](http://cloudinit.readthedocs.org/) package is the defacto standard for initialization of cloud instances. It comes pre-installed on most official cloud images, including Ubuntu and Fedora, and it is even available on the Cirros images used for testing. Cloud-init runs during the initial boot of an instance, and it contacts the Nova metadata service API to see if there are any actions that need to be carried out.

The easiest way to interact with the cloud-init service is by providing a script to run during boot. The script is executed as the root user, so it has full access to the instance to install and apply configuration changes as necessary. Curious to see how this works? Try the following template, which is a simple extension of template `heat_1b.yaml` from my previous article:

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
          user_data: |
            #!/bin/sh
            echo "Hello, World!"
          user_data_format: RAW

    outputs:
      instance_name:
        description: Name of the instance
        value: { get_attr: [my_instance, name] }
      instance_ip:
        description: IP address of the instance
        value: { get_attr: [my_instance, first_address] }

There are just a few changes in this template:

- The `user_data` property on the `my_instance` resource contains a small initialization script that prints a greeting message.
- The `user_data_format: RAW` property tells Heat to provide the `user_data` script as is to the instance, without any additional contents. In a future article I will show you other possible formats for instance user data.
- The `instance_name` output is set to export the name assigned to the instance.

You can download the above template by clicking here: [heat_2a.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/heat_2a.yaml). Then you can give it try with the following command:

    (venv) $ heat stack-create stack_with_init_script -f heat_2a.yaml

If you are an extremely lazy person, instead of downloading the template you can deploy it directly from my GitHub repository:

    (venv) $ heat stack-create stack_with_init_script -u https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/heat_2a.yaml

If any of the parameter defaults are not appropriate for your environment, then provide new values using the `-P` command line option. For example, if your private network is called "private" instead of "private-net", and you want to use an image called "Trusty" instead of my Cirros default, you can override the two defaults as follows:

    (venv) $ heat stack-create stack_with_init_script -f heat_2a.yaml -P "private_network=private;image=Trusty"

The next step is to verify that the user data script has executed. You can access the output of the script, logged in the instance's console log, with the `nova` command line client (or from the Horizon dashboard if you prefer to do it from a web browser). To get the console log, we first need to know the name that Heat assigned to the instance, and for that we can look at the outputs of the stack:

    (venv) $ heat stack-show stack_with_init_script
    +----------------------+------------------------------------------------------------------------+
    | Property             | Value                                                                  |
    +----------------------+------------------------------------------------------------------------+
    | ...                  |                                                                        |
    | ...                  |                                                                        |
    | outputs              | [                                                                      |
    |                      |   {                                                                    |
    |                      |     "output_value": "stack_with_init_script-my_instance-t5elvfeqdz63", |
    |                      |     "description": "Name of the instance",                             |
    |                      |     "output_key": "instance_name"                                      |
    |                      |   },                                                                   |
    |                      |   {                                                                    |
    |                      |     "output_value": "10.10.10.75",                                     |
    |                      |     "description": "IP address of the instance",                       |
    |                      |     "output_key": "instance_ip"                                        |
    |                      |   }                                                                    |
    |                      | ]                                                                      |
    | ...                  |                                                                        |
    | ...                  |                                                                        |
    +----------------------+------------------------------------------------------------------------+

Now that we know the name of the instance we can obtain its console log:

    (venv) $ nova console-log stack_with_init_script-my_instance-t5elvfeqdz63 | less

Scroll near the end of this log to find the `"Hello, World!"` message printed by the initialization script.

When you are done experimenting with this simple stack, you can delete it with the following command:

    (venv) $ heat stack-delete stack_with_init_script

### A Real Deployment

Of course deploying a script that prints a greeting to the log is not very interesting. But you can apply this technique to a real world deployment by making the user data script execute the required installation commands.

As an example, I'm going to show you an actual deployment script. The template that you can see below deploys a web application written in Python, using the Flask microframework. This is a microblogging application featured in my O'Reilly book as an advanced example. This application works with a database, sends email notifications, implements an API, and has a modern web interface, so it is an ideal test subject.

Below is the complete deployment template for this application. I invite you to see how much of it you can understand on your own before you continue reading:

    heat_template_version: 2013-05-23

    description: This template deploys a Flasky single instance server with a SQLite database.

    parameters:
      image:
        type: string
        label: Image name or ID
        description: Image to be used for the server. Please use an Ubuntu based image.
        default: trusty-server-cloudimg-amd64
      flavor:
        type: string
        label: Flavor
        description: Type of instance (flavor) to be used on the compute instance.
        default: m1.small
      key:
        type: string
        label: Key name
        description: Name of key-pair to be installed on the compute instance.
        default: my_key
      private_network:
        type: string
        label: Private network name or ID
        description: Private network to attach server to.
        default: private-net
      gmail_username:
        type: string
        label: Gmail account username
        description: Username of the Gmail account to use for notifications.
      gmail_password:
        type: string
        label: Gmail account password
        description: Password of the Gmail account to use for notifications.
        hidden: true

    resources:
      flask_secret_key:
        type: OS::Heat::RandomString
        properties:
          length: 32
          sequence: lettersdigits

      flasky_instance:
        type: OS::Nova::Server
        properties:
          image: { get_param: image }
          flavor: { get_param: flavor }
          key_name: { get_param: key }
          networks:
            - network: { get_param: private_network }
          user_data_format: RAW
          user_data:
            str_replace:
              params:
                __gmail_username__: { get_param: gmail_username }
                __gmail_password__: { get_param: gmail_password }
                __flask_secret_key__: { get_attr: [flask_secret_key, value] }
              template: |
                #!/bin/bash -ex

                # install dependencies
                apt-get update
                apt-get -y install build-essential python python-dev python-virtualenv nginx supervisor git

                # create a flasky user to run the server process
                adduser --disabled-password --gecos "" flasky

                # clone flasky from github
                cd /home/flasky
                git clone https://github.com/miguelgrinberg/flasky.git
                cd flasky

                # Write configuration file
                cat >.env <<EOF
                FLASK_CONFIG=heroku
                SECRET_KEY=__flask_secret_key__
                DATABASE_URL=sqlite:////home/flasky/flasky/appdb.sqlite
                MAIL_USERNAME=__gmail_username__
                MAIL_PASSWORD=__gmail_password__
                FLASKY_ADMIN=__gmail_username__@gmail.com
                SSL_DISABLE=1
                EOF

                # create a virtualenv and install dependencies
                virtualenv venv
                venv/bin/pip install -r requirements/prod.txt
                venv/bin/pip install gunicorn==18.0

                # create database
                venv/bin/python manage.py deploy

                # make the flasky user the owner of the application
                chown -R flasky:flasky ./

                # configure supervisor to run a private gunicorn web server, and
                # to autostart it on boot and when it crashes
                # stdout and stderr logs from the server will go to /var/log/flasky
                mkdir /var/log/flasky
                cat >/etc/supervisor/conf.d/flasky.conf <<EOF
                [program:flasky]
                command=/home/flasky/flasky/venv/bin/gunicorn -b 127.0.0.1:8000 -w 4 --chdir /home/flasky/flasky --log-file - manage:app
                user=flasky
                autostart=true
                autorestart=true
                stderr_logfile=/var/log/flasky/stderr.log
                stdout_logfile=/var/log/flasky/stdout.log
                EOF
                supervisorctl reread
                supervisorctl update

                # configure nginx as the front-end web server with a reverse proxy
                # rule to the gunicorn server
                cat >/etc/nginx/sites-available/flasky <<EOF
                server {
                    listen 80;
                    server_name _;
                    access_log /var/log/nginx/flasky.access.log;
                    error_log /var/log/nginx/flasky.error.log;
                    location / {
                        proxy_pass http://127.0.0.1:8000;
                        proxy_redirect off;
                        proxy_set_header Host \$host;
                        proxy_set_header X-Real-IP \$remote_addr;
                        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                    }
                    location /static {
                        alias /home/flasky/flasky/static;
                    }
                    location /favicon.ico {
                        alias /home/flasky/flasky/favicon.ico;
                    }
                }
                EOF
                rm -f /etc/nginx/sites-enabled/default
                ln -s /etc/nginx/sites-available/flasky /etc/nginx/sites-enabled/
                service nginx restart

    outputs:
      instance_name:
        description: Name of the instance
        value: { get_attr: [flasky_instance, name] }
      instance_ip:
        description: The IP address of the deployed instance
        value: { get_attr: [flasky_instance, first_address] }

If you want to try this template, download it from the following link: [heat_2b.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/heat_2b.yaml). Then launch it as follows:

    (venv) $ heat stack-create flasky -f heat_2b.yaml -P "gmail_username=<your-gmail-user>;gmail_password=<your-gmail-pw>"

As before, you may need to add additional parameters to the `-P` part if you need to use a different key pair, image, etc. Note that the two parameters that I show above are required because I have not defined defaults for them.

Let's analyze this template one piece at a time. First of all, I'm sure you noticed that there are two new parameters in this template that ask for your Gmail account credentials. The Flasky application sends emails to users to notify them of certain events, and the simplest way to have email sending capability is to use a third party email server, such as Gmail. This is useful for testing, but the Gmail service cannot be used for a production application. In this case I chose to work with Gmail to not complicate this example deployment even more. Your credentials are stored in a configuration file inside the instance, but they don't appear in logs (note the `hidden: true` property on the `gmail_password` parameter, which makes Heat treat that parameter with care).

The installation script in the `user_data` property makes up the bulk of this template, obviously. But the structure is a little bit different than the previous example. In this template I wrapped the script with the `str_replace` function, which is provided by Heat. This allows me to perform variable replacements within the code of the script. The `params` argument specifies a list of variables with their values, and the `template` argument contains the script code. The `str_replace` function replaces any occurrences of the variables with their values.

There are three variables that I want to replace in this script. Two are for the Gmail username and password, which are written to a configuration file. The third one is a special security key that Flask applications use to perform encryption of sensitive information. Note that the value of the secret key references a resource, which you can see defined above the server resource. This is a resource of type `OS::Heat::RandomString`, and, as its name implies, generates random strings that can be used as passwords or keys.

This script, written in bash, assumes the instance runs an Ubuntu based image. The `-ex` option is given to bash so that all commands are logged to the console log, and, if any command returns an error, the script aborts immediately. This is very useful for debugging failures, so I always have it in my deployment scripts.

There are comments in the script for all the actions taken, but here is a summary of the sequence of actions that are performed in it:

- First, a number of dependent packages are installed. This includes the C++ compiler and the Python SDK (required to compile native code Python extensions), the `virtualenv` utility, `git`, the `nginx` web server, and the `supervisor` monitoring daemon.
- Then a user named `flasky` is created. This user runs the Python web application. It is always a good idea to run applications under a regular user, as this makes the server more secure. Note that this user does not get a password, so that this user can't login from the outside.
- The `git` command line client is then used to clone the Flasky application, directly from my GitHub repository and into the home directory of the newly created `flasky` user.
- Flasky uses a configuration file stored in a `.env` file. This file is generated next, and note that three of its settings are provided by the variables defined in the `str_replace` function. The `FLASK_CONFIG` variable has a peculiar value (it's set to `"heroku"`). This is because Flasky has set of pre-configured defaults to run on the Heroku service, and those defaults match the OpenStack environment, so I decided to reuse that configuration here. Also of interest is the `DATABASE_URL` variable, which defines the database used by this application to be a SQLite database file on disk. In a future article, when we look at deployments of multiple instances, I will show you how to work with a database server running on a different server.
- The next step creates a virtual environment and then installs the list of required packages in it. The Gunicorn web server is also installed.
- The `manage.py deploy` command, a custom command implemented by this application, creates the database, applies all the migrations to it, and populates it with some initial values.
- Because the script is running as the root user, all the files created by the application are changed to be owned by the `flasky` user.
- The application is going to run on a local instance of the Gunicorn web server listening on `http://127.0.0.1:8000`. Instead of running Gunicorn directly, the script creates a supervisor configuration file, so that the process is automatically monitored and restarted if it dies, or if the instance is rebooted. The supervisor configuration also sets up log files for stdout and stderr of the Gunicorn process, to aid in debugging and troubleshooting.
- Finally, a configuration is added for nginx to act as a front-end web server and reverse proxy to the Gunicorn server. Special handling is added for nginx to serve the static files provided by the application directly, since nginx is much more efficient than Gunicorn for serving files.

Phew! Are you still with me? I hope this does not scare you away from writing deployment scripts. I can assure you that being able to run a single command, and then go grab a cup of coffee while you wait for the application to materialize on its own is a fantastic feeling!

If you launched the above template, and you have the instance running, you can verify that the deployment worked by looking at the console log, as I showed you before. Near the bottom you should see something like "Restarting nginx ... done", which indicates that all the installation steps completed and Flasky is running on your instance.

Unfortunately, this isn't over yet. The instance is fully provisioned and is running the application, but there is no connection to the outside world yet.

## Networking Improvements

The template that deploys Flasky does most of the work already, but the networking setup, which hasn't changed since the first example in the previous article, is very limited. All the template does is connect the instance to the specified private network. Nothing is done to open port 80 to external clients, and more importantly, there is no effort to assign a floating IP address that external clients can be access. But don't despair, the worst part is over, it's a smooth sailing from now on!

### Setting Up A Security Group

Setting up a custom security group on an instance is actually very easy, because Heat includes a resource type dedicated to this task. The changes to the template are shown below:

    resources:
      ...

      web_server_security_group:
        type: OS::Neutron::SecurityGroup
        properties:
          name: web_server_security_group
          rules:
            - protocol: tcp
              port_range_min: 80
              port_range_max: 80
            - protocol: tcp
              port_range_min: 443
              port_range_max: 443
            - protocol: icmp
            - protocol: tcp
              port_range_min: 22
              port_range_max: 22

      flasky_instance:
        type: OS::Nova::Server
        properties:
          ...
          security_groups:
            - { get_resource: web_server_security_group }

As you can see, the `OS::Neutron::SecurityGroup` defines which ports to open, and then the `security_groups` property in the server resource links to it. In this case, I chose to open ports 80 and 443. The nginx web server is not configured to run secure HTTP, but that could be a very useful improvement (that I leave to you as an exercise!). In addition to the web related ports, I added support for pings and SSH.

### Creating a Private Network

The current approach of requesting an existing private network to attach the instance to is not very convenient, because there is no way for Heat to ensure that the given network is properly configured and routed to an external network.

The approach I'm going to show you next is much more flexible. Instead of including a reference to an existing private network in the parameters, the template asks for an external network that can be used as a source of floating IP addresses. With just this information, the template creates its own private network, plus a router that connects it to the outside world. Once again, Heat saves the day by providing resource types for all the needed entities.

The changes are shown below. The `private_network` parameter needs to be replaced with a new one called `public_network`, and then a few new resources are included in the template to create net, subnet and router:

    parameters:
      ...
      public_network:
        type: string
        label: Public network name or ID
        description: Public network with floating IP addresses.
        default: public-net
      ...

    resources:
      ...

      private_network:
        type: OS::Neutron::Net

      private_subnet:
        type: OS::Neutron::Subnet
        properties:
          network_id: { get_resource: private_network }
          cidr: 10.10.10.0/24
          dns_nameservers:
            - 8.8.8.8

      router:
        type: OS::Neutron::Router
        properties:
          external_gateway_info:
            network: { get_param: public_network }

      router-interface:
        type: OS::Neutron::RouterInterface
        properties:
          router_id: { get_resource: router }
          subnet: { get_resource: private_subnet }

The first three resource declarations should be straightforward to understand, as they create new net, subnet and router resources. Since this new network will be routed to the external network, I have added a DNS address for name resolution. For the router, the `public_network` parameter is defined as the gateway. The fourth resource, `router-interface`, is used to associate the private network with the router. This is all it takes to have a properly setup private network.

### Attaching a Floating IP Address

The last important piece needed in this template is to allocate a floating IP address for the server, which requires yet more resources:

    resources:
      ...

      flasky_port:
        type: OS::Neutron::Port
        properties:
          network: { get_resource: private_network }
          security_groups:
            - { get_resource: web_server_security_group }

      flasky_instance:
        type: OS::Nova::Server
        properties:
          ...
          networks:
            - port: { get_resource: flasky_port }

      floating_ip:
        type: OS::Neutron::FloatingIP
        properties:
          floating_network: { get_param: public_network }

      floating_ip_assoc:
        type: OS::Neutron::FloatingIPAssociation
        properties:
          floatingip_id: { get_resource: floating_ip }
          port_id: { get_resource: flasky_port }

    outputs:
      ...
      instance_ip:
        description: The IP address of the deployed instance
        value: { get_attr: [floating_ip, floating_ip_address] }

All the examples I showed you so far associated a private network with a server through a reference to the network in the `networks` property of the server. This method does not provide enough detail to also include a floating IP address, so I changed the template to attach the server to a *port*, a lower level resource that is associated with a private network and the custom security group. Then, a `OS::Neutron::FloatingIP` resource allocates the floating IP address, which is associated with the port through the `OS::Neutron::FloatingIPAssociation` resource.

The `outputs` section, which used to contain the private network IP address associated with the instance, is now much more useful, since it contains the floating IP address used to access the server from the outside. This address can be easily obtained from a property in the `floating_ip` resource.

### Putting It All Together

Ready to try this last template? Go ahead and download the new version of the template, including all the networking changes, from the following link: [heat_2c.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/heat_2c.yaml). Then launch it with the following command:

    (venv) $ heat stack-create flasky -f heat_2c.yaml -P "gmail_username=<your-gmail-user>;gmail_password=<your-gmail-pw>"

Note that you may also need to include the name of your external network, if it doesn't match the default I defined. If you let the template run for a couple of minutes, you should be able to obtain its floating IP address from the outputs. After you type this address into your browser, you should see Flasky's login page!

## Signaling

You now have seen a template that deploys a Python application, complete with network, router and floating IP address. But you probably noticed that Heat is largely unaware of all the deployment operations, as it switches the stack to the `STACK_COMPLETE` state right after the instance is launched, without waiting for the installation script to complete. This is because Heat has no way to know what the script is doing, the best it can do is pass the script to the instance and assume it will finish soon. But this is a problem, because there is no way to tell when the deployment completes, you just have to try to connect to it until it works.

Luckily, there are several ways for an instance to send signals back to the Heat API to inform on the installation progress. To complete today's article, I want to show you the simplest of them, based on a resource called *wait condition*. Take a look at these template additions:

    resources:
      ...

      wait_condition:
        type: OS::Heat::WaitCondition
        properties:
          handle: { get_resource: wait_handle }
          count: 1
          timeout: 600

      wait_handle:
        type: OS::Heat::WaitConditionHandle

      flasky_instance:
        type: OS::Nova::Server
        properties:
          ...
          user_data:
            str_replace:
              params:
                ...
                wc_notify: { get_attr: ['wait_handle', 'curl_cli'] }
              template: |
                #!/bin/bash -ex
                ...
                wc_notify --data-binary '{"status": "SUCCESS"}'

The `OS::Heat::WaitCondition` resource instantiates a special resource that can be signaled from the instance through a *handle*. This resource will change its state only after it receives the number of signals specified in the `count` property. A `timeout` property specifies the time it will wait for those signals. Failure to receive the signals in the allocated time puts the wait condition in a state of failure, making the whole stack fail as well.

There are a few mechanisms to trigger a signal from the instance, but by far the simplest is to send a request with `curl`. To make it even easier, the wait handle resource provides the `curl_cli` attribute, which defines the command to use to send the signal, including the authentication token. I added the `curl_cli` attribute as an additional replacement variable in the script, and I invoke it at the end of the script with a success status, given in JSON format.

Simple, right? The final version of the template can be downloaded from the following link: [heat_2d.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/heat_2d.yaml). With this template, the state of the stack will only change to `STACK_COMPLETE` once the script sends the success signal, and at that point you can be sure that the application is fully deployed.

## Conclusion

This was a pretty long article! I hope you were able to run my examples and can now appreciate how Heat greatly simplifies deployments. Today, I showed you a number of techniques that are useful for single instance applications. But most of what you learned today can also be applied to larger deployments involving multiple instances. But I'm getting ahead of myself now, as multi-instance deployments is the topic of my next article.

I hope you'll join me again for the next part of this tutorial!
