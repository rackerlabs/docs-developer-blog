---
layout: post
title: 'How did we serve more than 20,000 IPython notebooks for Nature readers?'
date: 2015-01-28T00:00:00.000Z
comments: true
author: Kyle Kelley
published: true
categories:
  - Python
  - Docker
  - architecture
---

The IPython/Jupyter notebook is a wonderful environment for computations, prose, plots, and interactive widgets that you can share with collaborators. People use the notebook [all](http://blog.quantopian.com/quantopian-research-your-backtesting-data-meets-ipython-notebook/) [over](http://nbviewer.ipython.org/github/GoogleCloudPlatform/ipython-soccer-predictions/blob/master/predict/wc-final.ipynb) [the](https://github.com/facebook/iTorch) [place](http://nbviewer.ipython.org/url/norvig.com/ipython/TSPv3.ipynb) across [many varied languages](https://github.com/ipython/ipython/wiki/IPython-kernels-for-other-languages). It gets used by [data scientists](http://nbviewer.ipython.org/gist/wrobstory/1eb8cb704a52d18b9ee8/Up%20and%20Down%20PyData%202014.ipynb), researchers, analysts, developers, and people in between.

<!-- more -->

As I alluded to in a writeup on [Instant Temporary Notebooks](http://lambdaops.com/ipythonjupyter-tmpnb-debuts/), we (combination of IPython/Jupyter and Rackspace) were prepping for a big demo as part of a [Nature article on IPython Notebooks](http://www.nature.com/news/interactive-notebooks-sharing-the-code-1.16261) by [Helen Shen](https://twitter.com/HelenShenWrites). The impetus behind the demo was to show off the IPython notebook to readers in an interactive format. What better way than to [provide a live notebook server to readers on demand](http://www.nature.com/news/ipython-interactive-demo-7.21492)?

[![Screenshot 2015-01-15 21.17.15.png](https://d23f6h5jpj26xu.cloudfront.net/nvqcj7okftoqw_small.png)](http://img.svbtle.com/nvqcj7okftoqw.png)

To do this, we created a [temporary notebook service](https://tmpnb.org) in collaboration with the IPython/Jupyter team.

### How does this temporary notebook service work?

[tmpnb](https://github.com/jupyter/tmpnb) is a service that spawns new notebook servers, backed by Docker, for each user. Everyone gets their own sandbox to play in, assigned a unique path.

![tmpnb architecture](https://cloud.githubusercontent.com/assets/836375/5909206/f0b156da-a573-11e4-8e3f-f65dfe9d23b8.png)

When a user visits a tmpnb, they're actually hitting an [http proxy](https://github.com/jupyter/configurable-http-proxy) which routes initial traffic to tmpnb's orchestrator. From here a new user container is set up and a new route (e.g. `/user/fX104pghHEha/tree`) is assigned on the proxy.

[![tmpnb-setup.gif](https://d23f6h5jpj26xu.cloudfront.net/z9gjan4yftabyq_small.gif)](http://img.svbtle.com/z9gjan4yftabyq.gif)

## Planning the Notebook Demo

When Brian Granger (Cal Poly) and Richard Van Noorden (Nature) asked for a demo, it was quite open what that could mean. Do we have people log in to a [JupyterHub](https://github.com/jupyter/jupyterhub) installation? Refer them to [Wakari](https://wakari.io/) or [Sage Math Cloud](https://cloud.sagemath.com/)?

The goal that Richard stated was to provide at most 150 concurrent users. In the back of our minds, we (the IPython/Jupyter project) knew that the initial spike in traffic would be far greater and we should be able to handle the load.

I was incredibly lucky to teach at and attend the incredible and crazy event that is the Mozilla Festival. Richard Van Noorden from Nature was in attendance as were my colleagues from the IPython community including [Matthias Bussonnier](https://twitter.com/Mbusson), [Aron Ahmadia](https://twitter.com/ahmadia), and [Jeramia Ory](https://twitter.com/DrLabRatOry). While we were all in one place we swarmed Richard with ideas about what should be in the notebook that Nature readers got to interact with. After the iterations there, pretty soon we had more collaboration from [David Ketcheson, a researcher at KAUST](https://twitter.com/DavidKetch), [Stefan van der Walt, a scikit-image lead](https://twitter.com/stefanvdwalt), and others.

You can tell this is a community with a lot of passion and aligned around a common format that has helped propel their research.

The other crazy benefit about being in London was that I got to go to the Nature offices to talk about the architecture backing the demo and make plans for operations. [Chris Ryan](https://github.com/chris-creditdesign), art editor at Nature, would put an iframe as part of the article in, expanding it into a lightbox for users when they click. For us, this just meant providing them one URL to rely on for content to get served to (as well as adjusting `CSP` or `X-Frame` restrictions).

## Kicking the Nature Notebooks into Operation

On the day of launch, we watched as the notebooks started getting gobbled up and recycled.

After some smooth sailing, we watched as it ticked toward our 512 user mark. After reading comments on various social media sites, we decided to kick it up a notch and allow for 1000s of concurrent users while the demo had initially launched.

This bit us in a couple ways. In order to scale across hosts we'd need to put the proxy and tmpnb in front of multiple docker hosts (note: this is pre-docker [swarm](https://github.com/docker/swarm)). Trying to swap largely untested bits out from underneath in production, while also dealing with the proxy issues did not sound ideal. Instead, [Min RK](https://github.com/minrk) quickly whipped up the tmpnb-redirector which uses the `/stats` endpoint to redirect users to new servers. This made rotating old nodes out easy as well.

![Redirect tmpnb nodes](https://cloud.githubusercontent.com/assets/836375/5913707/3b282e20-a5ae-11e4-9768-c22089b70497.png)

## Closing up

In the end we ended up serving more than 20,000 notebook servers and counting.

We love IPython notebooks, the overall architecture that has been built out here, and hope to keep supporting Open Source projects do interesting things on the internet in a way that benefits community, technology, and the whole ecosystem.
