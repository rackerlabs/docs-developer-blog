---
layout: post
title: Python continuous documentation
date: '2013-05-30 08:00'
comments: true
author: Ian Good
published: true
categories:
  - Python
---

A well-documented Python library is something to be proud of. Reading through
the code, you've got docstrings explaining the various parameters and
constraints around your functions, hopefully using standards like [Sphinx][1]
or [Google][13] formatting. Having to open up the code to find this information
is less than ideal, but it's easy to turn these docstrings into beautiful,
hosted HTML, updated every time you push to GitHub.

We'll be taking advantage of plenty of different technologies to make this
happen:

* [ReadTheDocs][2] manages the builds, versions, and hosts your docs.
* [Sphinx][3] with [autodoc][4] renders your docs.
* [GitHub][5] or [BitBucket][6] hook into ReadTheDocs to trigger builds
  whenever code is commited.

Before we get started, head over to [ReadTheDocs][2] and create an account, if
you don't have one already. It's a free, open-source service. You can even spin
up your own private instances, although their documentation for doing that
isn't the best :)

<!-- more -->

### Setting Up Your Project

#### Installation

As always, I suggest using a [virtualenv][7] for local Python development!
Inside your virtualenv, run:

    pip install sphinx

#### Setup

Create a `doc/` directory in your project, we'll add it to git later:

    mkdir -p doc
    cd doc

Create the basic configuration and file structure:

    sphinx-quickstart

There are several questions I suggest giving a non-default answer to:

    > Separate source and build directories (y/N) [n]: y
    > Project name: yourproject
    > Author name(s): Your Name
    > Project version: 1.2.3
    > autodoc: automatically insert docstrings from modules (y/N) [n]: y
    > intersphinx: link between Sphinx documentation of different projects (y/N) [n]: y

#### Creating the Doc Layout

When running `sphinx-quickstart`, you specified `index.rst` as the starting
point for your documentation pages. With Sphinx, you'll need every page linked
either directly or indirectly from `index.rst` using the `.. toctree::`
directive. Let's consider the following Python package:

    docpkg/__init__.py
    docpkg/main.py
    docpkg/config.py

One package, three modules. Replace your `index.rst` with the following:

    ``docpkg`` Package
    ==================

    .. automodule:: docpkg
       :members:

    -------------------

    **Sub-Modules:**

    .. toctree::

       docpkg.main
       docpkg.config

Now we're going to create two more files, `docpkg.main.rst` and
`docpkg.config.rst`.  I'll give you `docpkg.main.rst`, create
`docpkg.config.rst` the same way:

    ``docpkg.main`` Module
    ========================

    .. automodule:: docpkg.main
       :members:

As you add more modules to your project, they need to be added to the
documentation structure. You can obviously put more than one `.. automodule::`
on a page, at your discretion.

#### Building the Docs Locally

Once you have your doc layout created, you can build your documentation from the
`doc/` directory with:

    make html

Now, just navigate to `doc/build/html/index.html` in your browser!

#### Committing to Git

The entire `doc/` directory tree does not necessarily need to be put into git.
The following should suffice:

    git add doc/Makefile doc/source/conf.py doc/source/*.rst

### Setting Up ReadTheDocs

Once you've created an account and logged in to ReadTheDocs, go to your
Dashboard and click the "Import" button. Most of your choices will depend on
your project, although you will need to set these three options in particular:

* **Repo**: Use the `https://<repo-url>.git` link to your Git repository!
* **Python configuration file**: `doc/source/conf.py`
* **Use virtualenv**: ***&#x2713;***

Once you've created your project, check your Builds tab for failure
information.  It may take some troubleshooting to get a Success, but *usually*
these are solvable with tweaks to your package, for example making sure it
pulls all its own dependencies in correctly.

### Version Control Webhook

Now that you've got your documentation building on ReadTheDocs, you want your
documentation rebuilt as you update your code (and docstrings!). This step is
crucial, don't skip it! If rebuilding your documentation is a manual step, just
admit it, it won't happen often.

Both GitHub and BitBucket have builtin webhooks for ReadTheDocs, under your
project's settings. Just activate them and you're good to go.

For other version control systems, you may need to work something else out. If
you look on your ReadTheDocs project page and find the "Post Build Hook" URL, it
can be hit to trigger documentation rebuilds.

### Frequently Asked Questions

**Q:** How do I link to other projects?

**A:** This is one of my favorite parts of Sphinx, the ability to link
directly to classes, functions, and modules in third-party projects on the
Internet. We can do this because we enabled the `intersphinx` extension, see
[its documentation][8] for its use. You can link to projects hosted anywhere,
not just other ReadTheDocs projects!

**Q:** What happens if my project depends on non-Python code?

**A:** Some projects may require things like C libraries to be installed,
which cannot be brought in automatically with `pip`. The ReadTheDocs build
servers have many of these packages [already installed][9].

**Q:** Does my project meet the requirements?

**A:** If you have a `setup.py` with an `"install_requires"` field to pull in
its own dependencies from [PyPi][10], that should be all you need! If your
project does not have a `setup.py`, it's dependencies can be installed using a
[pip requirements file][11].

**Q:** Is it only for documenting code?

**A:** You can easily add items to your ``.. toctree::`` with anything you
want, such as usage manuals or code samples. Sphinx documentation is built
using their heavily extended [reStructuredText][12] markup, so anything you can
concoct with this powerful syntax is possible.

[1]: http://pythonhosted.org/an_example_pypi_project/sphinx.html#full-code-example
[2]: http://readthedocs.org/
[3]: http://sphinx-doc.org/
[4]: http://sphinx-doc.org/latest/ext/autodoc.html
[5]: https://github.com/
[6]: https://bitbucket.org/
[7]: http://www.virtualenv.org/en/latest/
[8]: http://sphinx-doc.org/latest/ext/intersphinx.html
[9]: http://read-the-docs.readthedocs.org/en/latest/builds.html#packages-installed-in-the-build-environment
[10]: https://pypi.python.org/pypi
[11]: http://www.pip-installer.org/en/latest/requirements.html#requirements-files
[12]: http://sphinx-doc.org/rest.html
[13]: http://google-styleguide.googlecode.com/svn/trunk/pyguide.html?showone=Comments#Comments

