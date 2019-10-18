---
layout: post
title: Libcloud 0.14 Released
date: '2014-02-03 14:51'
comments: true
author: Brian Curtin
published: true
categories:
  - python
  - openstack
---

On 22 January, [Apache Libcloud](https://libcloud.apache.org/index.html) project chair Tomaz Muraus announced the release of Libcloud 0.14, a Python package which abstracts away the many differences among cloud provider APIs, allowing developers to target one interface regardless of the vendor.

<!-- more -->

{% img 2014-02-03-libcloud-0-dot-14-released/libcloud.png 225 %}

# History

The Libcloud project began in 2009 at Cloudkick, who were later acquired by Rackspace, leading to the [Cloud Monitoring](https://www.rackspace.com/cloud/monitoring/) product. After joining the Apache Incubator in late 2009, Libcloud graduated to a top-level Apache project in May 2011.

The May 2011 release of Libcloud 0.5 saw the additions of object storage and load balancer abstractions, to compliment the original compute-only releases. Libcloud 0.6 brought DNS abstractions to the package just a few months later. Documentation saw a visual and content overhaul in July 2013, with the move to [ReadTheDocs.org](https://libcloud.readthedocs.org/en/latest/).

Python 3 has been supported since the 0.7.1 release in December 2011, and [PyPy](https://pypy.org/) became supported in 0.9.

If you've been following the project, you might notice the website has undergone a makeover. The refresh makes use of Jekyll and Bootstrap, and offers a more modern view of the project, including its own blog, which includes [a post](https://libcloud.apache.org/blog/2014/01/23/welcome-to-the-new-website.html) on how the new site came to be.

# Getting Started

In order to use Libcloud, you'll need appropriate credentials for the provider you're using -- check the [supported providers](https://libcloud.readthedocs.org/en/latest/supported_providers.html) matrix to see if yours is listed.

For Rackspace, the user name you need is the same one you use to login to [your control panel](https://mycloud.rackspace.com). Once you're logged in, you'll find your API key inside of the Account Settings page. Click on your user name in the top right access it.

![Menu]({% asset_path 2014-02-03-libcloud-0-dot-14-released/menu.png %})

From the Account Settings page, your API key will be obscured, so click *Show* to expose it. You'll want to be careful when using your user name and API key. For one, don't enter them directly into code you're checking into source control, especially if that repository is public.

![Settings]({% asset_path 2014-02-03-libcloud-0-dot-14-released/settings.png %})

# Installing Libcloud

Libcloud is available on PyPI as [apache-libcloud](https://pypi.python.org/pypi/apache-libcloud), and is installable via `pip`.

    pip install apache-libcloud

Downloads are also available on the [Libcloud site](https://libcloud.apache.org/downloads.html).

# Adding an SSH Key

Before you dig in and spin up servers on your provider, you'll want a secure way of accessing them. Most providers offer an API to setup SSH key pairing, including OpenStack and the Rackspace Cloud. As of the 0.14 release, key management is a part of the base *compute* APIs, instead of its previous life as a set of extension APIs.

If you don't already have an SSH key, there are many guides available around the web - [here's one](https://www.debian-administration.org/articles/530). Libcloud can even [create one for you](https://libcloud.readthedocs.org/en/latest/compute/key_pair_management.html#creating-a-new-key-pair). Here's how you import an existing key:

    from libcloud.compute.types import Provider
    from libcloud.compute.providers import get_driver

    # Create the Rackspace driver and connect to it.
    Driver = get_driver(Provider.RACKSPACE)
    rs = Driver("libclouduser", "AbCdEfGhIjKlMnOpQrStUvWxYz", region="ord")

    # Import your existing key pair by giving its path.
    # Give it a name - you'll need it when you create the Node!
    key_pair = rs.import_key_pair_from_file(
                key_file_path="/home/libclouduser/mykey.pub",
                name="my_key")

# Create Some Servers

Now that you'll have a secure way of talking to your servers, let's create some. But first, you'll need to know some terminology. Whether you use Rackspace or any of the other supported providers, the specifics are abstracted away into the following base classes:

- `Node`: a compute resource, server, virtual machine, etc.
- `NodeSize`: the hardware configuration your `Node` will run on.
- `NodeImage`: the disk image your `Node` will run on.

As with the key pairing example, we need to start off with some imports and connect to our driver. This code will be necessary for each example in the following section.

The following creates a Rackspace compute driver in the ORD datacenter. This method of communicating with a specific region is new for 0.14, whereas in the past each region was represented by its own class. Several other providers had the drivers updated in this same fashion.

    from libcloud.compute.types import Provider
    from libcloud.compute.providers import get_driver

    # Create the Rackspace driver and connect to it.
    Driver = get_driver(Provider.RACKSPACE)
    rs = Driver("libclouduser", "AbCdEfGhIjKlMnOpQrStUvWxYz", region="ord")

## Pick a Size and Image

Before you can create your `Node`, you need to pick a `NodeSize` and `NodeImage`. Libcloud has taken care of the differences between the supported providers, allowing you to find out each provider's offerings with a simple interface.

    # Return lists of `NodeSize` and `NodeImage` objects.
    sizes = rs.list_sizes()
    images = rs.list_images()

Since the Rackspace Cloud is built on OpenStack, the Rackspace compute provider APIs inherit from the OpenStack compute APIs. When you look at the items of the `sizes` list, you'll see that they're `OpenStackNodeSize` objects.

    [<OpenStackNodeSize: id=performance1-1, name=1 GB Performance, ram=1024, disk=20, bandwidth=None, price=0.04, driver=Rackspace Cloud (Next Gen), vcpus=1,  ...>,
     <OpenStackNodeSize: id=performance1-2, name=2 GB Performance, ram=2048, disk=40, bandwidth=None, price=0.08, driver=Rackspace Cloud (Next Gen), vcpus=2,  ...>, ...]

Each `NodeSize` object has attributes such as `ram` and `disk` which represent those particular sizes, and `id` and `name` which represent a formal identifier and a friendly name, respectively. From that list, pick the size that fits your need.

When you look at each `NodeImage`, the `name` attribute corresponds to the friendly name you'll find in the control panel. When your chosen image is sent to the API, it's the `id` which is sent.

    [<NodeImage: id=087497de-d71c-4d78-a707-599d0a8ea8b5, name=Windows Server 2012 + SQL Server 2012 SP1 Standard, driver=Rackspace Cloud (Next Gen)  ...>, ...
     <NodeImage: id=857d7d36-34f3-409f-8435-693e8797be8b, name=Debian 7 (Wheezy), driver=Rackspace Cloud (Next Gen)  ...>, ...]

## Build it!

With our key pair configured, and our size and image picked out, we're ready to create a new Rackspace Cloud Sever!

    # Create a a 2GB Performance Server that runs Debian Wheezy.
    # Give it our 'my_key' key pair from earlier.
    node = rs.create_node(name="server1", size=perf2, image=wheezy,
                          ex_keyname="my_key")

A couple of minutes later, `rs.list_nodes()` will show our "server1" `Node`, complete with a public IP that we can now SSH to. Another option is to pass `node` into [`rs.wait_until_running()`](https://libcloud.readthedocs.org/en/latest/compute/api.html#libcloud.compute.base.NodeDriver.wait_until_running), which will block until your new compute resource is considered available!

Whenever you find that it's ready, go ahead, SSH in and play around, or point your favorite orchestration tool at it. Libcloud also has options for bootstrapping your freshly created nodes to get you started: see [`libcloud.compute.deployment`](https://libcloud.readthedocs.org/en/latest/compute/deployment.html).

# Create a Load Balancer

Rackspace is among the supported providers for Libcloud's Load Balancer abstraction, along with [several others](https://libcloud.readthedocs.org/en/latest/loadbalancer/supported_providers.html). Rackspace Load Balancers used to be separated into US and UK specific drivers, but Libcloud 0.14 unifies them, since the Load Balancer product is a global service.

Load Balancers are super easy to get setup. The main piece is a list of `Member`s, which we'll build from the `Node`s we created above. We also need to pick the `Algorithm` by which the load balancer directs traffic.

For brevity, the following example assumes `nodes` is a list of compute nodes like you would have gotten from the [`list_nodes()`](https://libcloud.readthedocs.org/en/latest/compute/api.html#libcloud.compute.base.NodeDriver.list_nodes) call in the [Build it!]() section.

    from libcloud.loadbalancer.base import Member, Algorithm
    from libcloud.loadbalancer.types import Provider
    from libcloud.loadbalancer.providers import get_driver

    Driver = get_driver(Provider.RACKSPACE)
    balancers = Driver("libclouduser", "AbCdEfGhIjKlMnOpQrStUvWxYz")

    # Create a list of Members from our list of Nodes.
    members = [Member(n.name, n.public_ips[0], 8080) for n in nodes]

    lb = balancers.create_balancer(name="my_lb", algoritm=Algorithm.ROUND_ROBIN,
                                   port=80, protocol="http", members=members)

What we've done is taken the compute nodes we created and set them up behind our load balancer. You can create load balancers for any protocol your provider supports, and this example shows the balancing of web servers on port 80.

# Configure DNS Records

Now that we have a couple of nodes behind a load balancer, let's point a DNS **A** record at it. As with `libcloud.loadbalancer`, `libcloud.dns` has moved to a single region-less provider for Rackspace instead of the previous US and UK split classes.

The `libcloud.dns` API, and typically your provider's DNS APIs, are for working with domains which you've already purchased and have pointed at the provider's name servers. Assuming we have control of a domain name, it's easy to work with from Libcloud.

To get started, you'll need to create a `Zone` for your domain. All other DNS operations within `libcloud.dns` operate on this zone.

    from libcloud.dns.providers import get_driver
    from libcloud.dns.types import Provider
    from libcloud.dns.types import RecordType

    Driver = get_driver(Provider.RACKSPACE)
    dns = Driver("libclouduser", "AbCdEfGhIjKlMnOpQrStUvWxYz")

    # Create a Zone for a domain, and configure your email address.
    zone = dns.create_zone(domain="example.com",
                           extra={"email": "libcloud@example.com"})

Now that we have our `zone`, setting records is simple. In the [Create a Load Balancer]() section, our example left off with `lb` as the created Load Balancer object. That `lb` object has an `ip` attribute which we'll point our **A** record at.

    # Set an A record to point 'example.com' to our Load Balancer.
    record = zone.create_record(name="", RecordType.A, data=lb.ip)

Another new feature in the Rackspace `libcloud.dns` driver is the addition of iterator methods for paginated zone and record requests: [`iterate_zones`](https://libcloud.readthedocs.org/en/latest/dns/api.html#libcloud.dns.base.DNSDriver.iterate_zones) and [`iterate_records`](https://libcloud.readthedocs.org/en/latest/dns/api.html#libcloud.dns.base.DNSDriver.iterate_records). These methods now allow users to access the full set of their DNS data.

# Store and Retrieve Objects

Libcloud users can access Rackspace Cloud Files and other providers' object storage APIs through the `libcloud.storage` abstraction. Like the `libcloud.compute` API, the storage API for Rackspace has moved from separate US and UK driver classes to being configured with a region argument.

    from libcloud.storage.types import Provider
    from libcloud.storage.providers import get_driver

    # Connect to Rackspace Cloud Files in the IAD datacenter.
    Driver = get_driver(Provider.CLOUDFILES)
    storage = Driver("libclouduser", "AbCdEfGhIjKlMnOpQrStUvWxYz", region="iad")

[`libcloud.storage`](https://libcloud.readthedocs.org/en/latest/storage/api.html) operates on two things: objects, and the containers that hold them. Regardless of your provider, it's easy to create a container and upload a piece of data to it.

    # Object upload operates on iterators, like BytesIO
    from io import BytesIO

    # Create a new container within Rackspace Cloud Files.
    container = storage.create_container("my_container")

    # Upload some data to our new container.
    obj = container.upload_object_via_stream(BytesIO("some_data"),
                                             object_name="my_uploaded_data")

The returned `obj` gives you several useful attributes, such as the `size` and `hash` of the uploaded data. If you're uploading files that are represented on disk, you can use `storage.upload_object` which takes a file name.

Retrieving data is just as easy as creating it. If we wanted to get the information we just put in, we'd do the following.

    # Return our specific container.
    # If we didn't already know the name, we could `list_containers()`.
    container = storage.get_container("my_container")

From here, we have a number of options with `container`. One common step is to enable our container to be served over the the Akamai CDN.

    container.enable_cdn() # Returns True if successful.

We can also retrieve the object that we uploaded into the container. We already know the name, but we could do `container.iterate_objects()` if we didn't.

    obj = container.get_object("my_uploaded_data")

With `obj`, there are a couple of things we can do. Let's say you uploaded some image for your website. `obj.get_cdn_url()` will give you a URL to your object on the Akamai CDN. Since we actually uploaded some text, we can stream the object and get it back.

    # as_stream returns a generator of our data.
    stream = obj.as_stream()
    data = next(stream) # `data` is now "some_data", as we uploaded.

---

Libcloud development is active on [GitHub](https://github.com/apache/libcloud), and gladly accepts pull requests from the community. If you have issues to report, [https://issues.apache.org/jira/browse/LIBCLOUD]() is the bug tracker. Also feel free to drop by #libcloud on irc.freenode.net!
