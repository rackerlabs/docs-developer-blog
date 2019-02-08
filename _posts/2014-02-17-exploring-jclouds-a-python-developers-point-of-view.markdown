---
layout: post
title: Exploring Apache jclouds with Groovy - A Python developer's point of view
date: '2014-03-05 11:00'
comments: true
author: John Yi
published: true
categories:
  - jclouds
  - sdk
  - developers
  - java
  - python
---

One of the most powerful features of Python is the REPL (Run, Evaluate, Print,
and Loop) This allows developers to run their code and get quick feedback.
Developers are able test out new ideas and try out different things without
the cycle of modifiying, compiling, and running the source code.

Another feature of Python's REPL is the introspection capabilities. This allows
developers to easily and dynamically explore libraries.

In the Java world there are a number of options to do this. This post explores
some of those; and how to leverage groovy and jclouds to achieve the same speed
of development.

<!-- more -->

Java developers rely on their Integrated Development Environments (IDEs) to
provide features like object introspection, code completion, on the fly code
analysis, and quick access to help documentation. However most Python
developers are not familiar with the various Java IDEs and would need time to
learn how to use their features.

They also may need to learn the Java language itself for a project. This is
where Groovy makes a lot of sense.

Groovy is a dynamic language like Python but has a Java like language syntax.
It also has seamless integration to existing Java classes and libraries making
it easy to use with existing Java code.

