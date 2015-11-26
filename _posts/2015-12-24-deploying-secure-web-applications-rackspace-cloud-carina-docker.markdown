---
layout: post
title: "Deploying Secure Web Applications on the Rackspace Cloud with Carina and Docker"
date: 2015-12-24 8:00
comments: true
author: Lars Butler
published: true
categories:
    - DevOps
    - Deployment
    - Security
    - Carina
    - Docker
---

# Deploying Secure Web Applications on the Rackspace Cloud with Carina and Docker

Contents:

- [Introduction](#introduction)
- [What You'll Need](#what-youll-need)
- [Environment Setup](#environment-setup)
- [Creating an SSL Certificate](#creating-an-ssl-certficiate)
- [Let's Do This](#lets-do-this)
- [One Container](#one-container)
- [Two Containers](#two-container)
- [Add a Cloud Load Balancer](#add-a-cloud-load-balancer)
- [Network, SSL, and DNS Configuration](#network-ssl-and-dns-configuration)
- [Conclusion](#conclusion)

## Introduction<a href="introduction"></a>

It's almost 2016, so I shouldn't need to convince you that making your web
application as secure as possible is an absolute necessity. Security is a
multi-faceted topic, but probably the biggest application security concerns
revolve around deployment and configuration of infrastructure. Internally,
that means that secrets, such as passwords and private keys, are stored and
handled in a secure way, and that network access to resources, such as virtual
servers, is limited only to what is absolutely necessary. Externally, any
communication between your app and a client needs to take place over a secure
channel, and that usually means that you'll need to set up SSL (Secure Sockets
Layer) on your web service in order to communicate over secure HTTP (HTTPS). In
terms of getting your application securely into production, there's a lot to
think about. But if you're a software developer like me, you probably want
spend to _more_ time thinking about building the next feature for your app and
_less_ time thinking about how to deploy it.

In this post, I'll show you what I found to be the path of least resistance in
getting a secure web application up and running on the Rackspace Cloud. I'll
first take you quickly through the process of creating an SSL certificate, and then
I'll show you how to deploy things using
[Carina](https://getcarina.com/)--Rackspace's new beta container
service--and [Docker](https://docker.com). No matter whether you've deployed
HTTPS applications dozens of times, or if you've never even done it once, this
guide should have something useful for you.

<!-- more -->

## What You'll Need<a href="what-youll-need"></a>

To follow me on this exercise, you'll first need a couple of things:

- A Carina account. You can sign up for free at
  [getcarina.com](https://getcarina.com).
- A Rackspace Cloud Account. If you don't have one yet, check out our
  [Developer Plus program](https://developer.rackspace.com/signup/); it's free
  for limited use.
- A computer with Linux or OSX and a knowledge of basic shell commands. If you
  don't have ready access to such a machine, there is a simple solution:
  Install [VirtualBox](https://www.virtualbox.org/) and use
  [Vagrant](https://www.vagrantup.com/) to spin up a local Linux virtual
  machine. See
  [Vagrant's Getting Started guide](https://docs.vagrantup.com/v2/getting-started/index.html)
  for more info.
- A registered domain name. I'm going to be showing you the basics of how you
  can create and deploy an SSL certificate, and you'll need a valid registered
  domain name in order to do this.

You will need a valid SSL certificate. If you have one already, great! You can
skip ahead to [Environment Setup](#environment-setup). If not, read on and I'll
take you through the process of creating one.

## Creating an SSL Certificate<a href="creating-an-ssl-certificate"></a>

First things first, you'll need to install [OpenSSL](https://www.openssl.org/)
on your Linux or OSX machine. Most system package managers should have an
`openssl` package available to install. For example:

- On RedHat-based Linux distros (such as RHEL or Centos), run
  `sudo yum install openssl`.
- On Debian/Ubuntu-based Linux distros, run `sudo apt-get install openssl`.
- On OSX you can use [Homebrew](http://brew.sh/) to `brew install openssl`.

Once you've got `openssl` installed, it's time to generate your Certificate
Signing Request (CSR) and a private key for your SSL certificate. Open a shell
session and run the following command:

    openssl req -newkey rsa:2048 -nodes -keyout mydomain.com.key -out mydomain.com.csr

There's a lot going in this command, so let's break it down:

- `req`: This is a sub-command of `openssl` concerned with the management of CSRs.
- `-newkey rsa:2048`: Create a new RSA key with a length of 2048 bits.
- `-nodes`: Stands for "no DES," which instructs `openssl` to not encrypt the
  private key file. This enables us to use the private key without having to
  enter a passphrase. (Source:
  [Stackoverflow discussion](http://stackoverflow.com/questions/5051655/what-is-the-purpose-of-the-nodes-argument-in-openssl).)
- `-keyout mydomain.com.key`: Filename where the private key will be saved. In
  this case, replace `mydomain.com` with your root domain name.
- `-out mydomain.com.csr`: Filename where the CSR will be save. Again, replace
  `mydomain.com` with your actual domain name.

The command will prompt you to enter a bunch of info to populate your CSR. It
should look like this:

    $ openssl req -newkey rsa:2048 -nodes -keyout mydomain.com.key -out mydomain.com.csr
    Generating a 2048 bit RSA private key
    ......+++
    .........................................+++
    writing new private key to mydomain.com.key'
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [AU]:US
    State or Province Name (full name) [Some-State]:New York
    Locality Name (eg, city) []:New York
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:
    Organizational Unit Name (eg, section) []:
    Common Name (e.g. server FQDN or YOUR name) []:secure.mydomain.com
    Email Address []:your.email@example.com

    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:
    An optional company name []:

Most of these inputs are optional, which is nice if you're creating an SSL
certificate for a personal website and you don't actually have a company name.
The important fields are:

- Country Name (2 letter code): If you don't know your country's 2 letter code,
  you can look it up [here](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
- State or Province Name (full name)
- Locality Name (eg, city)
- Common Name (e.g. server FQDN or YOUR name): Typically what you'll want to
  enter here is the Fully Qualified Domain Name (FQDN) where you will be
  deploying your app. In this example, the FQDN we've specified is
  `secure.mydomain.com`, with `secure` as the subdomain--but you can choose any
  subdomain you like, such as `www`, or whatever. It's also possible to
  generate a
  [wildcard certificate](https://en.wikipedia.org/wiki/Wildcard_certificate),
  such as `*.mydomain.com`, but this is a bit more complicated (and the
  certificate will cost more).
- Email Address

Once you fill out the required info, `openssl` will generate two files:
`mydomain.com.key` and `mydomain.com.csr`. Don't lose these, especially the
`.key` file!

    IMPORTANT: `mydomain.com.key` is the private key for your certificate.
    Never publish it or put it directly into source control. In the immortal
    words of Gandalf, "Keep it secret, keep it safe." If you're doing all of
    this on a virtual machine, using Vagrant, for example, make sure you copy
    the key off of the machine and store it someplace safe before you destroy
    the machine. Your certificate is useless without the private key!

Now that you have your Certificate Signing Request (`mydomain.com.csr`),
you'll need to submit it to a
[Certificate Authority](https://en.wikipedia.org/wiki/Certificate_authority)
and purchase an SSL certificate. Many domain registrars offer SSL certificate
services, so if you're not sure where to get one, check with your domain
registrar first. There is quite a broad range of SSL certificate options
available, so you'll need to choose one which is appropriate for your
application. For testing purposes, you should be able to get a basic
certificate for about $10, but for a production application, you may need
something more than that. (If you're not sure which SSL certificate is right
for you,
[we can help with that](https://www.rackspace.com/custom-networking/ssl-certs).)
Altogether, it should take a day or less to get your certificate.

When all is done, your certificate will be comprised of three files:

- The private key, which you generated at the beginning, along with your CSR.
- The certificate itself, typically saved as a `.crt` file. This will be given
  to you after a successful certificate request.
- The intermediate certificate chain, or Certificate Authority (CA) bundle.
  This will be given to you along with your certificate.

You will need all three files to set up SSL on your web application.

## Environment Setup<a href="environment-setup"></a>

Before we can start hacking on things, we'll need to install some tools. Log in
to your Linux or OSX machine and install the Docker Version Manager (dvm):

    wget https://download.getcarina.com/dvm/latest/install.sh
    sh install.sh

The output of this command will tell you to `source /home/me/.dvm/dvm.sh`
(where `/home/me` is your home directory) and then add that command to your
`.bashrc` or `.bash_profile`. Let's do that:

    source /home/me/.dvm/dvm.sh
    echo "/home/me/.dvm/dvm.sh" >> ~/.bashrc

## Let's Do This<a href="lets-do-this"></a>

Okay, now let's get to the fun part. Let's create a simple web application and
run it on Carina. First, [log in to Carina](https://app.getcarina.com/app/login).
This will drop you immediately into
the Carina control panel. Click on `Add Cluster...` and give it a name. You can
call it whatever you want. For example, you could name your cluster after the
FQDN for your site, such as `secure-mydomain-com`. (Note: The name can only contain
letters, numbers, underscores, and hyphens). Type in the `Cluster Name` and
select `Enable Autoscale` if you like; it's optional for this example. (You can
read more about Carina's autoscaling feature
[here](https://getcarina.com/docs/tutorials/autoscaling-carina/).)

![Carina - Creating a cluster]({% asset_path 2015-12-24-deploying-secure-web-applications-rackspace-cloud-carina-docker/1-carina-create-cluster.png %})

Click `Create Cluster` and watch it build. It will only take a minute. Once the
cluster is done building, click the `Get Access` button, then `Download File`.
Save this zip file somewhere convenient. For example, you can save it to your
home directory.

    NOTE: If you're running a Linux virtual machine with Vagrant, simply put
    the zip file in the same directory as your `Vagrantfile` and you can access
    the zip file inside the Vagrant box from the `/vagrant` directory.

![Carina - Get access, download credentials]({% asset_path 2015-12-24-deploying-secure-web-applications-rackspace-cloud-carina-docker/2-carina-get-access-download-file.png %})

`cd` into to the directory with the zip file and extract the contents using the `unzip` command:

    unzip secure-mydomain-com.zip

`cd` into the `secure-mydomain-com` directory.

In this directory, let's two create files: a `main.go` file for the web
application itself and a `Dockerfile`, from which the container for our web
application will be built. Notice that we're going to be writing our example
web application in [Go](https://golang.org). Why Go? Because Go is awesome,
and its built-in webserver is pretty decent. [Also, it turns out that it makes
for a really simple and concise example for this guide.]

Create the `main.go` file with the following code (which is borrowed from an
example in the
[Go documentation](https://golang.org/pkg/net/http/#ListenAndServe)):

```go
package main

import (
	"io"
	"net/http"
	"log"
)

func HelloHandler(w http.ResponseWriter, req *http.Request) {
	io.WriteString(w, "hello, world!\n")
}

func main() {
	http.HandleFunc("/", HelloHandler)
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
```

Next, let's create our `Dockerfile`:

```dockerfile
FROM golang

RUN mkdir -p /usr/src/app
ADD main.go /usr/src/app/main.go

WORKDIR /usr/src/app
RUN go build main.go

EXPOSE 8080

ENTRYPOINT ["./main"]
```

In case you're not yet too familiar Docker, here's what the `Dockerfile` is
doing:

- `FROM golang`: Start from a base image which already Go installed. (You can
  look for additional base images on [Docker Hub](https://hub.docker.com/).)
- `RUN mkdir -p /usr/src/app`: Create a folder inside the container for our
  application files.
- `ADD main.go /usr/src/app/main.go`: Copy `main.go` from the current directory
  into the target directory in the container.
- `WORKDIR /usr/src/app`: Change the working directory to `/usr/src/app`. All
  subsequent commands in the `Dockerfile` will be run from this directory.
- `RUN go build main.go`: Compile `main.go` and create a binary called `main`.
- `EXPOSE 8080`: Our `main` web application will bind to and listen on port
  8080, so we need to expose that port to the outside world.
- `ENTRYPOINT ["./main"]`: The command to execute to start the web service.

Now it's time to build our Docker container image and deploy it:

    source docker.env
    dmv use

`source docker.env` sets up environment variables we'll need in order to talk
to the Docker service running on Carina, and `dvm use` will sets up a compatible
Docker client for us to use with the service. Now we can actually build the
docker image:

    docker build --tag secure-mydomain-com .

Once the container image is built, we can deploy a container on Carina using
that image. We're actually going to deploy our container a couple of times,
each time in a slightly different way, and the entire deployment will get
increasingly complex as we go. First, we're going to deploy a single container
and verify that our "hello, world" web application is online and functions
correctly--with just direct HTTP (not HTTPS) access to the container.
Next, we'll deploy a pair of containers and set up a load balancer to
distribute the load, then test that the traffic is being routed correctly to
the containers. Finally, we will set up SSL on the load balancer, configure
DNS, and update the containers' network configuration to isolate them from the
public internet.

    QUESTION: Why use a load balancer? For one, putting a load balancer in
    place will allow you to easily horizontally scale your web application by
    simply spinning up more nodes/containers and adding them to your load
    balancer configuration. Second, it also makes installation of your SSL
    certificate a snap, in comparison to configuring Apache or Nginx to use
    your SSL cert. It also means you don't need to deal with SSL termination on
    your application containers, which potentially adds a lot of complexity and
    security concerns into your build pipeline.

## One Container<a href="one-container"></a>

Before we start deploying things, let's test that our `docker` client is configured correctly and communicating properly with Carina:

    docker ps

The command should simply return an empty listing, since we don't yet have any
containers running. So let's run one:

    docker run --detach --publish 8080 secure-mydomain-com

So what's going on here?

- `docker run`: This is the sub-command used to run Docker containers. But you
  probably guessed that already. =)
- `--detach`: Tell the Docker container to run in the background. If you omit
  this flag, your shell will retain an actively attached session to the
  container. (This can be useful to actively view output from your
  containerized application, and for testing and debugging. But for this
  example, we'll just use `--detach`.)
- `--publish 8080`: Publish port 8080 to make it available outside the
  container. In this case, Docker will figure out how to map this to an IP
  address and port which you can access outside of the container.
- `secure-mydomain-com`: This is simply the name of the container image we
  built using the `docker build` command above.

Run `docker ps` again, and you should see something like the following:

    $ docker ps
    CONTAINER ID        IMAGE                 COMMAND             CREATED             STATUS              PORTS                           NAMES
    880960711bb6        secure-mydomain-com   "./main"            3 minutes ago       Up 7 seconds        172.99.78.193:32769->8080/tcp   885bbfe5-5fd1-4797-97d1-2ae199906afb-n1/awesome_varahamihira

Take a look at the PORTS column. We see here that `172.99.78.193:32769` has
been set up to connect our web application to the outside world. (Your IP
address and port will of course be different in your cluster.) Let's test it
using `curl`. The command and output should look like this:

    $ curl http://172.99.78.193:32769  # replace the IP/port with the output you got from `docker ps`
    hello, world!

## Two Containers<a href="two-containers"></a>

Now let's add another container, using the same `docker run` command as before:

    docker run --detach --publish 8080 secure-mydomain-com

We should see two containers runnings now:

    $ docker ps
    CONTAINER ID        IMAGE                 COMMAND             CREATED             STATUS              PORTS                           NAMES
    3acd98aaad21        secure-mydomain-com   "./main"            3 minutes ago       Up 7 seconds        172.99.78.193:32770->8080/tcp   885bbfe5-5fd1-4797-97d1-2ae199906afb-n1/romantic_fermi
    880960711bb6        secure-mydomain-com   "./main"            5 minutes ago       Up 2 minutes        172.99.78.193:32769->8080/tcp   885bbfe5-5fd1-4797-97d1-2ae199906afb-n1/awesome_varahamihira

Test the connectivity on the second one:

    $ curl http://172.99.78.193:32770
    hello, world!

## Add a Cloud Load Balancer<a href="add-a-cloud-load-balancer"></a>

Log in to your [Rackspace Cloud control panel](https://mycloud.rackspace.com/).
At the top of the page, click `Networking`, then `Load Balancers`. On the form,
enter `secure.mydomain.com` for the load balancer name and make sure
`Northern Virginia (IAD)` is selected for the region. (Note: Carina runs in the
IAD region, so it's important to create your load balancer in the same region.
Toward the end of this post, you will see why that's important. You can find
more info about Rackspace regions
[here](http://www.rackspace.com/knowledge_center/article/about-regions).)
The rest of the settings can be left as defaults.

![Create a Load Balancer]({% asset_path 2015-12-24-deploying-secure-web-applications-rackspace-cloud-carina-docker/3-create-load-balancer.png %})

Scroll down to the `Add Nodes` section, and let's add our Docker containers.
Click `Add External Node` and copy/paste in the IP address and port
combinations of your containers (as you saw above while running `docker ps`).

![Load Balancer - Add Nodes]({% asset_path 2015-12-24-deploying-secure-web-applications-rackspace-cloud-carina-docker/4-create-load-balancer-add-nodes.png %})

After adding both nodes, your configuration should look something like this:

![Load Balancer - Nodes Added]({% asset_path 2015-12-24-deploying-secure-web-applications-rackspace-cloud-carina-docker/5-create-load-balancer-nodes-added.png %})

Click `Create Load Balancer` and watch it spin up. It should take a minute or
less.

![Load Balancer Details]({% asset_path 2015-12-24-deploying-secure-web-applications-rackspace-cloud-carina-docker/6-load-balancer-details.png %})

Now let's test it. Copy the `Public IP` from the load balancer detail and
`curl` it:

    $ curl http://146.20.25.93
    hello, world!

## Network, SSL, and DNS Configuration<a href="network-ssl-and-dns-configuration"></a>

Now it's time to put the finishing touches on our application. Currently, our
load balancer is communicating with our containers over a public network;
since this traffic is unencrypted, we need to fix that. The first thing we'll
need to do is redeploy our containers with a slightly different network
configuration.

Kill the currently running containers by running the 'docker kill' command for
each container ID:

    docker kill 3acd
    docker kill 8809

Note that you don't have to type the full container ID; all you have to do and
type in the first few characters of the ID and Docker will figure out which
container you meant. (If there's any ambiguity when matching a partial ID,
Docker will give you an error.)

We now want to deploy some new containers, but only expose them to
[ServiceNet](http://www.rackspace.com/knowledge_center/article/cloud-networks-faq),
Rackspace's private multi-tenant network partition.  (I mentioned above that
your load balancer needs to be in the IAD region--the same as Carina--and this
is why: ServiceNet provides service-to-service communication, but only within a
single region.) In order to do that, we need to get the ServiceNet IP of one of
the nodes in your cluster.

The Carina documentation already has a
[great tutorial](https://getcarina.com/docs/tutorials/servicenet/#run-a-redis-container-exposed-only-on-servicenet)
about exposing services only to ServiceNet, so we can use a couple of tricks
from that. First, we need to run `docker info`:

    $ docker info
    Containers: 5
    Images: 4
    Role: primary
    Strategy: spread
    Filters: health, port, dependency, affinity, constraint
    Nodes: 1
     885bbfe5-5fd1-4797-97d1-2ae199906afb-n1: 172.99.78.193:42376
      └ Containers: 5
      └ Reserved CPUs: 0 / 12
      └ Reserved Memory: 0 B / 4.2 GiB
      └ Labels: executiondriver=native-0.2, kernelversion=3.18.21-1-rackos, operatingsystem=Debian GNU/Linux 7 (wheezy) (containerized), storagedriver=aufs
    CPUs: 12
    Total Memory: 4.2 GiB
    Name: 817f1afe99da

Copy the node ID from the output. In this case, the node ID is
`885bbfe5-5fd1-4797-97d1-2ae199906afb-n1`. If `docker info` shows that your
cluster has more than one node, just pick one.

    NOTE: Each of the server nodes in your Carina cluster has both PublicNet IP
    address and a ServiceNet IP address. You can read more about the
    differences between PublicNet and ServiceNet
    [here](http://www.rackspace.com/knowledge_center/article/cloud-networks-faq).

Now let's get the ServiceNet IP for the node:

    $ docker run --net=host \
        --env constraint:node==885bbfe5-5fd1-4797-97d1-2ae199906afb-n1 \
        racknet/ip \
        service ipv4
    10.176.229.17

Copy the resulting IP address and then spin up two containers. The command you
need is similar to the `docker run` commands we used before, but there are a
couple of important additions:

    docker run --detach --publish 10.176.229.17::8080 \
        --env constraint:node=885bbfe5-5fd1-4797-97d1-2ae199906afb-n1 \
        secure-mydomain-com

Run this command a second time so we have two containers.

So what's going on in this command? There are two main things to focus on here:

- `--publish 10.176.229.17::8080`: The format of the `--publish` argument is
  `ip:hostPort:containerPort`. This means: publish the service running on
  `8080` in the container to the ServiceNet IP on the host, and use a random
  available port.
  ([Click here](https://docs.docker.com/engine/reference/run/#expose-incoming-ports)
  for more info about exposing ports in Docker.)
- `--env constraint:node=885bbfe5-5fd1-4797-97d1-2ae199906afb-n1`: This is a
  [Docker Swarm scheduling filter](https://docs.docker.com/swarm/scheduler/filter/)
  which simply specifies where the container should be hosted.

Let's check the results of our `docker run` commands:

    $ docker ps
    CONTAINER ID        IMAGE                 COMMAND             CREATED             STATUS              PORTS                           NAMES
    7ac35cf8c9d2        secure-mydomain-com   "./main"            3 minutes ago       Up 28 seconds       10.176.229.17:32771->8080/tcp   885bbfe5-5fd1-4797-97d1-2ae199906afb-n1/prickly_panini
    8398b4e45b1c        secure-mydomain-com   "./main"            3 minutes ago       Up 31 seconds       10.176.229.17:32768->8080/tcp   885bbfe5-5fd1-4797-97d1-2ae199906afb-n1/condescending_tesla

Take note of the host IP address and port for each container. We need to add
these to our load balancer. Head over to you Rackspace Cloud control panel and
open up your load balancer configuration. In the `Nodes` configuration, remove
the two old nodes (by clicking the gear and selecting
`Remove from load balancer...`), and then add two entries for our new
containers, using the `Add External Node` button.

Curl the load balancer IP and very that everything works:

	curl http://146.20.25.93

While we're in the load balancer configuration, we can install our SSL
certificate. Scroll to the `Optional Features` section and click the pencil
next to `Secure Traffic (SSL)`.

1. First, select `Allow Only Secure Traffic`.
2. For the `Certificate`, paste in your SSL certificate contents.
3. For the `Private Key`, paste in the contents of the private key you
   generated with your CSR. (If you followed the instructions above, paste the
   contents of the `mydomain.com.key` file.)
4. For the `Itermediate Cert`, paste the contents of your intermediate
   certificate/CA bundle file.
5. Click `Save SSL Configuration.`

![Load Balancer - Configuring SSL]({% asset_path 2015-12-24-deploying-secure-web-applications-rackspace-cloud-carina-docker/7-configure-ssl-add-keys-certs.png %})

Next, also under the `Optional Features`, click the pencil next to
`HTTPS Redirect` and enable it. This will ensure that all HTTP (non secure
HTTP) requests submitted to your load balancer will redirect to your secure
HTTP (HTTPS) endpoint. (You probably noticed that many sites do exactly this!
This is an important usability detail.)

Before we move on to DNS configuration, let's test the HTTPS redirect using a
`curl -i` and then a `curl -L` (to follow the redirect) on the load balancer:

    $ curl -i http://146.20.25.93
    HTTP/1.1 301 Moved Permanently
    Content-Type: text/html
    Content-Length: 0
    Connection: Keep-Alive
    Date: Thu, 26 Nov 2015 15:13:35 GMT
    Location: https://146.20.25.93/
    $ curl -L http://146.20.25.93
    curl: (60) SSL certificate problem: Invalid certificate chain
    More details here: http://curl.haxx.se/docs/sslcerts.html

    curl performs SSL certificate verification by default, using a "bundle"
     of Certificate Authority (CA) public keys (CA certs). If the default
     bundle file isn't adequate, you can specify an alternate file
     using the --cacert option.
    If this HTTPS server uses a certificate signed by a CA represented in
     the bundle, the certificate verification probably failed due to a
     problem with the certificate (it might be expired, or the name might
     not match the domain name in the URL).
    If you'd like to turn off curl's verification of the certificate, use
     the -k (or --insecure) option.

Basically, this error tells us that we should only be accessing our web
application using the domain name associated with our SSL certificate. (If you
try to access this address in a browser, you'll get a similar security
warning.)

Now for the last piece of the puzzle: You need to point your domain name to the
load balancer. Go into your DNS management console (wherever your DNS is
hosted) and create an A record for your domain name. If your domain name is
`secure.mydomain.com`, make an A record with a host name of `secure` and point
it to the IP of your load balancer. Once your DNS changes are fully propagated
(which may take a few hours or even a day), you can test the "real thing":

    $ curl https://secure.mydomain.com
    hello, world!

Try it out in a browser, too, and you should get a "green light" on your secure
connection!

![Browser - Secure HTTP]({% asset_path 2015-12-24-deploying-secure-web-applications-rackspace-cloud-carina-docker/8-https-secure.png %})

## Conclusion<a href="conclusion"></a>

In this tutorial, I've tried to give a simple and realistic example of
deploying a web application with SSL without leaving out important
details. Naturally, a real web application is going to be more complex than a
few containers running a "hello, world" program behind a load balancer. At some
point, so you will likely want to add a datastore, a cache, or other services.
The [Carina documentation](https://getcarina.com/docs/#tutorials)
already has a bunch of great tutorials for containerizing services like MySQL,
Apache, and MongoDB, so check them out! Happy hacking.
