---
comments: true
sharing: true
date: 2012-08-28T08:52:28.000Z
layout: post
author: Hart Hoover
title: 'Welcome, Mailgun!'
categories:
  - Mailgun
  - jclouds
  - cloud files
  - java
---



Rackspace has [acquired](http://www.rackspace.com/blog/we-are-acquiring-mailgun/) Mailgun. [Mailgun](http://www.mailgun.com/) simplifies email integration into websites and applications. Developers can easily use their powerful set of APIs to send, receive, and track email effortlessly – without managing an email server or becoming an expert in email setup, operations and deliverability. Mailgun is built for developers. It has server-side MIME assembly, which means that no libraries are required. The service allows you to receive event notifications via a webhook, and everything is priced to scale as you scale.

<!-- more -->

Mailgun also allows you to [track your email responses](http://blog.mailgun.net/post/22292787994/tracking-replies-in-mailgun-or-any-other-email) and parse them for data. You can then use that data to take an action. For example, you can parse an attachment of a video from a mobile user to an email address and post that video on a website or share it on social networks. Developers can also track opens, [unsubscribes](http://documentation.mailgun.net/api-unsubscribes.html), [bounces](http://documentation.mailgun.net/api-bounces.html), and [complaints](http://documentation.mailgun.net/api-complaints.html) using the API. Mailgun makes sure your email gets to the end user's inbox.

Mailgun really shines when using it via the API, but if you are trying to move a legacy application to the cloud you can configure your mail transfer agent (MTA) to relay through Mailgun's service. To set this up in Postfix, add the following settings to /etc/postfix/main.cf:


    mydestination = localhost.localdomain, localhost
    relayhost = smtp.mailgun.org
    smtp_sasl_auth_enable = yes
    smtp_sasl_password_maps = static:postmaster@mydomain.com:password
    smtp_sasl_security_options = noanonymous


You will need to create a mailbox for this as your control panel credentials will not work for relaying mail.

Once you're ready to use the API to send a message, you can add this to your Ruby application:

{% codeblock lang:ruby %}def post_message
  RestClient.post "https://api:key-XXXXXXXXXXXXX"\
  "@api.mailgun.net/v2/mail.domain.com/messages",
  :from => "DevOps Blog ",
  :to => "hart.hoover@rackspace.com, wayne.walls@rackspace.com",
  :subject => "Hello",
  :text => "Testing Mailgun!"
end{% endcodeblock %}

Click [here](http://documentation.mailgun.net/api-intro.html) for more information on the Mailgun API. We're excited to welcome the "Mailgunners" as members of the Rackspace family!
