---
layout: post
title: "Unlocking new capabilities with Syntribos 0.5.1"
date: 2018-04-13 00:00
comments: false
author: Michael Dong
published: true
authorIsRacker: true
categories:
    - Openstack
---

It has been a while since the last official release of Syntribos - a whole
year, in fact! But we haven't been sitting idle. This article explores the new
capabilities offered by this latest release.

<!-- more -->

### What is Syntribos?

Syntribos is an open source automated API security testing tool that is
maintained by members of the
[OpenStack Security Project](https://wiki.openstack.org/wiki/Security-SIG).

Given a simple configuration file and a set of template HTTP requests, Syntribos
generates and sends new requests that substitute parameters in the template with
common attack payloads. The tool aims to automatically detect common security
defects such as SQL injection, LDAP injection, buffer overflow, and so on. In
addition, it can be used to help identify new security defects by automated
fuzzing.

Although Syntribos ships with request templates and extensions that make it easy
to test OpenStack applications, Syntribos is versatile enough to test any API.

At Rackspace, and previously under OSIC, our security teams have been using
Syntribos to test a variety of APIs, both OpenStack and non-OpenStack. It has
become an invaluable part of our toolset to keep the cloud secure. Already,
Syntribos has been used to detect vulnerabilities before releases were launched.

### New in Syntribos

Recently, we released Syntribos 0.5.1, which comes with significant usability
and performance improvements. These enhancements were based, in large part, on
feedback from Rackspace security engineers, who have been using Syntribos for
their API security testing needs on a variety of projects. We hope that these
changes make Syntribos better suited to your testing needs as well.

#### Multithreading

One of the biggest pain points that testers had when using Syntribos was its
performance. Because Syntribos serialized its requests, a full run on a large
project running on a remote host could sometimes take hours. In Syntribos 0.5.1,
we have made wholesale changes to the runner, allowing a configurable number of
workers to send requests in parallel. In practice, this offers a dramatic
improvement in performance.

The following before and after results show the significant speed increase that
the new multi-threaded runner in Syntribos 0.5.1 achieves when compared to the
Syntribos 0.3.1 release. These tests were run against a small API with ~50ms
network lag.

*Syntribos 0.3.1 test*

     ============================================
     Total: Ran 2655 tests in 349.914s
     Total: 6 unique failures and 0 unique errors
     ============================================

*Syntribos 0.5.1 test*

     ============================================
     Total: Ran 2655 tests in 78.639s
     Total: 6 unique failures and 0 unique errors
     ============================================

Of course, this behavior is fully configurable with command line options or
configuration file parameters, in case you are testing against rate-limited
endpoints or endpoints that do not handle concurrent connections well.

#### Template meta-variables

Request templates in Syntribos have always had the advantage of being very
similar to raw HTTP requests, which makes it easy for testers to create them
for a project. Syntribos 0.3.1 had the following shortcomings:

- The template creation process usually involved a fair bit of tedious
  copy-and-pasting, even on attributes that are shared across templates. That
  means any changes to a group of templates required the user to open the
  templates individually and edit them one-by-one - a slow, manual process that
  was prone to mistakes.

- To allow request templates to take full advantage of Syntribos' extensions or
  any other external libraries, they had to be cluttered with long, ugly
  `CALL_EXTERNAL` directives.

- The request templates could only hold a limited amount of information.
  Syntribos treated nearly every part of the template identically, and there was
  no way for the user to specify, for example, that specific fields should be
  fuzzed only with URL-encoded characters, or with strings of a certain length.

To solve these problems, we introduced the concept of meta-variables.
Meta-variables are JSON objects that are stored in separately from the request
templates file and that define reusable variables, which can be referenced in
request template parsing.

Any number of request templates can reference these meta-variables, and the
meta-variables can even inherit values from other meta-variable files based on
the directory where they are stored.

The following examples demonstrate the differences between the old and new
Syntribos releases.

##### Syntribos 0.3.1 template example

The following example (`post_image.template`) demonstrates template meta-variable use:

    POST /v2/images HTTP/1.1
    X-Auth-Token: CALL_EXTERNAL|syntribos.extensions.identity.client:get_token_v2:["user"]|

    {
        "name": "Test",
        "id": "CALL_EXTERNAL|syntribos.extensions.random_data.client:get_uuid:[]|"
        ...
    }

**Note** Because Syntribos is fully backward-compatible, you can use this request
template as-is with Syntribos 0.5.1.

With Syntribos 0.3.1, a change like adjusting the `x-auth-token` header for
multiple templates requires manually updating each template individually.

Passing information to Syntribos 0.3.1 to assist API validation is not possible.
For example, if the API accepts only ASCII characters for the `name` in the
request body, Syntribos 0.3.1 has no way to pass that information.

Syntribos 0.3.1 code is not very pretty to look at, and you just have to
live with it.

#### Syntribos 0.5.1 template example

With Syntribos 0.5.1, meta-variable files allow you to create a file,
`meta.json`, in the same directory as your template, like the following example:

    {
      "token": {
        "type": "function",
        "val": "syntribos.extensions.identity.client:get_scoped_token_v3",
        "args": ["user"]
      },
      "id": {
        "type": "function",
        "val": "syntribos.extensions.random_data.client:get_uuid"
      },
      "name": {
        "val": "Test"
        "fuzz_types": ["ascii"]
      }
    }

Using the `meta.json` file, the template now looks like the following example:

    POST /v2/images HTTP/1.1
    X-Auth-Token: |token|

    {
        "name": "|name|",
        "id": "|id|"
        ...
    }

Now, your templates are simplified while containing more information. And of
course, you can reference all those variables defined in `meta.json` in your
other request templates as well.

For more detailed information on meta-variables, see
[https://docs.openstack.org/syntribos/latest/test-anatomy.html#meta-variable-file](https://docs.openstack.org/syntribos/latest/test-anatomy.html#meta-variable-file).

### What's next?

We have big plans ahead for Syntribos, including the following:

- Enable Syntribos to understand context beyond a single request, allowing more
  complex tests that create, modify, and clean up a resource.

- Make Syntribos more CI/CD friendly.

- Explore ways to integrate Syntribos into gate jobs and build pipelines.

- Work on improvements to the test cases themselves, as well as to the documentation
  so that Syntribos is more accurate and user-friendly.

If you have any questions about Syntribos, we are available at #openstack-security
on freenode. User feedback is very important to us as we continue development,
and we'd love to hear from you!

