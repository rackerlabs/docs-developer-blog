---
layout: post
title: 'OpenStack Orchestration In Depth, Part III: Multi-Instance Deployments'
date: '2014-11-21 07:15'
comments: true
author: Miguel Grinberg
published: true
categories:
  - Private Cloud
  - Orchestration
bio: "Miguel Grinberg is a software engineer with a background in web technologies and REST APIs. He is the author of the book \"Flask Web Development\" from O'Reilly Media, and has a blog at http://blog.miguelgrinberg.com, where he writes about a variety of topics including web development, robotics, photography and the occasional movie review. Miguel works as a Software Developer with the Rackspace Private Cloud team. He lives in Portland, Oregon with his wife, four kids, two dogs and a cat. Follow @miguelgrinberg on Twitter."
---

This is the third article in my series on OpenStack orchestration with Heat. In [Part 1](/blog/openstack-orchestration-in-depth-part-1-introduction-to-heat), I introduced the HOT template syntax, and then in [Part 2](/blog/openstack-orchestration-in-depth-part-2-single-instance-deployments/), I showed you some of the techniques Heat offers to orchestrate the deployment of applications that run entirely within a single compute instance.

Today, building on the same ideas exposed in my previous article, I'm going to show you how to design deployments across more than one instance, and I'm going to demonstrate these concepts by deploying an application that runs on a server and connects to a MySQL database on another server. You have seen how to deploy a Python application in my previous examples, so, to add some variety, I'm now going to switch to a PHP application as guinea pig. That application is none other than the venerable Wordpress.

<!-- more -->

## Nested Templates

The first approach you may consider, if you need to deploy a multi-instance application with Heat, is to just put several `OS::Nova::Server` resources into your template, along with their wait conditions and anything else they need. This approach can work, but it leads to very large template files that are very hard to debug or update.

To keep my sanity, I prefer to split complex templates into smaller sub-templates, and use *nesting* to combine the parts into the whole. Today, I'm going to show you a method to deploy Wordpress that is partitioned into several small and reusable templates.

So how do you invoke a sub-template in Heat? Simply create a resource that has its type set to the YAML file of the sub-template. If we assume that there is a template called `lib/mysql.yaml` at our disposal that creates a MySQL server, then this is how a master template can invoke it:

    heat_template_version: 2013-05-23

    parameters:
      image:
        type: string
        label: Image name or ID
        description: Image to be used for server. Please use an Ubuntu based image.
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
        description: Network to attach server to.
        default: private

    resources:
      mysql:
        type: lib/mysql.yaml
        properties:
          image: { get_param: image }
          flavor: { get_param: flavor }
          key: { get_param: key }
          private_network: { get_param: private_network }
          database_name: wordpress
          database_user: wordpress_user

The `mysql` resource in this example represents a complete instantiation of the stack defined by the `lib/mysql.yaml` template, so, in the context of the master template, all the resources defined in the sub-template are encapsulated in a single resource.

Resources that reference a nested template also have properties and attributes, like regular resources. The properties of a nested template resource are the parameters defined in the sub-template, while the attributes are its outputs. This is extremely powerful, as nested templates can be thought of as specialized resources that can be written to be opaque and reusable through their inputs and outputs.

I haven't shown you the `lib/mysql.yaml` template yet, because, if you are writing a master template for an application that needs a MySQL database, you can just treat the MySQL template as a black box. You can see in the example above that the properties allow the server to be configured for different types of applications, and you can even specify what database name and user you want.

Extending the black box theme a bit more, let's say I have another template called `lib/wordpress.yaml`, which boots an instance with a LAMP stack and Wordpress in it. Then I could add to my master template a second nested template that starts Wordpress, and links it to the `mysql` resource:

    wordpress:
      type: lib/wordpress.yaml
      properties:
        image: { get_param: image }
        flavor: { get_param: flavor }
        key: { get_param: key }
        private_network: { get_param: private_network }
        mysql_server: { get_attr: [mysql, mysql_instance_ip] }
        database_name: wordpress
        database_user: wordpress_user
        database_password: { get_attr: [mysql, database_password] }


Note that this server needs to obtain some information from the database template, specifically the database password, which is generated as a random string in the MySQL nested template and exported as an output. Since outputs become attributes in the master template, all I need to do is use `get_attr` on the `mysql` resource to get the value of `database_password`.

