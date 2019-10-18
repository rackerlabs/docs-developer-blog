---
layout: post
title: The Pain of Slow Build Times
date: '2014-06-05 11:54'
comments: true
author: Matt Barlow
published: true
categories:
  - NodeJS
---

The other day I was working on a Ruby on Rails cookbook. I used the
excellent
[rbenv community cookbook](https://github.com/RiotGames/rbenv-cookbook)
to build Ruby 2.1.2, and
[Node.js](https://github.com/mdxp/nodejs-cookbook) for the JavaScript
runtime environment.

<!-- more -->

Everything was working great, but my build times were exceedingly
slow due to the compile of Ruby and Node.js. It was taking me on
average around 15 minutes to bootstrap a node.

{% img 2014-06-05-mattjbarlow/images/ruby_before_500.png Build Time Before %}

This made my testing process painful. Also, if I ever hoped to use this
cookbook in a scaling group, there was no way that I could wait 15
minutes for servers to build. So, I decided to take some immediate
action to speed up build times.

## Speeding Up Build Times with fpm

In order to speed up my build times, I decided to use [fpm](https://github.com/jordansissel/fpm) -- Effing
package management -- to package up a pre-compiled Ruby and
NodeJS. The result cut my build times in half, which is
great for a first pass.

{% img 2014-06-05-mattjbarlow/images/ruby_after_500.png Build Time After %}

## Overview of the Steps Required

Here are the steps I'll walk through. This same process can also be
applied to other software you want to package.

1. Generate a GPG Key.
2. Converge a node part way with [Test Kitchen](https://github.com/test-kitchen/test-kitchen).
3. Compile Ruby and Node.JS on the VM.
4. Build packages from the compiled software.
5. Create a signed Apt Repository directory structure.
6. Upload the Apt Repo to Rackspace Cloud Files.
7. Test the new Repo.
8. Update the Chef cookbook to add the repo and install the packages.

This walk through assumes you have the following installed:

### Gems:
* [berkshelf](https://berkshelf.com/) >= 3.1.0
* [test-kitchen](https://github.com/test-kitchen/test-kitchen) >= 1.2.0
* kitchen-vagrant >= 0.15.0

You can install these individually or via the
[Chef Development Kit](https://www.getchef.com/downloads/chef-dk/)

### System Packages:
* [vagrant](https://www.vagrantup.com/) >= 1.5.0
* [VirtualBox](https://www.virtualbox.org/) >= 4.3.0

### Python Modules:
* [file-syncer](https://github.com/Kami/python-file-syncer) >= 0.4.0

## Generate your GPG Key

Before getting started, generate a GPG Key if you don't already have
one. Here are some guidelines taken from
[OpenPGP Best Practices](https://we.riseup.net/riseuplabs+paow/openpgp-best-practices).

* Use a 2048-4096bit RSA key with sha512.
* Set expiration to a max of 5y.
* Generate a revocation certificate.
* Use your subkey for signing.
* Use long OpenPGP keyids.
* Do not include a comment.

You should create your gpg.conf file with the recommendations taken
from the Best Practices page. These commands will take care of that
for you:

    mkdir ~/.gnupg
    wget -O ~/.gnupg/gpg.conf https://gist.githubusercontent.com/mattjbarlow/14e9965bead6ce5ce5c9/raw/2b4e5cc282e754f18fa4ade6773b8dcde36f3df0/gistfile1.txt

Next, go ahead and generate your key:

    localhost:ruby-site $ gpg --gen-key
    Please select what kind of key you want:
       (1) RSA and RSA (default)
       (2) DSA and Elgamal
       (3) DSA (sign only)
       (4) RSA (sign only)
    Your selection? 1
    RSA keys may be between 1024 and 4096 bits long.
    What keysize do you want? (2048) 4096
    Requested keysize is 4096 bits
    Please specify how long the key should be valid.
             0 = key does not expire
          <n>  = key expires in n days
          <n>w = key expires in n weeks
          <n>m = key expires in n months
          <n>y = key expires in n years
    Key is valid for? (0) 5y

## Setup a Synced Folder

Let's set up a Synced Folder in your .kitchen.yml file:

    driver:
      name: vagrant

      network:
      - ["forwarded_port", {guest: 80, host: 8080}]

      customize:
        memory: 2048

      synced_folders:
        - ["data/instance_data", "/opt/instance_data"]

We will use this folder for transferring files back and forth from the
VM. IMPORTANT: Make sure your data/ directory is added to your .gitignore
file.

## Build the VM But return Early

Before you run 'kitchen converge' you can place a return statement
near the top of your default recipe in order to avoid waiting for a
full run.

I wanted the ruby_build and nodejs software but didn't care about
anything else, so I returned near the top of my recipe:

    include_recipe "rbenv::default"
    include_recipe "rbenv::ruby_build"

    # Install nodejs since Rails requires JS runtime
    include_recipe "nodejs::default"

    return

Build the VM with 'kitchen converge' which will leave the VM in a
running state.

## Copy your keys to the VM

You should, of course, be extremely careful when copying your GPG
keys. In this case, we will be destroying the VM in a just a few
minutes.

    cp -a ~/.gnupg/ data/instance_data/

## Build your ruby package

Log into the server with 'kitchen login' and build Ruby.

    mkdir /usr/local/ruby
    ruby-build 2.1.2 /usr/local/ruby/2.1.2
    cd /usr/local/ruby/2.1.2
    bin/gem install fpm

Then create your deb package with fpm and move it to your synced folder.

    bin/fpm -s dir -t deb -n ruby-2.1.2p95 -v 1 /usr/local/ruby/2.1.2/
    mv ruby-2.1.2p95_1_amd64.deb /opt/instance_data

## Build your nodejs package

My cookbook already compiled and installed Node.js and it was nice
enough to leave the source code hanging around. So, I just compiled it
again and installed it into a new directory.

    cd /usr/local/src/node-v0.10.15
    mkdir /usr/local/node
    ./configure --prefix=/usr/local/node; make; make install

Then, I built a package out of it and moved it to the synced folder.

    /usr/local/ruby/2.1.2/bin/fpm -s dir -t deb -n node-0.10.15 -v 1 /usr/local/node/
    mv node-0.10.15_1_amd64.deb /opt/instance_data

## Create your apt repository directory structure

I'm doing all of this in the synced folder since I will transfer it to
my workstation.

    mkdir -p /opt/instance_data/debian/conf

Add the following to /opt/instance_data/debian/conf/distributions

    Origin: Ruby Servers
    Label: Node and Ruby
    Codename: precise
    Architectures: amd64
    Components: main
    Description: Apt repository for Ruby servers
    SignWith: YOUR SUBKEY

Where it says YOUR SUBKEY insert the keyid for your SUBKEY which
looks like this:

{% img 2014-06-05-mattjbarlow/images/subkey_500.png Subkey %}

Then add the following to /opt/instance_data/debian/conf/options

    verbose
    basedir /opt/instance_data/debian
    ask-passphrase

This makes sure that you will be asked for your passphrase when
creating the repo.

Run these commands to build the repo:

    cd /opt/instance_data/debian
	apt-get install reprepro

    reprepro includedeb precise \
	/opt/instance_data/node-0.10.15_1_amd64.deb \
	/opt/instance_data/ruby-2.1.2p95_1_amd64.deb

You will need to export your public key as well, so that it can be
downloaded to verify the authenticity of your repo.

    gpg --armor --output ruby-site.gpg.key --export YOUR PUBKEY

Where it says YOUR PUBKEY, you guessed it, insert the keyid of your
PUBKEY which looks like this:

{% img 2014-06-05-mattjbarlow/images/pubkey_500.png Pubkey %}

## Sync Your Repo with Cloud Files

On your workstation, run 'pip install file-syncer' to download the
file-syncer which enables you to sync with Rackspace Cloud
Files. Here's the command I ran to sync the repo.

    file-syncer --log-level=DEBUG \
      --directory=~/chef/Personal/ruby-site/data/instance_data/debian/\
      --username=mattbarlow --key=YOUR API KEY\
      --container-name=ruby-site

You will need to get your API key from the mycloud.rackspace.com
control panel. You can find this by logging into mycloud.rackspace.com
and clicking Account Settings in the drop down menu next to your
account number.

{% img 2014-06-05-mattjbarlow/images/account_500.png API Key %}

Now that your repo is uploaded, you will need to log into
mycloud.rackspace.com and enable CDN on the container.

{% img 2014-06-05-mattjbarlow/images/cdn_enable_500.png CDN Enable %}

## Testing your Repo

Before going any further, you should back up your repo located in
data/instance_data/debian to a safe location, so that you can add new
packages to it later on.

To test your repo, move your return statement to the top of your
default recipe so that your VM is returned to you quickly. Run
'kitchen converge' and then 'kitchen login' when it is built.

Within the mycloud.rackspace.com control panel, right click on your
'ruby-site.gpg.key' and select "Copy Link Location".

Download the gpg key to your VM like this:

    wget https://YOUR_CDN_URL/ruby-site.gpg.key

Then run:

    apt-key add ruby-site.gpg.key

Finally, you will need to create a file called
/etc/apt/sources.list.d/ruby-site.list with contents similar to this:

    deb [arch=amd64] https://YOUR_CDN_URL precise main

Now, check that you are able to download your new packages:

    apt-get update
    apt-get install ruby-2.1.2p95
    apt-get install node-0.10.15
    apt-get install libyaml-0-2

The libyaml package was required for me to get RubyGems to work.

If everything worked as planned, you will now have Ruby and Node.js
installed into their respective /usr/local directories.

Now it is time to update our Chef cookbooks to add the apt repo,
download our packages, and make use of them.

## Preparing Your Chef Cookbook

We can start by assigning some attributes in attributes/default.rb

    default['ruby_path'] = '/usr/local/ruby/2.1.2'
    default['node_path'] = '/usr/local/node'

Here's a snippet from the recipes/default.rb to setup the apt repo and
install our new packages

    apt_repository 'ruby-site' do
      uri 'https://YOUR_CDN_URL'
      key 'https://YOUR_CDN_URL/ruby-site.gpg.key'
      arch 'amd64'
      components ['main']
      distribution 'precise'
    end

    %w(ruby-2.1.2p95 node-0.10.15).each do |package|
      apt_package package do
        action :install
      end
    end

I also found that I needed to update Apache envvars so that execjs in
Rails could find the JavaScript runtime. I did this by templatizing
the /etc/apache2/envvars config file and inserting this line into it:

    export PATH=<%= node['node_path'] %>/bin:<%= node['ruby_path'] %>/bin:$PATH

Similarly, you may want to update your system PATH by templatizing a
file called /etc/profile.d/custom.sh which sources custom.sh.erb as
follows:

    export PATH=<%= node['node_path'] %>/bin:<%= node['ruby_path'] %>/bin:$PATH

## What's Next?

After these changes, you should see a significant drop in build
times. As mentioned, mine dropped from 13m51s to 6m25s. There is still
opportunity with apt and the buildout of mod_passenger.so to speed
things up even further, but cutting our build times in half is great
for a first pass.

Here are some resources for further reading. Much thanks to the
contributors of these articles which were indispensible in the
preparation of this post.

* [Hosting APT repository on Rackspace CloudFiles](https://www.tomaz.me/2012/07/22/hosting-apt-repository-on-rackspace-cloud-files.html)
* [Setting Up Signed Apt Repository With Reprepro](https://wiki.debian.org/SettingUpSignedAptRepositoryWithReprepro)
* [OpenPGP Best Practices](https://we.riseup.net/riseuplabs+paow/openpgp-best-practices)
* [Creating your own Signed APT Repository and Debian Packages](https://blog.jonliv.es/2011/04/26/creating-your-own-signed-apt-repository-and-debian-packages/)

Also, here is a link to my GitHub repo that has the finished cookbook
using these packages:

* [Ruby Site Application Cookbook](https://github.com/mattjbarlow/ruby-site-fpm)
