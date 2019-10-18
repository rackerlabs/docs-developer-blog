---
layout: post
title: Ansible and Docker
date: '2015-04-27 10:00'
comments: true
author: Ash Wilson
published: true
categories:
  - ansible
  - docker
---

At first glance, [Ansible](https://www.ansible.com/) and [Docker](https://www.docker.com/) seem to be redundant. Both offer solutions to the configuration management problem through very different means, enabling you to reliably and repeatably manage complicated software deployments. While you certainly can use either on its own with great success, using both together can result in a fast, clean deployment process.

There are two ways that you can combine them, both useful for different reasons. You can use Ansible to orchestrate the deployment and configuration of your Docker containers on the host, or you can use Ansible to construct your Docker container images based on Ansible playbooks as a more powerful alternative to Dockerfiles.

<!-- more -->

<img
  src="{% asset_path 2015-04-27-ansible-and-docker/cow-on-container.jpg %}"
  alt="I'm pretty sure Ansible's EULA requires you to use a picture of a cow somewhere"
  title="I'm pretty sure Ansible's EULA requires you to use a picture of a cow somewhere">

## Deploying Docker containers with Ansible

Docker containers provide a powerful way to deliver a consistent environment for your software, from your laptop to a cluster of production machines, but there are still ample responsibilities left for Ansible to take. Ansible can provision your [servers](https://docs.ansible.com/rax_module.html), your [networks](https://docs.ansible.com/rax_network_module.html), your [load balancers](https://docs.ansible.com/rax_clb_module.html), and [more](https://docs.ansible.com/list_of_cloud_modules.html#rackspace). If the server image you choose doesn't already have Docker installed, you'll need some way to do that. Sometimes, you'll also need to manage the Docker daemon's configuration or tweak [Linux kernel parameters](https://docs.docker.com/installation/ubuntulinux/#adjust-memory-and-swap-accounting).

Most prominently, though, you can use Ansible to manage how and where each of your containers run: image versions, environment variables, volumes and links.

### The Ansible Docker module

Ansible includes a [Docker module](https://docs.ansible.com/docker_module.html) that you use to manage the Docker containers that are active on each host. It supports an intimidating number of module parameters, but you need to know only a few to get started.

The minimum information that you can specify is the name of an image. It's good practice to also be explicit about the desired state, even though there's a default value. I also prefer to name my containers whenever I can, so that (1) the output of `docker ps` is as readable as possible and (2) the container is convenient to reference from other containers and tools later.

```yaml
- name: Database
  docker:
    name: database
    image: postgres:9.4
    state: started
```

This task will pull the latest Postgres image from DockerHub if it isn't present and then launch a single container. However, if any container called "database" is already running on the current host, it won't launch anything.

That's a good starting point. However, if you're shipping code often, your application images will be changing frequently, and this task will never see those updates! To deploy new versions of your software, you'll want to take advantage of the "pull" parameter and the "reloaded" state.

### `pull=always` and `state=reloaded`

These two options, added in the recent Ansible 1.9.0 release, allow you to use the Docker module to deploy containers in a more idempotent fashion. `pull=always` performs a `docker pull` on the server before anything else is done, even if the image is already present -- this lets you be certain that you're running the latest builds of all of your containers. Using `state=reloaded` instead of `state=started` invokes more powerful logic about your container's state: it asserts that, not only is a container with the same *name* (or matching image and command) running, but a container with the same *configuration*. If anything has been changed in the container's image or the settings in your playbook (for example, a new build of the image, a different value for an environment variable, or a redeployed container that was linked to this one) the existing container or containers will be stopped, and new containers will be started with the new configuration. If everything is still the same, though, nothing will be done, and the module will report `changed=false`, like any other well-behaved Ansible citizen.

Using them together lets you keep a container up to date, keep its configuration up to date, and automatically propagate container restarts to any dependent containers. Handy!

```yaml
- name: My application
  docker:
    name: web
    image: quay.io/smashwilson/minimal-sinatra:latest
    pull: always
    state: reloaded
    env:
      SOMEVAR: value
      SHH_SECRET: "{{ "{{ from_the_vault" }} }}"
    link:
    - "database:database"
```

I like to use these parameters on my own application containers, because they change often and because I can be sure I'm writing code that will gracefully handle the occasional restart. It's probably not a good idea to use them on containers that provide infrastructure services, like your database, because you won't want those to restart unless you really need them to!

### `restart_policy=always`

Another important option you should consider using is `restart_policy`, which lets you use Docker as a process supervisor, like upstart, monit, or forever.js. This is important for production environments, because it protects you from seeing extended downtime when you have an uncaught exception somewhere.

You can instruct the Docker daemon to restart your container any time its process terminates by adding the `restart_policy` parameter:

```yaml
- name: My application
  docker:
    name: web
    image: quay.io/smashwilson/minimal-sinatra:latest
    pull: always
    state: reloaded
    restart_policy: always
```

Setting it to `on-failure` allows the container to exit if its process exits cleanly (with a 0 status). If you're concerned about flapping, the number of restarts before Docker will give up can also be controlled by setting `restart_policy_retry` to a nonzero count.

<img
  src="{% asset_path 2015-04-27-ansible-and-docker/cow-in-container.jpg %}"
  alt="[muffled mooing noises]"
  title="[muffled mooing noises]">

## Using Ansible to build Docker images

Most of the time, Dockerfiles are perfectly reasonable for creating Docker container images. For me, most of the benefit of using Ansible is that you can create playbooks that are *idempotent*, which means that when you re-run your playbook, only the tasks that actually require changes have any effect. However, when you're creating a Docker container image, each step is performed from a consistent starting state (in theory, at least!). Also, because the Ansible build is performed as a single "step", delegating image creation to Ansible prevents you from being able to use the build cache purposefully. Managing the build cache is important, because it allows you to keep your image build times short when you're iterating rapidly.

Still, there are several reasons why using an Ansible playbook can be beneficial:

 * If you have existing infrastructure that's already using a pure Ansible approach, it's a simple way to kickstart a migration into containers.
 * Ansible allows you to use Jinja2 templates to create files from templates, enabling you to use variables to reduce duplication and to derive values from the environment.
 * Ansible's [extensive module library](https://docs.ansible.com/modules_by_category.html) helps you to simplify common administrative tasks.
 * You can use roles published on [Ansible Galaxy](https://galaxy.ansible.com/) to benefit from expertise from the community.

To do so, all that you need to do is write a Dockerfile that's based on one of [the official base images](https://github.com/ansible/ansible-docker-base) that ship with Ansible pre-installed and execute `ansible-playbook` with a `RUN` step:

```
FROM ansible/ubuntu14.04-ansible:stable

# Add your playbooks to the Docker image
ADD ansible /srv/example
WORKDIR /srv/example

# Execute Ansible with your playbook's primary entry point.
# The "-c local" argument causes Ansible to use a "local connection" that won't attempt to
# ssh in to localhost.
RUN ansible-playbook site.yml -c local

EXPOSE 443
ENTRYPOINT ["/usr/local/bin/myapp"]
CMD ["--help"]
```

## Onward

We've been using Ansible and Docker together to ship projects like [Cloudpipe](https://github.com/cloudpipe/deploy) and [Deconst](https://github.com/deconst/deploy) and learning more about doing so every day. Both are great tools that let us manage deployments consistently, reliably, and rapidly, using a foundation of descriptive code that's version controlled.

Happy shipping!

----

*Ash is a software developer on Rackspace's Developer Experience team. His interests include programming languages, continuous deployment, and plugging things into other things (we had to cover all the wall sockets). You can follow him [on Twitter](https://twitter.com/smashwilson) or watch him code [on GitHub](https://github.com/smashwilson).*
