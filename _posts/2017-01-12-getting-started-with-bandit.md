---
layout: post
title: Getting started with Bandit
date: 2017-01-16 10:00
comments: false
author: Ian Cordasco
published: true
authorIsRacker: true
categories:
    - security
    - OpenStack
---

One of the many benefits of using and working with Python is its ability to
introspect itself. This empowers us to write and use tools to analyze the
projects we use and write. Tools written in Python can use the built-in `ast`
module to parse and analyze other Python code into an "_A_bstract _S_yntax
_T_ree". Perhaps you've heard of Flake8, PyFlakes, PyLint, Radon, or another
tool that provides style checking, lint discovery, or complexity computation?
They all use the AST to provide that functionality. There's also a tool called
[Bandit][] that uses the AST to provide static security analysis of Python
programs.

<!-- more -->

Starting out with Bandit is simple

```
$ pip install bandit
$ bandit path/to/code/to/check/*.py
```

Bandit scans our files for any known vulnerabilities and then provides us
with explicit feedback about what it found, the severity of the problem, and how
confident it is in its discovery. Let's take a look at an example. Bandit
knows about PyYAML and some of its past security vulnerabilities, so let's
give it example some code that I wrote:

```python
# blog_ex.py
import yaml


def to_yaml(object):
    return yaml.dump(object)


def from_yaml(yaml_str):
    return yaml.load(yaml_str)


yaml_str = to_yaml({
    # Yes, this is some metadata about this blog ;)
    'layout': 'post',
    'title': 'Getting Started with Bandit',
    'date': '2017-01-16 10:00',
    'author': 'Ian Cordasco',
})
parsed_yaml = from_yaml(yaml_str)
```

Running Bandit on this file results in:

```
~/o/bandit ❯❯❯ bandit blog_ex.py
[main]    INFO    profile include tests: None
[main]    INFO    profile exclude tests: None
[main]    INFO    cli include tests: None
[main]    INFO    cli exclude tests: None
[main]    INFO    running on Python 2.7.12
[node_visitor]    INFO    Unable to find qualified name for module: blog_ex.py
Run started:2017-01-11 20:47:39.901651

Test results:
>> Issue: [B506:yaml_load] Use of unsafe yaml load. Allows instantiation of arbitrary objects. Consider yaml.safe_load().
   Severity: Medium   Confidence: High
   Location: blog_ex.py:8
7    def from_yaml(yaml_str):
8        return yaml.load(yaml_str)
9

--------------------------------------------------

Code scanned:
    Total lines of code: 12
    Total lines skipped (#nosec): 0

Run metrics:
    Total issues (by severity):
        Undefined: 0
        Low: 0
        Medium: 1
        High: 0
    Total issues (by confidence):
        Undefined: 0
        Low: 0
        Medium: 0
        High: 1
Files skipped (0):
```

Let's look specifically at the `Test results` section. We see here that
there's an issue labeled `B506` and named `yaml_load`. The message then tells
us what the specific issue is and a potential way to fix it:

```
Use of unsafe yaml load. Allows instantiation of arbitrary objects. Consider
yaml.safe_load().
```

After that message, we are given information about:

1. How severe the issue is - Medium in this case
2. How confident Bandit is that there's a problem - High
3. Where the issue is - in `blog_ex.py` on line number 8
4. And the code in question, complete with line numbers.

If we were certain we wanted to disable this check, we could then "skip" it
by its ID (`B506`) explicitly:

```
~/o/bandit ❯❯❯ bandit -s B506 blog_ex.py
[main]  INFO    profile include tests: None
[main]  INFO    profile exclude tests: None
[main]  INFO    cli include tests: None
[main]  INFO    cli exclude tests: B506
[main]  INFO    running on Python 2.7.12
[node_visitor]  INFO    Unable to find qualified name for module: blog_ex.py
Run started:2017-01-11 20:55:05.987581

Test results:
    No issues identified.

Code scanned:
    Total lines of code: 12
    Total lines skipped (#nosec): 0

Run metrics:
    Total issues (by severity):
        Undefined: 0
        Low: 0
        Medium: 0
        High: 0
    Total issues (by confidence):
        Undefined: 0
        Low: 0
        Medium: 0
        High: 0
Files skipped (0):
```

Further, we're able to store this configuration in a file. If we're using
[tox][] for our project, then we can add the following to our `tox.ini` file:

```
# tox.ini

[bandit]
skips = B506
```

And run

```
~/o/bandit ❯❯❯ bandit --ini tox.ini blog_ex.py
[main]    INFO    Using .bandit arg for skipped tests
[main]    INFO    profile include tests: None
[main]    INFO    profile exclude tests: None
[main]    INFO    cli include tests: None
[main]    INFO    cli exclude tests: B506
[main]    INFO    running on Python 2.7.12
[node_visitor]    INFO    Unable to find qualified name for module: blog_ex.py
Run started:2017-01-11 20:59:08.793653

Test results:
    No issues identified.

Code scanned:
    Total lines of code: 12
    Total lines skipped (#nosec): 0

Run metrics:
    Total issues (by severity):
        Undefined: 0
        Low: 0
        Medium: 0
        High: 0
    Total issues (by confidence):
        Undefined: 0
        Low: 0
        Medium: 0
        High: 0
Files skipped (0):
```

Finally, if our first run of Bandit is giving us a lot of noise, we can filter
by *severity* and *confidence*. It's very reasonable for us to start
addressing only the issues that are the highest severity and the highest
confidence. To see only those, we can run:

```
$ bandit -lll -iii /path/to/code/*.py
```

Providing `-l` increases the minimum severity level and it can be repeated
without having to specify it individually. Likewise, `-i` increases the
minimum confidence level. Specifying each of them three times means we will
only see the issues with `HIGH` severity and confidence.

Finally, it is important to note that Bandit should be installed and run with
the version of Python we're writing for. If our code is using features in
Python 3 only, Bandit should be installed on Python 3 and run from Python 3,
otherwise it may not be able to fully detect problems due to not being able to
parse the files.

[Bandit]: https://pypi.org/project/bandit
[tox]:    https://tox.readthedocs.io/
