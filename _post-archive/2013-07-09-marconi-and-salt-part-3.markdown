---
layout: post
title: 'Marconi and Salt: Part 3'
date: '2013-07-09 16:13'
comments: true
author: Oz Akan
published: true
categories:
  - OpenStack
---
In the [second article](https://developer.rackspace.com/blog/marconi-and-salt-part-2.html), we configured three environments: a `base` environment will have very generic formulas, which we would like to apply to all servers we will ever create with Salt. A `marconi-base` environment will have formulas that are identical in all Marconi environments. For example, the way we will install MongoDB isn't different in a production environment than a development environment so we will place MongoDB formulas in a `marconi-base` environment. There is a little trick here, that I mentioned in the previous article; we will never use a `marconi-base` environment but will use it in an overlay setup with the third environment, `marconi-preview-ord`. Let's go over the folder structure to make this a little more clear.<!-- more -->

First, let's check two folders for two Marconi environments.

    root@salt01:/srv/salt/marconi# ls
    base  preview-ord

Let's get into `base` environment.

    root@salt01:/srv/salt/marconi# cd base/
    root@salt01:/srv/salt/marconi/base# pwd
    /srv/salt/marconi/base

Let's check `mongodb/install.sls`

    root@salt01:/srv/salt/marconi/base# ls
    mongodb
    root@salt01:/srv/salt/marconi/base# cd mongodb
    root@salt01:/srv/salt/marconi/base/mongodb# ls
    install.sls

Now, let's go to a `marconi-preview-ord` environment.

    root@salt01:/srv/salt/marconi/base# cd ../preview-ord/
    root@salt01:/srv/salt/marconi/preview-ord# pwd
    /srv/salt/marconi/preview-ord
    root@salt01:/srv/salt/marconi/preview-ord# ls mongodb
    ls: cannot access mongodb: No such file or directory

We don't even have a `mongodb` folder under the `marconi-preview-ord` environment. In this case, when `install.sls` is called, based on the `salt-master` configuration file we setup in the previous article, Salt is going to look for the file in the `marconi-preview-ord` environment first. If it finds the file, it will execute it. If it can't find it, it will look for the file under location we setup for a `marconi-base` environment. This is a nice feature that lets us create only the formulas or data files which are different in each environment.

## Configure MongoDB Service

MongoDB plays an essential role in Marconi. It is the first storage for Marconi to be used in production. It handles data replication, so it is an important part of the HA plan. It can failover without the need of a floating IP address (VIP), so it's very handy for cloud environments where VRRP is not always available and you would usually have to use an API call to move an IP address from one instance to another. It can scale horizontally to a point by adding secondaries. Best of all, it is NoSQL, so applications designed to use MongoDB can easily be modified to handle many instances of the storage.

By default, Marconi uses three MongoDB instances - one primary and two secondaries. Writes go to the primary and reads to all instances. Writes are acknowledged after they are acknowledged by two members.

### Create Map File for MongoDB Instances

We will create a map file and use `salt-cloud` command to create all three instance at once with proper grains.

    root@salt01:~# emacs /srv/salt/marconi/preview-ord/map/mongodb_server.map
    marconi-centos-4GB:
        - mar-pre-ord-mng-01:
            minion:
                master: salt01.myserver.com
            grains:
                environment_id: marconi-preview-ord
                project: marconi
                environment: preview
                location: ord
                roles:
                    - mongodb_server
                mongodb_replica_set: pre-rs1
                mongodb_role: primary
        - mar-pre-ord-mng-02:
            minion:
                master: salt01.myserver.com
            grains:
                environment_id: marconi-preview-ord
                project: marconi
                environment: preview
                location: ord
                roles:
                    - mongodb_server
                mongodb_replica_set: pre-rs1
                mongodb_role: secondary
        - mar-pre-ord-mng-03:
            minion:
                master: salt01.myserver.com
            grains:
                environment_id: marconi-preview-ord
                project: marconi
                environment: preview
                location: ord
                roles:
                    - mongodb_server
                mongodb_replica_set: pre-rs1
                mongodb_role: secondary

Above, the first line defines the instance type. If you follow the rest of the file you will see that we create three instances of the same type. They have four grains: `environment_id`, `project`, `environment` and `location` with same values. We will use `environment_id` to match an environment and other grains to match all servers for the project, all servers for the location or a mix of these.

### Create MongoDB Instances

It is easy to create all three instaces with a command after having a proper map file.

    root@salt01:~#  salt-cloud -P -m /srv/salt/marconi/preview-ord/map/mongodb_server.map

`salt-cloud` is going to wait for a "Y" after reading the map file (-m option) and after that it will talk to the Rackspace OpenStack Cloud and start three instances in parallel (-P option). Once the instances are up, it will install salt-minion on all instances and register them to salt-master. It won't take long: we will have three instances with nothing but salt-minion running.

We can see them at this moment.

    root@salt01:~# salt-key  -L
    Accepted Keys:
    mar-pre-ord-mng-01
    mar-pre-ord-mng-02
    mar-pre-ord-mng-03
    Unaccepted Keys:
    Rejected Keys:

We can even ping them by matching `environment_id`.

root@salt01:~# salt -G 'environment_id:marconi-preview-ord' test.ping

    mar-pre-ord-mng-02:
        True
    mar-pre-ord-mng-01:
        True
    mar-pre-ord-mng-03:
        True

Is your list out of order? that is normal. The command above places a message in ZeroMQ that is processed by minions and the order is not guaranteed.

We can even choose the instances by `environment_id` and `roles`, which we will use more often when we have more types of servers.

    root@salt01:~# salt -C 'G@environment_id:marconi-preview-ord and G@roles:mongodb_server' test.ping
    mar-pre-ord-mng-02:
        True
    mar-pre-ord-mng-01:
        True
    mar-pre-ord-mng-03:
        True

### Create SLS Formulas

We cannot initiate a replica set before having all servers ready so we will first install MongoDB servers and then configure replica sets.

Let's create MongoDB folder.

    root@salt01:/srv/salt/marconi/base# pwd
    /srv/salt/marconi/base
    root@salt01:/srv/salt/marconi/base# mkdir mongodb
    root@salt01:/srv/salt/marconi/base# cd mongodb

Let's create an `init.sls` file that just includes the `install.sls` formula.

    root@salt01:/srv/salt/marconi/base/mongodb# emacs init.sls
    include:
      - mongodb.install

Now, we will create the formula file that actually configures the MongoDB repo, installs it and configures it.

    root@salt01:/srv/salt/marconi/base/mongodb# emacs install.sls
    /etc/yum.repos.d/10gen.repo:
      file:
        - managed
        - source: salt://mongodb/files/10gen.repo

    /etc/sysconfig/mongod:
      file:
        - managed
        - template: jinja
        - replica_set: {{ grains['mongodb_replica_set'] }}
        - source: salt://mongodb/files/mongod

    /etc/logrotate.d/mongodb:
      file:
        - managed
        - source: salt://mongodb/files/logrotate_mongodb

    numactl:
      pkg:
        - installed

    mongo-10gen:
      pkg:
        - installed
        - require:
          - file: /etc/yum.repos.d/10gen.repo

    mongo-10gen-server:
      pkg:
        - installed
        - require:
          - file: /etc/yum.repos.d/10gen.repo
          - pkg: numactl
          - pkg: mongo-10gen
      service:
        - name: mongod
        - running
        - watch:
          - file: /etc/sysconfig/mongod
          - file: /etc/mongod.conf

    /etc/mongod.conf:
      file:
        - managed
        - template: jinja
        - source: salt://mongodb/files/mongod.conf

    pymongo:
      pkg:
        - installed
        - require:
          - pkg: mongo-10gen
          - pkg: mongo-10gen-server

Above there are two sections that require some clarification.

#### Jinja Templates

First one is the MongoDB configuration section which reads a Jinja template to create the actual file on the minion.

    /etc/sysconfig/mongod:
      file:
        - managed
        - template: jinja
        - replica_set: {{ grains['mongodb_replica_set'] }}
        - source: salt://mongodb/files/mongod.jinja

Templates are files that are rendered by a template engine. In this case, Jinja is the default, but Salt supports many others. While a static file would have to be the same on all environments, a template may differ from one environment to another by using the system variables. In the example above, we see that `replica_set` gets the value of `{{ grains['mongodb_replica_set'] }}`.

Now, we will create the template file.

    root@salt01:/srv/salt/marconi/base/mongodb# mkdir files
    root@salt01:/srv/salt/marconi/base/mongodb# emacs files/mongod.jinja
    OPTIONS="${OPTIONS} --rest --nojournal --replSet {{ replica_set }}"

#### Service and Watch Statement

With a Salt service module, we can manage states of a service and restart it when there is a change in it's configuration files.

    mongo-10gen-server:
      pkg:
        - installed
        - require:
          - file: /etc/yum.repos.d/10gen.repo
          - pkg: numactl
          - pkg: mongo-10gen
      service:
        - name: mongod
        - running
        - watch:
          - file: /etc/sysconfig/mongod
          - file: /etc/mongod.conf

Above, the `pkg` section handles installation of a mongo-10gen-server from the repository that is defined in `/etc/yum.repos.d/10gen.repo` and requires `numactl` and `mongo-10gen` packages to be installed. The `service` section ensures that the `MongoDB` process is running. If two files under the watch statement are changed, Salt will also restart the `MongoDB` process by running the `service MongoDB restart` command.

#### Other Files for MongoDB

At this point, the MongoDB folder is going to look like this:

    root@salt01:/srv/salt/marconi/base/mongodb# tree
    .
    -- files
    |   -- 10gen.repo
    |   -- logrotate_mongodb
    |   -- mongod.conf
    |   -- mongod.jinja
    -- init.sls
    -- install.sls

The `10gen.repo` file has the repository information.

    root@salt01:/srv/salt/marconi/base/mongodb/files# cat 10gen.repo
    [10gen]
    name=10gen Repository
    baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64
    gpgcheck=0
    enabled=1

`logrotate_mongodb` has the log rotation configuration.

    root@salt01:/srv/salt/marconi/base/mongodb/files# cat logrotate_mongodb
    /var/log/mongo/*.log {
           weekly
           rotate 10
           copytruncate
           delaycompress
           compress
           notifempty
           missingok
    }

`MongoDB.conf` the has MongoDB configuration.

{% highlight php %}
root@salt01:/srv/salt/marconi/base/mongodb/files# cat mongod.conf
logpath=/var/log/mongo/mongod.log
logappend=true
fork = true
dbpath=/var/lib/mongo
pidfilepath = /var/run/mongodb/mongod.pid
replSet = {{ grains['mongodb_replica_set'] }}
{% endhighlight %}

### Run MongoDB Formulas

Now, we will put our SLS formulas to action.

We can run this:

    root@salt01:~# salt -C 'G@environment_id:marconi-preview-ord and G@roles:mongodb_server' state.sls mongodb marconi-preview-ord

or this:

    root@salt01:~# salt -C 'G@environment_id:marconi-preview-ord and G@roles:mongodb_server' state.sls mongodb.install marconi-preview-ord

The tiny difference is the first line only has `MongoDB` while second line has `mongodb.install`. Remember that MongoDB folder has a file named `init.sls` and it is the default formula file called when only a folder name is provided as a parameter to the `state.sls` function. Also, remember that, our `mongodb/init.sls` file includes `install.sls` which means calling `mongodb` is identical to `mongodb.install`. In Salt language, the first one would run `init.sls` which eventually runs `install.sls`, and the second one would directly run `install.sls`.

It will take a while, though not long, for three servers to download packages and install them. All the files under the `files` folder are going to be copied from master to minions after being parsed by Jinja when required.

### Configure MongoDB Replica Set

Once we have MongoDB installed on all three servers, we can setup replica sets.

#### Manual (Human Keyboard) Way

If we do it manually, these are the steps to configure replica set.

* Decide replica set name, `pre-rs1` in this case
* Login to the MongoDB server (`mar-pre-ord-mng-01`), which will be the primary
* Initiate the replica set on primary
    * `# mongo local --eval "printjson(rs.initiate())"`
    * Wait long enough this process to get executed
* Add the first secondary MongoDB instance
    * `# mongo local --eval "printjson(rs.add('mar-pre-ord-mng-02'))"`
* Add the second secondary MongoDB instance
    * `# mongo local --eval "printjson(rs.add('mar-pre-ord-mng-03'))"`

The commands above are run on the bash instead of the mongo console, which lets us use them later on within SLS formulas.

#### Automated (Salt) Way

We will use create another SLS formula to wrap the`mongodb` we created above. We will name it `mongodb_server` and it may differ from implementation to implementation, while installing binaries is relatively standard.

Let's create the folder.

    root@salt01:~# mkdir /srv/salt/marconi/base/mongodb_server/
    root@salt01:~# cd /srv/salt/marconi/base/mongodb_server/

We will create the must-have `init.sls` file under the new folder.

{% raw %}
    root@salt01:/srv/salt/marconi/base/mongodb_server# emacs init.sls
    {% if 'roles' in grains and 'mongodb_server' in grains['roles'] %}

    include:
      - mongodb

    {% endif %}
{% endraw %}

This is the first SLS we used as an "if" statement. First we check if a `roles` string is present in `grains`. `grains` is a data structure available on each minion. When the salt-minion process starts, it reads the `/etc/salt/minion` and `/etc/salt/grains` files and creates a dictionary. `grains` is one of the keys in this dictionary that can be accessed on each minion during an SLS formula execution. Apart from the grains, each minion knows about OS-specific information which we will use later on.

The second part of the "if" checks if a `mongodb_server` string is present in `grains['roles]`. In YAML, representation for this data would be like:

    grains:
      roles: ['mongodb_server']

`grains` is the key for the dictionary that holds `roles` as key and `mongodb_server` is the first item in the list as a value.

Salt data structures are all based on dictionaries and lists. It would be beneficial to understand these concepts to be able to get most out of Salt. More on Python [dictionary](http://www.tutorialspoint.com/python/python_dictionary.htm) and [lists](http://www.tutorialspoint.com/python/python_lists.htm).

In the include statement we provided `mongodb` so `mongodb_server` SLS will just install MongoDB. To create replica set, we will have to be sure that MongoDB has already been installed. So, for now, we split this into two different tasks.

Let's dive into `replica.sls`

{% highlight text %}
root@salt01:/srv/salt/marconi/base/mongodb_server# emacs replica.sls
{% endhighlight %}

{% highlight php %}
{% raw %}
  {% if 'mongodb_role' in grains and grains['mongodb_role'] == 'primary' %}
  {%   if 'mongodb_replica_set_configured' not in grains or grains['mongodb_replica_set_configured'] != true %}

  mongo local --eval "printjson(rs.initiate())":
    cmd:
      - run

  {% set my_replica_set = grains['mongodb_replica_set'] %}
  {% set my_id = grains['id'] %}
  {% for host, value in salt['mine.get']('environment_id:' + grains['environment_id'], 'grains.items', expr_form='grain').items() %}
  {%     if value.id != my_id and 'mongodb_server' in value.roles and my_replica_set == value.mongodb_replica_set %}

  mongo local --eval "printjson(rs.add('{{ value.id }}'))":
    cmd:
      - run

  {%     endif %}
  {% endfor %}

  mongodb_replica_set_configured:
    grains:
      - present
      - value: true

  {%   endif %}
  {% endif %}
{% endraw %}
{% endhighlight %}

We want to run an SLS formula that will configure a replica set only on one (the primary) MongoDB instance. So we start with two "if" statements (it could be just one "if" statement) to ensure this is a MongoDB server with a primary role and it is the first time we are trying to configure replica set.

Remember that we can call this SLS formula as shown below:

    # salt '*' state.sls mongodb_server.replica marconi-preview-ord

If we do so, all minions will match the `'*'` expression but only one server with the correct grain values will run the `mongodb_server.replica` SLS formula.

The First directive uses the `cmd` state module and tells salt-minion to run the `mongo local --eval "printjson(rs.initiate())"`.

Then we populate my_replica_set value and my_id variables using grains. Later we run a "for" loop to run `mongo local --eval "printjson(rs.add('{{ value.id }}'))"` on each server that is a MongoDB secondary. Here we use Salt mine, which is another data structure similar to pillar but populated via minions and stored on master. It helps minions to access other minions' data. Remember that `replica.sls` will be run by salt-minion on the MongoDB primary server so in our case `mar-pre-ord-mng-01` will have to find other MongoDB servers and Salt mine just helps with that. We will discuss Salt mine later in depth.

A quick note about `value.id`: It is a different representation of `value['id']`.

Finally, we set `mongodb_replica_set_configured` to `true` so that `replica.sls` is guaranteed to run just once.

Run this.

    # salt 'mar-pre-ord-mng-01' state.sls mongodb_server.replica marconi-preview-ord

All good?  Not yet.

First, a quick reminder about `marconi-preview-ord`: it tells Salt which environment to use and eventually it just means what folder to look for. Remember our `/etc/salt/master` file;

      marconi-preview-ord:
        - /srv/salt/marconi/preview-ord
        - /srv/salt/marconi/base

According to this configuration `mongodb_server.replica` indicates the file location to be `/srv/salt/marconi/preview-ord/mongodb_server/replica.sls` or `/srv/salt/marconi/base/mongodb_server/replica.sls`.

Second, the problem with `replica.sls` is that Salt isn't guaranteed to run those directives in the order represented in the file by default. We need to use the require directive to indicate which state needs the other to run first in order for it to run.

Below is a better version of `replica.sls`.

{% highlight php %}
{% raw %}
  {% if 'mongodb_role' in grains and grains['mongodb_role'] == 'primary' %}
  {%   if 'mongodb_replica_set_configured' not in grains or grains['mongodb_replica_set_configured'] != true %}

  mongo local --eval "printjson(rs.initiate())":
    cmd:
      - run

  {% set my_replica_set = grains['mongodb_replica_set'] %}
  {% set my_id = grains['id'] %}
  {% for host, value in salt['mine.get']('environment_id:' + grains['environment_id'], 'grains.items', expr_form='grain').items() %}
  {%     if value.id != my_id and 'mongodb_server' in value.roles and my_replica_set == value.mongodb_replica_set %}

  mongo local --eval "printjson(rs.add('{{ value.id }}'))":
    cmd:
      - run
      - require:
          - cmd: mongo local --eval "printjson(rs.initiate())"

  {%     endif %}
  {% endfor %}

  mongodb_replica_set_configured:
    grains:
      - present
      - value: true

  {%   endif %}
  {% endif %}
{% endraw %}
{% endhighlight %}

This is still not perfect as it takes a while for MongoDB to initiate the primary, so we will have to wait until primary is initiated before adding secondaries.

So we will add the section below to create a file that will be executed as a Python script and wait for as long as 30 seconds until primary is set.

    /tmp/.ismaster.py:
      file:
        - managed
        - source: salt://mongodb_server/files/ismaster.py
        - require:
            - cmd: rs-initiate

    rs-ismaster:
      cmd:
        - run
        - name: python /tmp/.ismaster.py
        - cwd: /tmp
        - stateful: true
        - require:
            - file: /tmp/.ismaster.py

Be careful about `rs-ismaster` where we set stateful to true. This enables other states to watch `rs-ismaster``. The state that add secondaries has to check `rs-ismaster` return value.

The `ismaster.py` file looks like this:

    from time import  sleep
    import pymongo
    conn = pymongo.connection.Connection('localhost', 27017)
    db = conn['local']

    counter = 0

    while counter < 30 :
        if db.command('isMaster')['ismaster']  == True:
            print "\nchanged=yes"
            break
        counter += 1
        sleep(1)

The above script connects to the local MongoDB instance, loops 30 times, checks if it is master, and sleeps a second in each loop. When master is set, it returns "changed=yes" which will be used by Salt to decide if there was a change. For more information you can check [salt.states.cmd](http://docs.saltstack.com/ref/states/all/salt.states.cmd.html).

Finally `replica.sls` will look like this:

{% highlight php %}
{% raw %}
  {% if 'mongodb_role' in grains and grains['mongodb_role'] == 'primary' %}
  {%   if 'mongodb_replica_set_configured' not in grains or grains['mongodb_replica_set_configured'] != true %}

  rs-initiate:
    cmd:
      - run
      - name: mongo local --eval "printjson(rs.initiate())"
      - cwd: /tmp

  /tmp/.ismaster.py:
    file:
      - managed
      - source: salt://mongodb_server/files/ismaster.py
      - require:
          - cmd: rs-initiate

  rs-ismaster:
    cmd:
      - run
      - name: python /tmp/.ismaster.py
      - cwd: /tmp
      - stateful: true
      - require:
          - file: /tmp/.ismaster.py

  {% for host, value in salt['mine.get']('environment_id:' + grains['environment_id'], 'grains.items', expr_form='grain').items() %}
  {%     if value.id != grains['id'] and 'mongodb_server' in value.roles and grains['mongodb_replica_set'] == value.mongodb_replica_set %}

  mongo local --eval "printjson(rs.add('{{ value.id }}'))":
    cmd:
      - wait
      - watch:
          - cmd: rs-ismaster

  {%     endif %}
  {% endfor %}

  mongodb_replica_set_configured:
    grains:
      - present
      - value: true

  rs-status:
    cmd:
      - wait
      - name: /usr/bin/mongo local --eval "printjson(rs.status())"
      - cwd: /tmp
      - watch:
          - cmd: rs-ismaster

  {%   endif %}
  {% endif%}
{% endraw %}
{% endhighlight %}

At this point we can create a MongoDB replica set in three steps.

1. Create servers
    * `root@salt01:~#  salt-cloud -P -m /srv/salt/marconi/preview-ord/map/mongodb_server.map`
2. Install MongoDB
    * `root@salt01:~# salt '*' state.sls mongodb_server marconi-preview-ord`
3. Configure Replica Set
    * `root@salt01:~# salt '*' state.sls mongodb_server.replica marconi-preview-ord`

## Conclusion

In this article, we discussed environments in more detail; automated VM provisioning with a map file; used Jinja templates and grains; and used watch and require statements that let us run states in a desired order.

In the next article, we will define roles for our server types and manage our grains with Salt as well.

Until then, if you have questions, you can find me at [Twitter](https://twitter.com/ozgurakan) or at [Google+](https://plus.google.com/110684487860941982359). Comments on this page are welcome as well.
