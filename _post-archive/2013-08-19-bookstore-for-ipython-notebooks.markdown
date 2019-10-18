---
layout: post
title: Bookstore for IPython Notebooks
date: '2013-08-19 08:08'
comments: true
author: Kyle Kelley
published: true
categories:
  - Cloud Files
  - OpenStack
  - Python
---

{% img 2013-08-19-bookstore-for-ipython-notebooks/IPy_header.png 'IPython logo' 'IPython logo' %}

If there is anything I love about the Python ecosystem, it's the scientific computing ecosystem. Standing on top of this stack for me is [IPython](https://ipython.org/), a robust tool for interactive computing. It has features like a simple navigable history, auto-completion, a brilliant [web based notebook](https://ipython.org/notebook.html) with inline plotting, an easy to use [parallel computing framework](https://ipython.org/ipython-doc/stable/parallel/parallel_intro.html), [magic](https://ipython.org/ipython-doc/stable/interactive/tutorial.html), and a well structured protocol that is being used to extend IPython for interactive computing with [other](https://github.com/minrk/iruby) [languages](https://nbviewer.ipython.org/4279371/node-kernel.ipynb) including [Julia](https://github.com/JuliaLang/IJulia.jl). If you haven't heard of IPython before, I recommend you watch [Fernando Perez's keynote talk on IPython](https://vimeo.com/63250251) from PyData Silicon Valley 2013.

<!-- more -->

As mentioned above, IPython contains a web based notebook for interactive computing called the IPython notebook. If you've ever used Mathematica, you'll feel right at home. IPython notebooks provide an easy way to interactively work with your code and data, all while visualizing and prototyping to your heart's content. Output goes [well beyond simple text](https://ipython.org/ipython-doc/dev/config/integrating.html) and plots, by allowing you to define a `_repr_html_` method on objects that outputs HTML. Pandas, in particular, allows their DataFrames to render as clean HTML tables embedded right alongside the rest of the code:

[{% img 2013-08-19-bookstore-for-ipython-notebooks/ipython_basemap.png 'Notebook example' 'Notebook example' %}](https://nbviewer.ipython.org/urls/bitbucket.org/hrojas/learn-pandas/raw/65203d891b5e20bb7c00628332694a612bcb54ee/notebooks/Basic_Basemap.ipynb)

Each cell allows you to write Python, run a computation, view results, and plot data like a typical [Read-eval-print loop (REPL)](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop). Unlike a typical REPL though, you can easily go back and edit your previous code. Cells can also be Markdown, headings, raw text and even display <span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">L<span style="text-transform: uppercase; font-size: 70%; margin-left: -0.36em; vertical-align: 0.3em; line-height: 0; margin-right: -0.15em;">a</span>T<span style="text-transform: uppercase; margin-left: -0.1667em; vertical-align: -0.5ex; line-height: 0; margin-right: -0.125em;">e</span>X</span>. This allows you to [create a narrative alongside your code](https://nbviewer.ipython.org/urls/raw.github.com/jakevdp/jakevdp.github.com/master/downloads/notebooks/sparse-graph.ipynb), useful for teaching and presenting. The [example below](https://nbviewer.ipython.org/urls/raw.github.com/jakevdp/jakevdp.github.com/master/downloads/notebooks/sparse-graph.ipynb) comes from [Jake Vanderplas' Python Perambulations blog](https://jakevdp.github.io/blog/2012/10/14/scipy-sparse-graph-module-word-ladders/).

{% img 2013-08-19-bookstore-for-ipython-notebooks/ipython_words.png 'IPython cells' 'IPython notebook cell example' %}

The greatest feature of the notebook is the ease at which you can share notebooks with others. This allows them to run through your code (👍 for reproducibility), change it locally, and see results for themselves. By default the notebooks are stored in the same directory IPython was invoked from and have a file extension of `.ipynb`. The easiest way to share them has been to put the notebook file on the web, through a GitHub Gist or in a GitHub repo, then link to it through the [notebook viewer](https://nbviewer.ipython.org/).

There's another way to store and save these notebooks now, using OpenStack Swift or Rackspace CloudFiles: [Bookstore](https://github.com/rgbkrk/bookstore).

# Bookstore

[Bookstore](https://github.com/rgbkrk/bookstore) allows you to save your IPython notebooks to OpenStack Swift or CloudFiles, seamlessly, while interacting with the notebook. You can even CDN enable your notebooks so they can be downloaded or [viewed by others](https://nbviewer.ipython.org/).

Install bookstore via pip

```bash
$ pip install bookstore
```

Then add bookstore to your IPython configuration

{% codeblock ipython_notebook_config.py lang:python %}
# Setup IPython Notebook to write notebooks to CloudFiles
c.NotebookApp.notebook_manager_class = 'bookstore.cloudfiles.CloudFilesNotebookManager'

# Set up your user name and API Key
c.CloudFilesNotebookManager.account_name = 'USER_NAME'
c.CloudFilesNotebookManager.account_key = 'API_KEY'

# Container on CloudFiles
c.CloudFilesNotebookManager.container_name = u'notebooks'

# Optionally, the region
c.CloudFilesNotebookManager.region = u'DFW'
{% endcodeblock %}


Your API Key is located in *Settings and Contacts* within the Cloud Control panel, underneath the security question.

{% img 2013-08-19-bookstore-for-ipython-notebooks/API_Key.png 'API Key location' 'The API Key is located in Settings and Contacts' %}

*Note: if you're using Rackspace UK, set region to `'LON'`.*

This code just needs to be added to your IPython configuration. Your default configuration is at `~/.ipython/profile_default/ipython_notebook_config.py`. If you want it in a separate profile just run

```bash
$ ipython profile create demo_name
```

and add the profile option when invoking the notebook

```bash
$ ipython notebook --profile=demo_name
```

Once configured, the IPython notebook will behave the same on the frontend but no `.ipynb` files will be created on your local box.

## Launching the Notebook

Now launch the IPython notebook with the profile you configured (default used below)

```bash
$ ipython notebook
2013-08-14 11:18:16.513 [NotebookApp] Using existing profile dir: u'/Users/kyle6475/.ipython/profile_default'
2013-08-14 11:18:28.667 [NotebookApp] Using MathJax from CDN: https://cdn.mathjax.org/mathjax/latest/MathJax.js
2013-08-14 11:18:28.676 [NotebookApp] Serving rgbkrk's notebooks on Rackspace CloudFiles from container notebooks_demo in the DFW region.
2013-08-14 11:18:28.676 [NotebookApp] The IPython Notebook is running at: https://127.0.0.1:4242/
2013-08-14 11:18:28.676 [NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
```

If you've configured it correctly, notebooks will be listed and read directly from CloudFiles.

{% img 2013-08-19-bookstore-for-ipython-notebooks/notebook_list.png 'Notebook List' 'List of IPython Notebooks' %}

It's worth noting that saving will certainly be a little slower than interacting with your local filesystem, since it has to send the whole ipynb document to CloudFiles. If your IPython notebook server is running in the same data center though, this time difference may not be noticeable.

Bookstore was built with OpenStack in mind so you can [store your notebooks on your own OpenStack Swift cluster](https://github.com/rgbkrk/bookstore#on-openstack-swift-using-keystone-authentication) (if it uses Keystone authentication -- no support for swauth yet).

## Storage

Notebooks are stored by a UUID and checkpoints are stored relative to that UUID.

    {notebook_id} # Notebook itself
    {notebook_id}/checkpoints/{checkpoint_id} # Checkpoints for that notebook

They should look like this within CloudFiles

{% img 2013-08-19-bookstore-for-ipython-notebooks/nb_storage.png 'Notebooks as UUIDs' 'Notebooks are stored using a UUID' %}

Currently only single checkpoints are stored, but multiple checkpoints will be enabled for [future versions of IPython and Bookstore](https://github.com/ipython/ipython/pull/3939). As IPython advances, this setup for saving will likely change as [multi-directory notebooks get implemented](https://github.com/ipython/ipython/pull/3619).

## CDN Enabling Containers

You can also CDN Enable your notebooks for wider dissemination. From the control panel for CloudFiles click the gear icon next to your container then click "Make Public (Enable CDN)".

{% img 2013-08-19-bookstore-for-ipython-notebooks/cdn_enable.png 'CDN Enable' 'CDN Enable a Container' %}

Once that's finished, click the container then view all links

{% img 2013-08-19-bookstore-for-ipython-notebooks/view_all_links.png 'view all links' 'View all links for the container' %}

Which leads to

{% img 2013-08-19-bookstore-for-ipython-notebooks/cdn_links.png 'CDN Links' 'CDN Links' %}

These links are the base links for the container. Put the UUID for a notebook after the HTTP or HTTPS urls to reach that specific notebook. Within the IPython notebook, the URL shows the UUID for a notebook at the very end.

{% img 2013-08-19-bookstore-for-ipython-notebooks/notebook_url.png 'Notebook UUID in URL' 'Notebook UUID in URL' %}

As an example, the URL for the container used above is https://504a2743e3ef413d3f50-f754606aafcd7bad1b04f6d0cd003745.r33.cf1.rackcdn.com. The notebook above can then be reached at

[https://504a2743e3ef413d3f50-f754606aafcd7bad1b04f6d0cd003745.r33.cf1.rackcdn.com/77ba6f19-de0e-469f-8bad-76d675222b31](https://nb.fict.io/77ba6f19-de0e-469f-8bad-76d675222b31)

Couple this with a CNAME for the container (using the HTTP link) through Rackspace's DNS (or your own DNS)

{% img 2013-08-19-bookstore-for-ipython-notebooks/add_cname.png 'Add' 'Add CNAME' %}

To make simplified links like [https://nb.fict.io/77ba6f19-de0e-469f-8bad-76d675222b31](https://nb.fict.io/77ba6f19-de0e-469f-8bad-76d675222b31) and you'll have a shorter URL for [sharing through the nbviewer](https://nbviewer.ipython.org/url/nb.fict.io/77ba6f19-de0e-469f-8bad-76d675222b31).

## Beneath the covers

Bookstore extends the `NotebookManager` class from [IPython.html.services.notebooks.nbmanager](https://github.com/ipython/ipython/blob/master/IPython/html/services/notebooks/nbmanager.py) by simply overriding reading, writing, listing, and deleting both notebooks and checkpoints while conforming to the NotebookManager interface. The IPython team did an excellent job making it easy to extend from. All the generic OpenStack Swift code for manipulating the notebooks as objects is handled by a [`SwiftNotebookManager`](https://github.com/rgbkrk/bookstore/blob/master/bookstore/swift.py#L68) which is extended by the two classes that handle the current authentication types [`KeystoneNotebookManager`](https://github.com/rgbkrk/bookstore/blob/master/bookstore/swift.py#L320) for OpenStack Keystone authentication and [`CloudFilesNotebookManager`](https://github.com/rgbkrk/bookstore/blob/master/bookstore/cloudfiles.py#L38) for Rackspace authentication.

[Pyrax](https://github.com/rackspace/pyrax) does all the heavy lifting when working with Swift ([python-swiftclient](https://github.com/openstack/python-swiftclient) under the hood), allowing bookstore to work with Python objects rather than primitive types.

# Closing up

IPython notebook is a wonderful tool for interactive computing. I'm really happy we have a way to save our notebooks automagically, publish them on the CDN, and provide nbviewer links.

Happy Computing!

# About the Author

Kyle Kelley is a Developer Support Engineer at Rackspace. You can follow him on twitter [@rgbkrk](https://twitter.com/rgbkrk).
