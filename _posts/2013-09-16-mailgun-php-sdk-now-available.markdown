---
layout: post
title: Mailgun PHP SDK now available
date: '2013-09-16 13:33'
comments: true
author: Michael Ferranti
published: true
categories:
  - Mailgun
  - SDK
---
At Rackspace, we've been putting a lot of work into SDKs lately. Recently the
team at Mailgun joined the SDK club and released an officially supported SDK for
PHP.  They are also working on SDKs for additional languages like C#, Ruby and
Python which are coming soon.

In addition to providing a way to interact with the Mailgun API, the PHP SDK has
a few really cool utilities that make it way easier to do some common, but
complex tasks.

<!-- more -->

You can check out the full post about the SDK over on the [Mailgun blog][1],
but here is one example of what you can do:

### Registering your users for a mailing list

One of the most common ways to communicate with customers is through mailing
lists.  Properly managing those mailing lists can be a pain through, from
validating the users email, to managing double-opt and unsubscribes there is a
lot to manage and a lot of code to write.  The Mailgun PHP SDK does all that,
including using their new [free address validation service][2] to validate the
accuracy of the email addresses.

The typical flow for using this *Opt-in* handler class would be as follows:

**Recipient Requests Subscribe** -> [Validate Recipient Address] -> [Generate Opt In Link] -> [Email Recipient Opt In Link]

**Recipient Clicks Opt In Link** -> [Validate Opt In Link] -> [Subscribe User] -> [Send final confirmation]

It is best to use this class for your website subscription forms, so you need a
web server accessible to the internet to handle the validation link click.

For more details check out the the full blog on [Mailgun.com][3].  And if you
didn't already know, remember that Rackspace customers can use Mailgun for free,
up to 50,000 emails per month.  Just click on the **More** link in the Rackspace
Cloud Control Panel, then select **Mailgun**.


  [1]: http://blog.mailgun.com/post/the-php-sdk-the-first-of-many-official-mailgun-sdks/
  [2]: http://blog.mailgun.com/post/free-email-validation-api-for-web-forms/
  [3]: http://www.mailgun.com/
