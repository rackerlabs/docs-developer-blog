---
comments: true
date: 2012-10-30T14:07:50.000Z
layout: post
title: Send emails using Mailgun from your Capistrano recipes
author: Hart Hoover
categories:
  - Mailgun
---

The guys over at Mailgun just posted an overview of how to use Mailgun to power email notifications from your Capistrano recipes. We've got a lot of customers using Capistrano to automate their big web deployments, so we thought we'd share a summary. You can read the full post on the [Mailgun blog](https://blog.mailgun.com/using-mailgun-with-capistrano-recipes/).

<!-- more -->

If you're using Capistrano, you can use this code, written by Spike Grobstein, Mailgun customer and Senior DevOps Engineer at [Ticket Evolution](https://ticketevolution.com/), to automatically send a notification after deployment ([here's the Github code](https://github.com/spikegrobstein/capistrano-mailgun)). Just add the following to your deploy.rb file:

{% codeblock lang:ruby %}
set :mailgun_api_key, 'key-12345678901234567890123456789012' # your mailgun API key
set :mailgun_domain, 'example.com' # your mailgun email domain
set :mailgun_from, 'deployment@example.com' # who the email will appear to come from
set :mailgun_recipients, [ 'you@example.com', 'otherguy@example.com' ] # who will receive the email

# create an after deploy hook
after :deploy, 'mailgun_notify'{% endcodeblock %}

That's it. When you deploy, it should automatically send an email using the built-in text and HTML templates. You can also send emails that include more sophisticated variables, create different notification emails for different mailing lists (e.g. developers@awesomesauce.com or qa@awesomesauce.com) or customize the emails. [Grab that code on Github](https://github.com/spikegrobstein/capistrano-mailgun).

I hope this makes managing epic deployments a little easier for you!