Thanks to nested templates, this is really all it takes to create a simple two-instance wordpress installation!

### Installing MySQL and Wordpress

Some of you may feel I'm cheating with the nesting of templates, that it can't really be that easy. So now it is time to invite you to open those black boxes that are the nested templates I referenced in the previous section, and take a peek inside.

You may be surprised, but these templates have absolutely no magic in them. They use the same techniques I showed you in my [previous article](/blog/openstack-orchestration-in-depth-part-2-single-instance-deployments/) to provision a single instance with some software, and in both cases there is a bash script that runs the proper installation and configuration commands in the respective instances. The instances are then attached to a private network that is given as a parameter.

The MySQL template defines four outputs, which a master template may need. They are the instance name, IP address, network port and the database password for the database that was created. The Wordpress template takes as input the database credentials, and exports just three outputs for the name, IP address and network port of the server.

If you want to see these templates, please go ahead and take a look at them in my GitHub repository. Here are [lib/mysql.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/lib/mysql.yaml) and [lib/wordpress.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/lib/wordpress.yaml).

## Launching Nested-Template Stacks

If you still aren't convinced, then go ahead and try this three-template solution. In the GitHub repository you can the master template, which I called [heat_3a.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/heat_3a.yaml). Download this to a directory in your computer, and then put the two sub-templates referenced in the previous section in a `lib` sub-directory.

You can launch the entire collection of templates with the `heat` command line client:

    (venv) $ heat stack-create wordpress -f heat_3a.yaml

So as you see, there's nothing new here. You just launch the master template, and the nested templates make it into Heat automatically. And as always, if you need to customize any of the parameters in the master template such as the name of the private network, then you can use the `-P` option, as I demonstrated in previous examples.

Unfortunately, a collection of templates sitting in your local disk cannot be launched as easily from Horizon, since the web-based interface to Heat does not currently support uploading more than one template at a time.

## Adding a Dedicated Private Network

The solution I presented above works very well, but it relies on the system having a private network that is property routed to an external network. In the previous article, I showed you a more reliable way to structure Heat templates, which involved the creation of a brand new private network dedicated to the stack and explicitly routed to the external network. I also showed you how to assign floating IP addresses directly from the template, so that you don't have to do it manually.

The solution I showed for a single instance needs to be adapted slightly to work with nested templates, but the nice thing is that these networking changes do not affect the sub-templates in any way. Those sub-templates are already done and tested, so now we can build the networking side of the stack independently.

I hope you like this idea of building little reusable templates that behave as black boxes, because I'm about to take that concept a couple of notches higher. Here is another reusable template that builds a private network, using the techniques I showed in the previous article:

    heat_template_version: 2013-05-23

    description: Template that creates a private network.

    parameters:
      public_network:
        type: string
        label: Public network name or ID
        description: Public network with floating IP addresses.
        default: public
      cidr:
        type: string
        label: Network CIDR
        description: The CIDR of the private network.
        default: '10.10.10.0/24'
      dns:
        type: comma_delimited_list
        label: DNS nameservers
        description: Comma separated list of DNS nameservers for the private network.
        default: '8.8.8.8'

    resources:
      private_network:
        type: OS::Neutron::Net

      private_subnet:
        type: OS::Neutron::Subnet
        properties:
          network_id: { get_resource: private_network }
          cidr: { get_param: cidr }
          dns_nameservers: { get_param: dns }

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

    outputs:
      name:
        description: The private network.
        value: { get_attr: [private_network, name] }

Isn't this fantastic? Now I don't have to remember all the resources that are involved in standing up a private network. All I need to do is nest [lib/private_network.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/lib/private_network.yaml), and, in my master template, the private network appears as a single, self-contained resource, which I can configure with properties. Also, I can query it for its attributes.

Here are the changes I need to make to my Wordpress master template to incorporate a private network:

    parameters:
      # ...
      public_network:
        type: string
        label: Public network name or ID
        description: Network to attach server to.
        default: public

    resources:
      network:
        type: lib/private_network.yaml
        properties:
        public_network: { get_param: public_network }

      mysql:
        type: lib/mysql.yaml
        properties:
          private_network: { get_attr: [network, name] }
          # ...

      wordpress:
        type: lib/wordpress.yaml
        properties:
          private_network: { get_attr: [network, name] }
          # ...