Apache [jclouds](http://jclouds.apache.org/) has become the defacto library of
multicloud infrastructures for Java developers. (The Python equivalent being
[libcloud](https://libcloud.readthedocs.org/en/latest/))


To make the setup easy, I'll specify a very opinionated setup running Ubuntu
12.04 with OpenJDK 7 patch 51. The code samples were created using the Ubuntu
12.04 image from Rackspace - [Ubuntu 12.04 LTS (Precise Pangolin) (PVHVM) (28b21a55-b686-4e8e-be9b-b6df2aaf60b8)]
however the precise64 virtualbox from Vagrant should work as well. Finally
your environment should have access to the internet. So let's set this up:

```
apt-get update
apt-get -y install openjdk-7-jdk zip unzip maven
```

Groovy has a environment manager called gvm that is similiar in concept to the
Ruby environment manager rvm. I've found this to be quite useful:

```
export JAVA_HOME=/etc/alternatives/java
curl -s get.gvmtool.net | bash
```

At this point gvm should be installed but you'll either have to source the gvm-init.sh or
restart the shell as specifed by the message upon gvm installation.
For most folks sourcing gvm-init.sh is easier.

```
source "$HOME/.gvm/bin/gvm-init.sh"
```

You'll now want to install the latest version of Groovy. At the time of this post the latest version is 2.2.1,
however you can run the command below to install the latest version:

```
gvm install groovy
```

Great, so now groovy is installed and we'll want to start diving into the jclouds code.
The easiest thing to start exploring is the
[jclouds-examples](https://github.com/jclouds/jclouds-examples) repo. Because
the examples already give us a lot of scaffolding code we can easily start
exploring without to much typing. So let's first clone the jclouds-example
repo from github.

```
git clone https://github.com/jclouds/jclouds-examples.git
cd jclouds-examples/rackspace
```

Next we'll need to pull down all our dependent libraries. Maven is to a Java
developer what pip is to a Python developer.

```
mvn dependency:copy-dependencies "-DoutputDirectory=./lib"
```

Also because we'll be using the jclouds-examples/rackspace we should go ahead and create class
files from the source.

```
javac -classpath "lib/*:src/main/java/:src/main/resources/" src/main/java/org/jclouds/examples/rackspace/*.java
```

So let's explore something that isn't to trival, creating a cloud server and
then adding some block storage to it.

We'll explore the example CreateVolumeAndAttach.java. So all we have to do at this point
is fire up groovy's REPL with the appropriate classpath set and import this package.

```
groovysh -cp "lib/*:src/main/java/:src/main/resources/"
Groovy Shell (2.2.1, JVM: 1.7.0_51)
Type 'help' or '\h' for help.
---------------------------------------------------------------------------------------------------------------------------
groovy:000> import org.jclouds.examples.rackspace.cloudblockstorage.CreateVolumeAndAttach
===> [import org.jclouds.examples.rackspace.cloudblockstorage.CreateVolumeAndAttach]
```

It helps to be looking
at the source here so point your browser to [CreateVolumeAndAttach.java](https://github.com/jclouds/jclouds-examples/blob/master/rackspace/src/main/java/org/jclouds/examples/rackspace/cloudblockstorage/CreateVolumeAndAttach.java)

Also, you'll need to grab your username and api_key. Instructions on how to do that are here:
[http://jclouds.apache.org/guides/rackspace/](http://jclouds.apache.org/guides/rackspace/)

```
cvs = new CreateVolumeAndAttach("groovy","beaf5678fffeeedddccc")
```

Because we've created an instance of the class CreateVolumeAndAttach, we
can should be able to access the computeService handle. We'll assign a convenient
alias to it. (A little snake_case for the Pythonista in me.)

```
compute_service = cvs.computeService
```

So let's go ahead and create our first cloud server. We'll create the Template
object first. Templates are jclouds way of abstracting the cloud instance
configurations to make it more portable to use with other clouds. Some common
elements that clouds share are things like Images, Hardware, and Location. To
make allowances for different options for booting images
jclouds also defines Options within the same Template object.

Here on the Rackspace cloud we'll use performance1-1 for our flavor and the
image that matches the regex ".*CentOS 6.4.*" So let's try this out. We'll
need to import some packages to bring them into our namespace.

```
import static org.jclouds.examples.rackspace.cloudblockstorage.Constants.*;
import org.jclouds.openstack.nova.v2_0.domain.zonescoped.ZoneAndId;
zoneAndId = ZoneAndId.fromZoneAndId(ZONE, "performance1-1");
template = compute_service.templateBuilder().locationId(ZONE).osDescriptionMatches(".*CentOS 6.4.*").hardwareId(zoneAndId.slashEncode()).build();
```

Here the constant ZONE was defined by the static import of
org.jclouds.examples.rackspace.cloudblockstorage.Constants.*
however any string defining a valid zone (i.e. "IAD", "ORD", "DFW", "SYD") would work.
Next let's create the cloud server. Because the method createNodesInGroup blocks till
the cloud server is created, let's put the method call createNodesInGroup
in its own thread so that we don't have to wait for it to finish.

```
node_create = Thread.start {
nodes = compute_service.createNodesInGroup("groovy-demo", 1, template);
nodeMetadata = nodes.iterator().next();
publicAddress = nodeMetadata.getPublicAddresses().iterator().next(); }
```

While our server is being created (1 - 2 minutes) we can work on creating our block storage.
As usual we'll need to import a few things.

```
import org.jclouds.openstack.cinder.v1.options.CreateVolumeOptions;
import com.google.common.collect.ImmutableMap;
options = CreateVolumeOptions.Builder.name("groovy-volume").metadata(ImmutableMap.<String, String> of("key1", "value1"));
volume = cvs.volumeApi.create(100, options);
```

Next let's join our thread node_create to our current context to make sure it is finished. This command
will block till node_create completes.

```
node_create.join()
```

So the method compute_service.createNodesInGroup actually returns
a list. For example if we had called it with compute_service.createNodesInGroup('groovy-demo', 5, template) we'd
be creating five servers based of the template. However because we are creating it with just one server
I'll just reference the first item in the list thus it will be nodes[0].getProviderId() in the argument
for attaching the volume. So let's attach the volume.

```
volumeAttachment = cvs.volumeAttachmentApi.attachVolumeToServerAsDevice(volume.getId(), nodes[0].getProviderId(), DEVICE);
```

At this point you should be able to see the volume attached to the server in the cloud control panel.
First we'll create a groovy password generator [from stackoverflow.com](http://stackoverflow.com/questions/8138164/groovy-generate-random-string-from-given-character-set)

Then we'll change the admin password to the secret password that we just generated.

```
generator = { String alphabet, int n ->
  new Random().with {
    (1..n).collect { alphabet[ nextInt( alphabet.length() ) ] }.join()
  }
}
set verbosity QUIET
secret_password = generator( (('a'..'z')+('A'..'Z')+('0'..'9')).join(), 12);
set verbosity INFO
cvs.nova.getApi().getServerApiForZone(ZONE).changeAdminPass(nodeMetadata.getProviderId(), secret_password);
```

Now it's time to build the script and run the
commands that will create a filesystem and mount the volume.

```
import org.jclouds.scriptbuilder.ScriptBuilder;
import static org.jclouds.scriptbuilder.domain.Statements.exec;
import org.jclouds.scriptbuilder.domain.OsFamily;
import org.jclouds.compute.options.RunScriptOptions;
script = new ScriptBuilder()
script.addStatement(exec("mkfs -t ext4 /dev/xvdd"))
script.addStatement(exec("mount /dev/xvdd /mnt"))
script.render(OsFamily.Unix)
options = RunScriptOptions.Builder.blockOnComplete(true).overrideLoginPassword(secret_password)
response = compute_service.runScriptOnNode(nodes[0].getId(), script, options);
```

Once the command completes you should get a status that looks like this:

```
===> {output=Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
6553600 inodes, 26214400 blocks
1310720 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=4294967296
800 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
	4096000, 7962624, 11239424, 20480000, 23887872

Writing inode tables: done
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done

This filesystem will be automatically checked every 29 mounts or
180 days, whichever comes first.  Use tune2fs -c or -i to override.
, error=mke2fs 1.41.12 (17-May-2010)
, exitStatus=0}
```

So there you go. Again the purpose of using Groovy here is to learn jclouds
in a Java context. You can of course explore jclouds with Jython and JRuby but
hopefully this will give the Python/Ruby developer yet another option when
exploring and hacking!
