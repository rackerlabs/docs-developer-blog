---
layout: post
title: "Ansible filter plugins"
date: 2017-12-19 00:00
comments: false
author: Josh Mattson
published: true
authorIsRacker: true
authorAvatar: 'https://www.gravatar.com/avatar/791617263c70278859e1b26c15d13eab'
categories:
    - DevOps
---

[Rackspace Application Services](https://www.rackspace.com/en-us/digital/rackspace-application-services) provides application support and management to a wide variety of customers ranging in size from small environments with only a few application servers to customers that run thousands of Java Virtual Machines (or JVMs) across their environment.  To help facilitate this, we heavily rely on [Ansible](https://www.ansible.com/) to help us automate implementation, troubleshooting, and maintenance tasks.  While Ansible is quite powerful and easy to use, many organizations do not take full advantage of some of the features that it provides.  In this article, we'll be discussing how you can extend Jinja2 and Ansible's built-in [filter plugins](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#filter-plugins) and how you can craft a completely new filter plugin to make specific tasks easier.

<!-- more -->

### Filters basics

Jinja2 comes with a [significant number](https://jinja.pocoo.org/docs/2.10/templates/#builtin-filters) of filters that are, at their core, simply a way to transform data.  Ansible has also extended and expanded upon these filters to perform more common tasks related to systems orchestration and management.

Let's look at a very simple example to illustrate the concept.  Suppose that we have a variable that can be inputted in to one of our playbooks, but this variable may contain leading or trailing whitespace which your playbook needs to account for – perhaps an API key or something that could easily run in to issues if incorrectly copy & pasted when executing the playbook.  We can use the built-in Jinja2 filter `trim` to address this in our template to very quickly strip out all extraneous whitespace:


`api_key: "{{ api_key | trim }}"`

This is obviously a very simple example, but it illustrates the power of filter plugins.

### Creating custom filter plugins

The built-in plugins within Jinja2 and Ansible are all well and good, but we've found situations where we have a much more specific use case.  To use a real world example, we maintain several thousand APM agents for our customers environments, and it can be a challenge to ensure that we are providing timely updates to these agents while being cognizant of customer preferences for timing, change control, and so on.

With these specific agents, the best way to determine the version of the existing agent is to make an API call to the controller and request the agent version.  However, the API will return a string similar to this:

`Server Agent v4.2.0.0 GA #10348 r6cb1b69515a61e8577749ec847709720770f46f3 31-4.2.0.next-build`

Ultimately, when we're recording Ansible facts and using these to determine which agents need to be updated, we only care about the actual version number itself.  Enter a bit of Python for the custom filter plugin, which we simply drop in to the `filter_plugins/` directory in the root of your Ansible repository:


```python
# This filter plugin takes a string from the AppDynamics API and parses out
# the actual version number.  For example, the API might return the following
# version string:
# Server Agent v4.2.0.0 GA #10348 r6cb1b69515a61e8577749ec847709720770f46f3 31-4.2.0.next-build
# Running the 'appd_version_parse' filter on this example will output:
# 4.2.0.0

class FilterModule(object):

    def filters(self):
        return {
            'appd_version_parse': self.appd_version_parse,
        }

    def appd_version_parse(self, string):
        import re
        version_search = re.search(r'v(\d[^\s]+)', string, re.M|re.I)
        if not version_search:
            raise AppDynamicsVersionFormat("{} isn't a valid AppDynamics version string.".format(string))
        return version_search.group(1)

class AppDynamicsVersionFormat(Exception):
    pass
```

If you're unfamiliar with Python, all we're doing here is declaring a new FilterModule class that performs a simple regex evaluation on a string and, assuming it is correctly recognized as a valid AppDynamics agent version string, returns our nicely formatted version string.

To see our custom filter plugin in action, here is how we use it in our playbook.  After making our API call to get all agent versions and storing it in a dictionary, we iterate through the dictionary for each agent to grab the raw output and pass it through this filter just as if we were using a built-in filter:

`{{ item.appAgentVersion | appd_version_parse }}'

### Final thoughts

Custom filter plugins provide a very powerful and, most importantly, repeatable way for you to manipulate data that you frequently have to with.  For a final example, prior to Ansible 2.4, Ansible had no way to convert from epoch time to human readable.  At the time, we were running Ansible 2.2 but this was a need that we had to record facts around installation times, maintenance execution times, etc.  Here is another simple fliter plugin that will convet epoch time to human readable format to further illustrate the concept:

```python
# This filter plugin will convert epoch time to human readable
# in the format of '%Y-%m-%d' (i.e. 2017-05-31).  Ansible does not
# have this functionality until version 2.4 when they will implement the
# strftime filter

class FilterModule(object):

    def filters(self):
        return {
            'epoch2date': self.epoch2date,
        }

    def epoch2date(self, value):
        import time
        return time.strftime('%Y-%m-%d', time.localtime(value))
 ```
