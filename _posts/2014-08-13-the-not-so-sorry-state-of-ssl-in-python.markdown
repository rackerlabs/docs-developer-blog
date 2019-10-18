---
layout: post
title: The not-so-sorry state of SSL in Python
date: 2014-08-13T00:00:00.000Z
comments: true
author: Alex Gaynor and David Reid
published: true
categories:
  - python
  - security
---
### Introduction
TLS and SSL are two critical technologies which underly much of the secure
communications that occur on the internet. Over the past few years, spurred by
increasingly effective attacks and a desire for new functionality, SSL and TLS
have seen many new features, as well as practical improvements.

Python is currently in a transitional period between Python 2 and Python 3. For
the past few years, all new feature development has been happening on Python 3,
including new features in Python's `ssl` module. This means that Python 3 users
have had acccess to these improvements to TLS, but Python 2 users (still the
majority of Python users) have been falling behind.

<!-- more -->

Unfortunately, missing features in an SSL/TLS stack aren't like missing
features in other modules. They can prevent interoperability with the wider
internet, compromise the security of connections, and there's usually no
workaround. To get a sense of how bad this situation is, you can watch [Hynek
Schlawack's talk on "The Sorry State of SSL" from
PyCon](https://hynek.me/talks/tls/).

### Current State and Requirements
This situation is unacceptable, given that Python 2 is going to continue to see
production usage for many years to come. As a result, we advocated strongly for
[PEP 466](https://legacy.python.org/dev/peps/pep-0466/), which provides
permission to backport many of these improvements to Python 2.

A few of the important features missing from Python 2 are:

1. `NPN`/`ALPN` support. NPN (Next Protocol Negotiation) was a TLS extension
   originally [introduced by
   Google](https://technotes.googlecode.com/git/nextprotoneg.html), which
   allows a connection to negotiate which application-level protocol will be
   used, it is currently in the process of being supplanted by ALPN
   (Application Level Protocol Negotiation), which is an IETF draft. These are
   necessary for protocols such as [SPDY](https://en.wikipedia.org/wiki/SPDY)
   and [HTTP/2](https://en.wikipedia.org/wiki/HTTP_2.0). (ALPN is not yet in
   Python, because it's not yet in an OpenSSL releases, once it is the feature
   will be added).
2. SNI support. SNI (Server Name Indication) is another TLS extension, which
   allows a server to support multiple hostnames on a single IP address. This
   is necessary because of the shrinking supply of IPv4 addresses and
   increasing desire to run distributed CDNs which serve multiple hostnames.
3. Hostname verification support. Part of the process for correctly
   implementing a TLS client is verifying that the certificate it presents has
   a hostname which matches the one you intended to request. Without this
   support, TLS connections are vulnerable to Man-In-The-Middle attacks.
4. Locating platform trust roots. With this Python is able to use your
   Operating System's provided set of Certificate Authorities for verifying the
   certificates of TLS servers.
5. Improved cipher suites. Previously Python used OpenSSL's default cipher suite
   list, which is unfortunately insecure. It includes several weak ciphers, and
   does not correctly prioritize the strongest ciphers.
6. ECDHE and DHE support. ECDHE (Elliptic Curve Diffie-Hellman Ephemeral) and
   DHE (Diffie-Hellman Ephemeral) provide a property called "Perfect Forward
   Secrecy", which means that even if the server's private key is compromised
   the plaintext of sessions *before* the compromise are still secret.
7. Any configurability. It's impossible to disable TLS compression (to prevent
   the [CRIME](https://en.wikipedia.org/wiki/CRIME)) attack, or configure which
   versions of the SSL/TLS protocol should be used.

### Work, Solutions and Issues
To address this, we backported each of these features from the Python 3 branch
to the Python 2 branch. This was a large task, because it is a huge amount of
code (the resulting diff is over 12,000 lines), written for two different
programming languages, with some very fundamental differences.

Our first step was to take a diff of the files that comprise the SSL module
between Python 2 and Python 3. Then, we applied this diff, using a graphical
merge tool and throwing away changes that were incorrect, or introduced
backwards incompatibilities.

Then we made sure all of the code compiled, fixing syntax errors, and API
differences between Python 2 and Python 3. And finally we ran the tests and
made fixes as necessary until all of them were passing.

A few of the issues we ran across were:

1. Missing functions in the C API, such as `PyUnicode_FSConverter`.
2. Usage of stdlib modules, such as `enum`, which didn't exist in Python 2.
3. Differences between the handling of `str`, `bytes`, and `unicode`.
   Particularly, existing Python 3 code was very strict about text vs. bytes in
   a way that often wasn't possible to emulate in Python 2.
4. The `ssl` module is deeply coupled to the `socket` module, and many of the
   internals of the `socket` module were changed in Python 3 to fully
   participate in [PEP 3116](https://legacy.python.org/dev/peps/pep-3116/).
5. Most of the code for the `ssl` module is written in C, rather than in
   Python. C code is considerably more difficult to work with than Python code,
   while all of the Python-code differences were easy to work around, the C API
   differences required considerably more work.

### Rackspace
This work is important to Rackspace for several reasons:

1. Rackspace uses a lot of Python. Between OpenStack, other open source Python
   projects, and internal tooling, Rackspace is powered by Python. Keeping our
   own code secure is a very important priority.
2. Many of Rackspace's customers use Python, including to orchestrate
   Rackspace's APIs, Keeping those connections secure is important.
3. Features like NPN, ALPN, SNI, and Perfect Forward Secrecy are vital for the
   health and continued growth of the internet. Developers' access to and
   adoption of these technologies in Python, whether for use with Rackspace or
   not, is critical.

### Closing Thoughts
The patch with our work is currently in code review, and we're hoping it will
be merged soon, for release in Python 2.7.9. One of our goals in working on
this patch was to reduce the maintenance burden going forward, by minimizing
the delta with Python 3. When new features like ALPN are added to Python 3,
they should be much easier to backport to Python 2 than this was.