Here I replaced the `private_network` parameter with another one called `public_network`, which I then feed as a property to the new `network` resource that imports the new sub-template. Then the network name is obtained as an attribute and given to the MySQL and Wordpress nested templates.

If you want to try this version of the template you have to download both  [lib/private_network.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/lib/private_network.yaml) and the new version of the master template [heat_3b.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/heat_3b.yaml).

## Assigning a Floating IP Address

The final improvement is to automatically assign a floating IP address to the Wordpress instance, and, for that, I'm sure you can guess that I'm going to write yet another reusable template:

    heat_template_version: 2013-05-23

    description: Template that assigns a floating IP address to a server.

    parameters:
      port:
        type: string
        label: Server port
        description: The server port that receives the floating IP address.

      public_network:
        type: string
        label: Public network name or ID
        description: Public network with floating IP addresses.
        default: public

    resources:
      floating_ip:
        type: OS::Neutron::FloatingIP
        properties:
          floating_network: { get_param: public_network }

      floating_ip_assoc:
        type: OS::Neutron::FloatingIPAssociation
        properties:
          floatingip_id: { get_resource: floating_ip }
          port_id: { get_param: port }

    outputs:
      ip:
        description: The floating IP address assigned to the server.
        value: { get_attr: [floating_ip, floating_ip_address] }

To invoke this template I just need to create a new nested template resource in my master template:

    resources:
      # ...

      floating_ip:
        type: lib/floating_ip.yaml
        properties:
          port: { get_attr: [wordpress, port] }
          public_network: { get_param: public_network }

    outputs:
      ip:
        description: The public IP address to access Wordpress.
        value: { get_attr: [floating_ip, ip] }

To try this, download [lib/floating_ip.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/lib/floating_ip.yaml) and the final version of today's master template: [heat_3c.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/heat_3c.yaml).

After you launch this template, you can just let it run for a couple of minutes, and then pick up the public IP address from the outputs. When you connect to this address with your web browser, you will be in the Wordpress setup page, and you will be on your way to starting a blog!

## Using Heat Environments

The heat command line client is pretty smart, it finds all the nested template references in the master template and then uploads all the needed files to Heat as a package. But as I mentioned above, Horizon does not have the ability to do that at this time, so the templates I showed you above, or actually any templates that reference other templates, cannot be launched from the web dashboard.

Heat provides an alternative way to nest templates called *environments*, which Horizon supports. An environment file is a YAML file that has global definitions that are imported before a template is parsed. What's interesting is that an environment file can be used to assign custom resource types to nested templates. Consider the following environment file:

    resource_registry:
      Lib::MSG::MySQL: https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/lib/mysql.yaml
      Lib::MSG::Wordpress: https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/lib/wordpress.yaml
      Lib::MSG::PrivateNetwork: https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/lib/private_network.yaml
      Lib::MSG::FloatingIP: https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/lib/floating_ip.yaml

The `resource_registry` section contains a mapping of custom resource types to the URLs of the nested templates that implement them. I have included the four templates I used to deploy Wordpress, and named them with a `Lib` prefix, to indicate that they come from a library of templates. I followed that with my initials, `MSG`, as way of a namespace. Finally, I gave a name to the template in the third part of the type.

After Heat imports this environment file, it can recognize the custom types, so for example, the MySQL server can be defined as follows:

    mysql:
      type: Lib::MSG::MySQL
      properties:
        # ...

If you want to try this, download [heat_3d.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/heat_3d.yaml) and [lib/env.yaml](https://raw.githubusercontent.com/miguelgrinberg/heat-tutorial/master/lib/env.yaml), and load both in Horizon's launch stack dialog.

If you are using the command line client, then an environment file can be given as follows:

    (venv) $ heat stack-create wordpress -f heat_3d.yaml -e lib/env.yaml

## Conclusion

I hope you are starting to realize the amazing power Heat templates give you over the regular OpenStack APIs. To prove this point today, I have shared with you a few reusable templates, and it goes without saying that you are more than welcome to take them, use them, adapt them or do whatever you want with them. If you make something cool with them, be sure to let me know!
