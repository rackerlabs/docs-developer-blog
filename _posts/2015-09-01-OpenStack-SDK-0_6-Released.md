---
layout: post
title: OpenStack SDK 0.6 Released
date: 2015-09-01 12:00
comments: true
author: Brian Curtin
published: true
categories:
    - OpenStack
    - SDKs

---

The developers behind the OpenStack SDK are proud to announce the 0.6 release of the project, aimed at creating a better experience for application developers who use OpenStack clouds via the Python language. If you're a Rackspace customer, this means *you*. With OpenStack SDK 0.6 also comes the 0.3 release of the Rackspace plugin for the SDK.

<!-- more -->

### Getting Started, Quickly

If you just want to dive in, the following will get you going. Check out the [docs](http://python-openstacksdk.readthedocs.org/en/latest/) for the full set of supported services and their APIs, otherwise read on below for more info. If you're not using Rackspace, see the SDK's [usage](http://python-openstacksdk.readthedocs.org/en/latest/users/guides/usage.html) guide for more information how to connect `openstacksdk` to your cloud.

1. `pip install rackspacesdk` (this package depends on `openstacksdk`)

2. Run `python` (we test with 2.7 and 3.4)

3. Create a Connection and work with some services!

```
Python 3.4.1+ (3.4:d23cea976f46, Jun  7 2014, 13:06:42) 
>>> from rackspace import connection
>>> conn = connection.Connection(username="brian", api_key="123", region="IAD")
>>> for server in conn.compute.servers():
...     print(server.name, server.flavor.id, server.image.id)
... 
myserver-iad1 performance1-1 cfa476b1-9e14-46ba-99c8-862d1b94ef7a
```

### What is this?

The OpenStack SDK is a project that aims to improve the experience that Python users have when interacting with OpenStack clouds via their REST APIs. It's a fresh look at providing a single package with a set of consistent interfaces to the many services OpenStack provides, and its focus is on users.

For Rackspace, this project is the Python SDK that we're putting all of our effort behind. We will have an announcement on Pyrax coming soon.

### What does it do?

It allows you to import one package, connect to a cloud, and work with each of its services in the same way.

The 0.6 release of the SDK brings some amount of support for thirteen of OpenStack's services. Some of these are complete, some are just scratching the surface, but we'll be completing them all over the upcoming releases. After we've put the project into state where we trust it in the hands of production users -- which at this point means a few key bugs are fixed, documentation is bulked up, and functional testing is completed -- we'll open up the process of adding new services. The following will be the services we're releasing between now and 1.0:

* Block Store (Cinder)
* Cluster (Senlin)
* Compute (Nova)
* Database (Trove)
* Identity (Keystone)
* Image (Glance)
* Key Management (Barbican)
* Message (Zaqar)
* Metric (Gnocchi)
* Network (Neutron)
* Object Store (Swift)
* Orchestration (Heat)
* Telemetry (Ceilometer)

#### How does it do it?

The REST API for each of the above services exposes a number of resources, and each of those resources has a corresponding class within that service's namespace. For example, the Compute service's `/servers` resource resides in `openstack.compute.v2.server`. Each of those resource classes support the HTTP requests that the REST API accepts, and is able to convert HTTP responses into easy to work with instances of the resource class.

One of the goals of the SDK is to smooth over the differences between the many services through these resource classes, so if you're able to work with one service in OpenStack SDK, you can work with them all.

### What's new in 0.6?

The project began as a series of discussions starting in November 2013, and the code started to take shape towards what we know it as now in the middle of 2014. Throughout that time we've built out services and bulked up the lower layers of the project that have gotten us to where we are now. While there were plenty of bugs fixed since 0.5, the biggest piece of the 0.6 release is support for plugins.

#### Plugins

The OpenStack SDK is a StackForge project within the OpenStack ecosystem, and as such, its focus is on providing libraries for OpenStack services. The Rackspace Public Cloud offers ten OpenStack services and additionally offers several non-OpenStack products, e.g., Cloud Monitoring. Even in the case of Rackspace's OpenStack services, we have some extensions on top of the base OpenStack service, such as the bulk delete functionality in Cloud Files, our deployment of OpenStack Swift. Through this new plugin feature, Rackspace is able to leverage OpenStack SDK's support of the services we've deployed and also extend the SDK to cover the entire suite of services we offer. One library, one set of APIs, consistency all around. That's what we wanted when we started the project, and that's what we've got.

Plugins are supported via setuptools' entry points, allowing an plugin to offer both brand new services and override base services offered by OpenStack SDK itself. Additionally, authentication plugins are also specified in the same manner. In the case of version 0.3 of `rackspacesdk`, we provide both an authentication plugin as well as support for two services in one convenient package.

##### Authentication

While you can authenticate to the Rackspace Public Cloud in OpenStack SDK if you know all of the arguments, such as the appropriate `auth_url`, our auth plugin takes care of everything, leaving you to provide only your credentials. It'll take `username` + `password` values as well as `username` + `api_key`. Authentication via API key is something we've extended in our Keystone-compatible authentication system, and it's the method we prefer for our users, so it's something we have to provide on top of the SDK in this plugin.

If you use the `rackspace.connection` module provided by the plugin, you don't need to directly worry about any of this, as our `Connection` subclass takes care of setting up the auth plugin and loading the service extensions. The following example will send the arguments through to our plugin:

```
>>> from rackspace import connection
>>> conn = connection.Connection(username="me", api_key="123", region="IAD")
```

##### Services

The aforementioned bulk delete functionality in Cloud Files is a feature we've exposed via our plugin. The `object_store` package that gets loaded when you've created a connection with the Rackspace extension enabled is from the `rackspace.object_store` package, which includes a Proxy class that inherits from `openstack.object_store` in order to extend it. It gives you everything OpenStack Swift offers, plus our `bulk_delete` method.

```
conn.object_store.bulk_delete("container_filled_with_stuff")
```

Also included in the plugin is support for Cloud Queues -- our deployment of the OpenStack message service, Zaqar -- as the Rackspace deployment uses a different internal name for it than OpenStack does. The `conn.message` namespace can talk to Cloud Queues, such as `conn.message.create_queue(name="my_queue")`.

### How to use it?

The first step to using the OpenStack SDK is creating a connection with your credentials. After that, it's a matter of calling methods to create, update, get, list, and find resources in any of your OpenStack cloud's services.

These examples assume a `conn` object from one of the `Connection` snippets from above, created with your credentials.

#### Create a Server

All it takes to create a server is an image, a flavor, and a name. The compute service, aka OpenStack Nova or Rackspace Cloud Servers, resides in the `compute` namespace on your `conn` object.

You can find all of the images and flavors by calling `conn.compute.images()` and `.flavors()` respectively, each returning a generator of all available items. However, if you already know the names of what you want to use, you can find them like so:

```
>>> image = conn.compute.find_image("Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)")
>>> flavor = conn.compute.find_flavor("performance1-1")
>>> server = conn.compute.create_server(name="my server", image=image, flavor=flavor)
```

The `server` object you get back isn't immediately created. You get back some information that is immediately available, such as the ID and information about the image and flavor, but it may take some time for the server to be available. If you want to wait for it to be up and running, try the `wait_for_server` method:

```
>>> server = conn.compute.wait_for_server(server)
```

Now the server is ready to be accessed, such as by SSH. You can find its public IPs by inspecting the `server` object.

```
>>> print(server.addresses["public"])
[{'addr': '104.130.4.108', 'version': 4}, {'addr': '2001:4802:7802:104:be76:4eff:fe20:b33', 'version': 6}]
```

#### Upload a directory to object storage

Given an OpenStack connection, a directory, and a file pattern, you can upload all files matching the pattern from that directory into a container named after the directory containing the files.

The object store service, aka OpenStack Swift or Rackspace Cloud Files, resides in the `object_store` namespace on your `conn` object.

```
import glob, os, sys
def upload_directory(conn, directory, pattern):
    container_name = os.path.basename(os.path.realpath(directory))
    container = conn.object_store.create_container(name=container_name)
    for root, dirs, files in os.walk(directory):
        for file_name in glob.iglob(os.path.join(root, pattern)):
            with open(file_name, "rb") as f:
                ob = conn.object_store.create_object(data=f.read(),
                                                     name=os.path.split(file_name)[1],
                                                     container=container)
                print("Uploaded {0.name}".format(ob))
```

Now just call it with a directory containing some files you want to upload.

```
upload_directory(conn, "/Users/brian/dogs", "*.gif")
```

Cool, now they're uploaded. You can retrieve the objects in a container via the `objects()` method. All resources within OpenStack SDK that correspond to retrieving multiple resources are named as the plural of the particular resource. You'll see `servers`, `networks`, `databases`, and more throughout the SDK, and they all return a generator that handles pagination for you.
 
```
>>> for ob in conn.object_store.objects("dogs"):
...     print(ob.name)
dog1.gif
dog2.gif
... <pagination handled for you because there are so many dog gifs in this container>
dog1000000.gif
```

### What's next?

We're currently working on bulking up our documentation and functional testing as well as fixing any bugs we find. While we think we've discovered a great set of conventions to build our APIs around, we're not totally locked into everything yet. In fact, an upcoming release is going to bring some extra consistency to methods that upload and download data, with `upload_` and `download_` being prefixes we'll work with. That'll mean the above example with `create_object` is going to become `upload_object`, among other similar methods around the library.

Other than that, we're aiming to make a great experience for people building applications for OpenStack, so we'd love it if you check out the SDK and let us know what you think!

* PyPI: [pypi.python.org/pypi/openstacksdk](https://pypi.python.org/pypi/openstacksdk)
* Documentation: [python-openstacksdk.readthedocs.org/en/latest/](http://python-openstacksdk.readthedocs.org/en/latest/)
* Bug Tracker: [bugs.launchpad.net/python-openstacksdk](https://bugs.launchpad.net/python-openstacksdk)
* Source code: [git.openstack.org/cgit/stackforge/python-openstacksdk/](http://git.openstack.org/cgit/stackforge/python-openstacksdk/) (Github mirror: [github.com/stackforge/python-openstacksdk](https://github.com/stackforge/python-openstacksdk)
* IRC: #openstack-sdks on Freenode
* Email: openstack-dev@openstack.org (prefix your subject with `[python-openstacksdk]`)