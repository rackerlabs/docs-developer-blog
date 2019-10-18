---
comments: true
date: 2012-09-21T10:20:53.000Z
layout: post
title: 'Supernova:  Managing OpenStack Environments Made Easy'
author: Wayne Walls
categories:
  - Cloud Servers
  - OpenStack
---

_[Major Hayden](https://www.linkedin.com/in/majorhayden) first wrote about Supernova in June on his personal [blog](https://rackerhacker.com/?s=supernova). This follow-up post addresses the changes since then, including secondary service provider coverage, new pypi packages and few more usage examples. You can find Major on [Twitter](https://twitter.com/rackerhacker) or hanging out in the #openstack IRC channel on Freenode._

You have OpenStack Cloud Servers in Rackspace datacenters, you have a Rackspace OpenStack Private Cloud and you have some OpenStack HP Cloud servers all helping you run your business. You probably have a pile of credential files (often referred to as "novarc" files) on your servers, in Evernote or stored locally on your favorite laptop. In the an earlier [post](https://devops.rackspace.com/getting-started-using-python-novaclient-to-manage-cloud-servers.html), Hart discussed using [rackspace-novaclient](https://pypi.python.org/pypi/rackspace-novaclient/) to interface with the Rackspace open cloud. This was for a single environment, in a single datacenter. This will likely suffice for many smaller shops and start-ups, but as you grow and your needs get more complicated, you will have to start thinking about geographical redundancy, service provider redundancy, disaster recovery and many other needs that will require the use of more than one OpenStack-powered environment. The OpenStack API was developed fully in the open and has allowed full unadulterated access to its code. Anyone who wants to improve the community user experience can write tools to do just that.

<!-- more -->

One of those tools is _Supernova_. _Supernova_ is an OpenStack management tool authored by [Major Hayden](https://www.linkedin.com/in/majorhayden), a 6-year Rackspace veteran. This tool was born out of necessity. At Rackspace, we constantly work in development, staging and production environments in different locations around the world, and it became clear to us that we needed a more simple way to manage those environments. _Supernova_ will be a valuable tool if you regularly have the following problems:



	
  * You hate trying to source multiple novarc files when using any novaclient

	
  * You get your terminals confused and do the wrong things in the wrong nova environment

	
  * You don't like remembering things

	
  * You want to keep sensitive API keys and passwords out of plain text configuration files (see the "Working with Keyrings" section toward the end)

	
  * You need to share common skeleton environment variables for nova with your teams


If any of these complaints ring true, _Supernova_ is for you. _Supernova_ manages multiple nova environments without sourcing novarc's or mucking with environment variables.

**Installing Supernova**
There is a few prerequisites to using _Supernova_, and one is having rackspace-novaclient already installed. If you have yet to set this up, feel free to jump back to this article to get that situated, then you can come back here and proceed with the _Supernova_ configuration.

This post is being written on OSX 10.8.1 using Python 2.7.3

    
    [dubsquared@localshake ~]$ git clone git://github.com/rackerhacker/supernova.git
    [dubsquared@localshake ~]$ cd supernova
    [dubsquared@localshake ~]$ sudo python <a href="https://setup.py/">setup.py</a> install


**Supernova Configuration**
For _Supernova_ to work properly, each environment must be defined individually in `~/.supernova` (in your user's home directory). The data in the file is exactly the same as the environment variables that you would normally use when running novaclient. You can copy/paste from your novarc files directly into configuration sections within `~/.supernova`.

As we mentioned above, we're going to set up _Supernova_ to manage multiple OpenStack cloud environments.



	
  * Rackspace Cloud DFW (Dallas / Ft Worth)

	
    * We'll call this "rax-dfw"




	
  * Rackspace Cloud ORD (Chicago)

	
    * We'll call this "rax-ord"




	
  * HP Cloud West Region 1 (Arizona)

	
    * We'll call this "hp-az1"





Example .supernova file:

{% codeblock lang:bash %}
[rax-dfw]
OS_AUTH_URL=https://identity.api.rackspacecloud.com/v2.0/
OS_AUTH_SYSTEM=rackspace
OS_REGION_NAME=DFW
OS_SERVICE_NAME=cloudserversOpenStack
OS_TENANT_NAME=$RAX_TENANT_NAME
OS_USERNAME=$RAX_ACCOUNT_NAME
OS_PASSWORD=$RAX_APIKEY
OS_NO_CACHE=1
NOVA_RAX_AUTH=1

[rax-ord]
OS_AUTH_URL=https://identity.api.rackspacecloud.com/v2.0/
OS_AUTH_SYSTEM=rackspace
OS_REGION_NAME=ORD
OS_SERVICE_NAME=cloudserversOpenStack
OS_TENANT_NAME=$RAX_TENANTNAME
OS_USERNAME=$RAX_ACCOUNTNAME
OS_PASSWORD=$RAX_APIKEY
OS_NO_CACHE=1
NOVA_RAX_AUTH=1

[hp-az1]
NOVA_USERNAME=$HPCLOUD_USERNAME
NOVA_PASSWORD=$HPCLOUD_PASSWORD
NOVA_PROJECT_ID=$HPCLOUD-TENANT1
NOVA_URL=https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/
NOVA_REGION_NAME=az-1.region-a.geo-1
{% endcodeblock %}

HP Cloud recently released a Python extension that makes it easier to authenticate to its services, [hpcloud-auth-openstack](https://pypi.python.org/pypi/hpcloud-auth-openstack/1.0). This uses the region name you specified to route your request to the right service endpoint. You can install this using [pip](https://pypi.python.org/pypi/pip) and then you have one less configuration line item you have to worry about.

When you use _Supernova_, you'll refer to these environments as rax-dfw, rax-ord, and hp-az1. Every environment is specified by its configuration header name.

**Supernova Usage Overview**

    
    [dubsquared@localshake ~]$ supernova -h
    
    supernova [--debug] [--list] [environment] [novaclient arguments...]
    
    Options:
    -h, --help   show this help message and exit
    -d, --debug  show novaclient debug output (overrides NOVACLIENT_DEBUG)
    -l, --list   list all configured environments


**Supernova in Action!**
For example, if you wanted to list all instances within the rax-dfw environment:

    
    [dubsquared@localshake ~]$ supernova rax-dfw list


Show a particular instance's data in the hp-az1 environment:

    
    [dubsquared@localshake ~]$ supernova hp-az1 show 3edb6dac-5a75-486a-be1b-3b15fd5b4ab0a


The first argument is generally the _environment argument_ and it is expected to be a single word without spaces. Any text _after_ the environment argument is passed directly to nova.

**Debug Override**
You may optionally pass `--debug` as the first argument (before the environment argument) to see additional debug information about the requests being made to the API:

    
    [dubsquared@localshake ~]$ supernova --debug raw-dfw list
    
    ...snip
    reply: 'HTTP/1.1 200 OK\r\n'
    header: Server: nginx/0.8.55
    header: Date: Mon, 17 Sep 2012 01:16:49 GMT
    header: Content-Type: application/json
    header: Transfer-Encoding: chunked
    header: Connection: keep-alive
    header: vary: Accept, Accept-Encoding, X-Auth-Token
    header: response-source: cloud-auth
    header: Content-Encoding: gzip
    header: Front-End-Https: on
    ...snip


As before, any text after the environment argument is passed directly to nova.

**View Configured Environments**
You can list all of your configured environments by using the `--list` argument. This will output all the variables you have set and give you a quick overview of your environments:

    
    [dubsquared@localshake ~]$ supernova --list
    dubsquared@laptop-2 ~ > supernova --list
    -- rax-ord ----------------------------------------------------------------------
      NOVA_RAX_AUTH        : 1
      OS_AUTH_SYSTEM       : rackspace
      OS_AUTH_URL          : https://identity.api.rackspacecloud.com/v2.0/
      OS_NO_CACHE          : 1
      OS_PASSWORD          : USE_KEYRING
      OS_REGION_NAME       : ORD
      OS_SERVICE_NAME      : cloudserversOpenStack
      OS_TENANT_NAME       : ---------
      OS_USERNAME          : ---------
      OS_VERSION           : 1.1
    -- rax-dfw ----------------------------------------------------------------------
      NOVA_RAX_AUTH        : 1
      OS_AUTH_SYSTEM       : rackspace
      OS_AUTH_URL          : https://identity.api.rackspacecloud.com/v2.0/
      OS_NO_CACHE          : 1
      OS_PASSWORD          : USE_KEYRING
      OS_REGION_NAME       : DFW
      OS_SERVICE_NAME      : cloudserversOpenStack
      OS_TENANT_NAME       : ---------
      OS_USERNAME          : ---------
      OS_VERSION           : 1.1
    ...snip


**Supernova and Keyrings**
Due to security policies at certain companies or due to general paranoia, some users may not want API keys or passwords stored in a plain text _Supernova_ configuration file. Luckily, support is now available (via the [keyring](https://pypi.python.org/pypi/keyring/0.9.2) Python module) to store any configuration value within your operating system's keychain. This has been tested on the following platforms:
	
  * Mac: Keychain Access.app

	
  * Linux: gnome-keyring, kwallet


To get started, you'll need to choose an environment and a configuration option. For example, some data you might not want to keep in plain text is your Rackspace API key. This value is read into _Supernova_ as OS_PASSWORD, so that is value we need to add to our keychain:

    
    [dubsquared@localshake ~]$ supernova-keyring --set rax-dfw OS_PASSWORD
    
    [Keyring operation] Preparing to set a password in the keyring for:
    
    - Environment  : rax-dfw
    - Parameter    : OS_PASSWORD
    
    If this is correct, enter the corresponding credential to store in your keyring or press CTRL-D to abort:(paste your key here - press enter)
    
    [Success] Successfully stored credentials for rax-dfw:OS_PASSWORD under the supernova service.


If you need to use the same data for multiple environments, you can use a global credential item very easily:

	[dubsquared@localshake ~]$ supernova-keyring --set global MyCompanySSO

Once it's stored, you can test a retrieval. Here is a test using a regular, per-environment storage mechanism (not global):

    
    [dubsquared@localshake ~]$ supernova-keyring --get rax-dfw OS_PASSWORD
    [Warning] If this operation is successful, the credential stored 
    for dfw:OS_PASSWORD will be displayed in your terminal as plain text.
    
    If you really want to proceed, type yes and press enter: yes
    
    [Success] Found credentials for rax-dfw:OS_PASSWORD: $YOUR_API_KEY_APPEARS_HERE


You'll need to confirm that you want the data from your keychain displayed in plain text (to hopefully thwart shoulder surfers).

Once you've stored your sensitive data, simply adjust your _Supernova_ configuration file:

{% codeblock lang:bash %}
#The old [rax-dfw] stanza:
OS_PASSWORD = $RAX_APIKEY

#The new [rax-dfw] stanza:
# If using storage per OpenStack environment
OS_PASSWORD = USE_KEYRING

# If using global storage for multiple company environments
OS_PASSWORD = USE_KEYRING['MyCompanySSO']
{% endcodeblock %}

When _Supernova_ reads your configuration file and spots a value of `USE_KEYRING,` it will automatically look for credentials stored under `OS_PASSWORD` for that environment. If your keyring doesn't have a corresponding credential, you'll get an exception.

**How art thou environment variables used?**
_Supernova_ will only replace and/or append environment variables to the already present variables for the duration of the nova execution. If you have `OS_USERNAME` set outside the script, it won't be used in the script since the script will pull data from `~/.supernova` and use it to run nova. In addition, any variables which are set prior to running _Supernova_ will be left unaltered when the script exits.

**The Wrap**
With _Supernova_ you now have a tool to manage many OpenStack-powered environments across different service providers. This post can easily be modified to add support for OpenStack private clouds; other OpenStack-powered public clouds; and any other infrastructure management needs you may run into. As OpenStack continues to mature, you can expect more tools like _Supernova_ to bubble to the top and be recognized as community favorites. If you would like to contribute to _Supernova_, the [code](https://github.com/rackerhacker/supernova) is currently hosted on [Github](https://github.com/)!
