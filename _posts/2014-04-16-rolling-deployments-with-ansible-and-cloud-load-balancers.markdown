---
layout: post
title: Rolling deployments with Ansible and Cloud Load Balancers
date: '2014-04-22 10:00'
comments: true
author: Jesse Keating
published: true
categories:
  - ansible
---

Recently a fellow Racker wrote a great post about [zero downtime deployments][0].
I strongly believe in the principals he described. In his example, he used Node.js
to build a deployment script to accomplish the goal, and I want to explore how
this could be done with [Ansible][1] and the Rackspace Cloud.

<!-- more -->

### Theory review

Lets review the theory. Assume you have 4 app servers behind a cloud load balancer. A zero downtime rolling deploy would mean taking half of the app servers out of the load balancer rotation, updating app code on them, validating app code on them, and re-inserting them back into the load balancer before moving on to repeat the steps with the second half of the app servers.

1. Mark two nodes as `draining`
2. When your app is done with current requests, mark those two as `disabled`
3. Deploy your app to those two
4. Verify your app as appropraite
5. Mark those two as `enabled`

Then, simply repeat this process for the remaining two.

### Ansible example

Lets write an Ansible playbook to accomplish the steps we outlined above. This example assumes a [Cloud LoadBalancer][2] named `app-lb1` configured with four active web servers.

First we're going to use the [rax_clb][3] module to discover data about the load balancer. We do this by making a call to ensure that `state=present`. This will create the load balancer if it doesn't exist, but thanks to idempotence it will return data about the load balancer if it already exists.

{% highlight yaml %}
- name: Loadbalancer Data Gathering
  hosts: localhost
  gather_facts: no
  connection: local

  tasks:
    - name: discover load balancer details
      rax_clb: name=app-lb1 port=80 protocol=HTTP type=PUBLIC
               state=present wait=true
               credentials=/path/to/credentials
      register: lb
{% endhighlight %}

This task will get the data and [`register`][4] that data in the `lb` variable. To see what kind of data is returned we can use the [`debug`][5] module:

{% highlight yaml %}
- name: debug lb data
  debug: var=lb
{% endhighlight %}

The data we care about is the status of the load balancer and the list of nodes behind the load balancer. Those are `lb.balancer.status` and `lb.balancer.nodes` respectively.

First lets check the health of the load balancer itself and [fail][6] early if the balancer is not healthy:

{% highlight yaml %}
- name: pre-flight lb health check
  fail: msg="Load Balancer not healthy, aborting deployment!"
  when: lb.balancer.status != 'ACTIVE'
{% endhighlight %}

Next lets ensure our nodes are healthy:

{% highlight yaml %}
{% raw %}
- name: pre-flight node health check
  fail: msg="Node {{ item.id }} is not healthy, abording deployment!"
  when: item.condition != 'ENABLED'
  with_items: lb.balancer.nodes
{% endraw %}
{% endhighlight %}

With those pre-flight checks out of the way, we can now create a group of hosts from the nodes. This uses the [add_host][7] module. We will set the name to the node ID then use the `ansible_ssh_host` variable to store the IP address to access them. We'll also set `ansible_ssh_user` to root, and set `lb_id` to the ID of the load balancer, which will use in a later play.

{% highlight yaml %}
{% raw %}
- name: create node host group
  add_host: name={{ item.id }} ansible_ssh_host={{ item.address }}
            ansible_ssh_user=root lb_id={{ lb.balancer.id }}
            groups=web
  with_items: lb.balancer.nodes
{% endraw %}
{% endhighlight %}

Now that we've captured the load balancer data, done our pre-flight checks, and added our nodes we can get on with our deploy. This will be a new play using the group we just created, `web`:

{% highlight yaml %}
- name: Deploy the code
  hosts: web
  gather_facts: no
  connection: ssh
  any_errors_fatal: yes
  serial: 2
{% endhighlight %}

