---
comments: true
date: 2012-10-01T16:44:06.000Z
layout: post
title: Using Mailgun and Python to parse email for your applications
author: Hart Hoover
categories:
  - Cloud Servers
  - Mailgun
---

In case you didn't hear, Rackspace recently [acquired Mailgun](https://techcrunch.com/2012/08/28/rackspace-acquires-y-combinator-startup-mailgun-an-api-that-abstracts-creating-email-inboxes-for-apps-and-web-sites/), a YCombinator startup that makes it really easy to integrate email into your application.  Mailgun does the simple things like sending password confirmations and shipping notifications, but it also makes it A LOT easier to build some really good stuff.

Figuring out how to make email work with the cloud is one of the biggest questions that we get at Rackspace, so we're publishing some code samples that show you how to build some really cool things with Mailgun. Mailgun has a [free plan](https://mailgun.com/pricing) that will let you try all these things and send up to 200 emails per day for free. Then they've got plans starting at only $20 a month.  So, onto the cool stuff!

<!-- more -->

### Parsing and posting email messages to your app using Mailgun Routes


Have you ever gotten an email from a social application to notify you of a comment on a thread you're watching, then you had to login to the app to reply?  That is totally unnecessary.

Here's how to integrate email communications into your app seamlessly. Some of the code in this example is written in Python for a Django app, but the same thing is possible in your favorite language (check out the [Mailgun user manual](https://documentation.mailgun.net/user_manual.html#um-routes) for full documentation on parsing and posting emails to your app using Mailgun).

First, you need to decide if you want to filter the emails coming into your app so you only do something for certain incoming emails. Maybe it’s only one kind of email that you want to do something with, like emails asking for support, or emails from a particular person or domain. You can match based on things like recipient or any field in the MIME header of the email.  Here are some examples:

<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">
<tbody>
<tr>
<td>Expression</td>
<td>Description</td>
</tr>
<tr>
<td>match_recipient("bob@myapp.com")</td>
<td>Returns true if the incoming message is going to bob@myapp.com.</td>
</tr>
<tr>
<td>match_recipient(".*@myapp.com")</td>
<td>Returns true if the incoming message is going to any user at @myapp.com.</td>
</tr>
<tr>
<td>match_header("subject", "hello")</td>
<td>Returns true if the subject of the message contains word ‘hello.’</td>
</tr>
<tr>
<td>catch_all()</td>
<td>Returns true if no other route matched, to implement catch-all behavior.</td>
</tr>
</tbody>
</table>

After matching, you need to decide what you want to do. Maybe you don't want to do anything. Or maybe you want to post the email and its contents to your app. These actions are called "routes" (think, I'm routing this email somewhere). There are three actions that you can take based on a match.

<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">
<tbody>
<tr>
<td>Action</td>
<td>Description</td>
</tr>
<tr>
<td>forward(“https://myapp/post”)</td>
<td>Parses the message and forwards it to a given URL.</td>
</tr>
<tr>
<td>forward(“support@myapp.com”)</td>
<td>Forwards the message to a given email address.</td>
</tr>
<tr>
<td>stop()</td>
<td>Stops and doesn’t look at any other routes.</td>
</tr>
</tbody>
</table>

These actions are where the really cool things start to happen. When you forward the email to your app, e.g. forward("support@myapp.com"), you can post to HTTP.  You can post two ways:
	
  * Fully parsed: Mailgun will parse the message, process attachments and attempt to separate quoted parts from the actual message. This is the preferred option.

  * Raw MIME: message is posted as-is. In this case you are responsible for parsing MIME. To receive raw MIME messages, the destination URL must end with mime (e.g. https://myhost/post_mime)


You can then take these difference parts of the parsed message and update your app with the data. The Python code below shows an example of what you would need to do in your Django app to handle the incoming messages:

{% codeblock lang:python %}# Handler for HTTP POST to https://myhost.com/messages for the route defined above
def on_incoming_message(request):
if request.method == 'POST':
sender    = request.POST.get('sender')
recipient = request.POST.get('recipient')
subject   = request.POST.get('subject', '')

body_plain = request.POST.get('body-plain', '')
body_without_quotes = request.POST.get('stripped-text', '')
# note: other MIME headers are also posted here...

# attachments:
for key in request.FILES:
file = request.FILES[key]
# do something with the file

# Returned text is ignored but HTTP status code matters:
# Mailgun wants to see 2xx, otherwise it will make another attempt in 5 minutes
return HttpResponse('OK'){% endcodeblock %}

Mailgun routes are very powerful. For example, you can use regular expression captures and refer to captured values in your destination. With routes, you can also create email addresses (even on the fly) for every user or object or ID in your app to enable very granular behavior. To learn more about Routes, check out the [Routes](https://documentation.mailgun.net/user_manual.html#um-routes) section of the [User Manual](https://documentation.mailgun.net/user_manual.html#user-manual) or contact Mailgun [support](https://mailgun.net/support). The Mailgunners also wrote a [blog post](https://blog.mailgun.net/post/12482374892/handle-incoming-emails-like-a-pro-mailgun-api-2-0) on routes a while ago that has some good additional information. Over the next few weeks we’ll post additional how-tos and sample code, so let us know if there is anything you're wondering how to do!