A couple things to call out in this play header. `any_errors_fatal` is a setting that will cause the entire playbook to abort with failure if there are any tasks that fail in this play. We want this instead of the default of only having total failure if **all** the hosts in a play have failures. `serial: 2` is a [setting][8] that alters how Ansible runs hosts through the tasks of the play. In this case, Ansible will take two hosts through each task of the play to completion, then move on to the remaining two. This is how we accomplish the **rolling** part of the update, roll 2, then roll the remaining 2.

Speaking of tasks, lets add them in! Remember we need to set nodes to draining, then wait for the node to finish it's tasks, then disabled, then update the code, and finally re-enable them. We will use the [`rax_clb_nodes`][9] module to do the status manipulation.

{% highlight yaml %}
{% raw %}
  tasks:
    - name: drain the node
      rax_clb_nodes: load_balancer_id={{ lb_id }}
                     node_id={{ inventory_hostname }}
                     condition=draining wait=true
                     credentials=/path/to/credentials
      delegate_to: localhost

    # place holder task to wait for connections to clear
    - name: wait for app connections to close
      command: echo "true"
      register: connections
      until: connections.stdout == "true"
      retries: 20
      delay: 10

    - name: disable the node
      rax_clb_nodes: load_balancer_id={{ lb_id }}
                     node_id={{ inventory_hostname }}
                     condition=disabled wait=true
                     credentials=/path/to/credentials
      delegate_to: localhost

    # place holder task to deploy the code, could be many tasks here
    # including tasks to validate the deploy
    - name: deploy the code
      command: echo "successful deploy"

    - name: re-enable the node
      rax_clb_nodes: load_balancer_id={{ lb_id }}
                     node_id={{ inventory_hostname }}
                     condition=enabled wait=true
                     credentials=/path/to/credentials
      delegate_to: localhost
{% endraw %}
{% endhighlight %}

The use of `delegate_to` in the `rax_clb_nodes` tasks directed Ansible to run the task locally on localhost. This module is designed to interact with the Cloud Load Balancers API, which we want to have happen locally, but with the variable context of the node we are dealing with.

There are a couple of "magic tasks" here. `wait for app connections to close` is doing a simple echo, but here you'll want to make use of a task that is appropriate to your application to ensure you're ready to move it into the disabled state. I've made use of an [until][10] loop here to demonstrate one way that Ansible can wait for a condition to be met before continuing on. The second magic function, `deploy the code` is also a place holder, an exercise left up to the application deployer.

Now that we have our playbook we can run it!

{% highlight bash %}
$ ansible-playbook app-deploy.yaml
{% endhighlight %}

### Final thoughts

I'll repeat the same concerns that Ken did regarding your applications:

1. Does your app have an integrated versioning/cache-busting approach?
2. Are your app-servers stateless or do they require sticky sessions?
3. How do you deploy your app to your app servers?
4. Do you have the ability to roll-back effortlessly?
5. Can your app have different versions served to clients concurrently?

I hope this example of how to accomplish a basic rolling update with Ansible
can start the move to a zero downtime deployment capability. This capability is
a great enabler for your team, ops, devs, product managers, etc.. will all
benefit from the ability to deploy code at any time without interruption.

  [0]: http://developer.rackspace.com/blog/zero-downtime-deployments-with-pkgcloud-and-cloud-load-balancers.html
  [1]: http://www.ansible.com
  [2]: http://www.rackspace.com/cloud/load-balancing/
  [3]: http://docs.ansible.com/rax_clb_module.html
  [4]: http://docs.ansible.com/playbooks_variables.html#registered-variables
  [5]: http://docs.ansible.com/debug_module.html
  [6]: http://docs.ansible.com/fail_module.html
  [7]: http://docs.ansible.com/add_host_module.html
  [8]: http://docs.ansible.com/playbooks_delegation.html#rolling-update-batch-size
  [9]: http://docs.ansible.com/rax_clb_nodes_module.html
  [10]: http://docs.ansible.com/playbooks_loops.html#do-until-loops
