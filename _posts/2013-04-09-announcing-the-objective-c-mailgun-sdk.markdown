---
layout: post
title: Announcing the Objective-C Mailgun SDK
date: '2013-04-09 12:26'
comments: true
author: Jay Baird
published: true
categories:
  - Mailgun
---
One of my favorite services here at Rackspace is [Mailgun](http://mailgun.com),
a set of APIs that allow you to send email and manage mailing lists via a REST
API. Coming back from a recent trip to San Antonio I decided that I would add an
Objective-C interface to send email via Mailgun using my own iOS interface
instead of using Apple's `MFMailComposeViewController`. This library is now
[open sourced on Github](https://github.com/rackerlabs/objc-mailgun) and available
via [Cocoapods](http://cocoapods.org).<!-- more -->

### Install the Mailgun SDK

To install the Mailgun SDK, you can either use the fantastic
[Cocoapods](http://cocoapods.org) or install directly from the source by adding
the `Mailgun.(h|m)` and `MGMessage.(h|m)` to your Xcode project. If you choose
to install manually you will also need to follow the instructions to install
the [AFNetworking](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking)
library.

### Use the Mailgun SDK

Currently the only functions of the Mailgun API the SDK supports are sending
e-mail, subscribing to mailing lists and unsubscribing to mailing lists. I felt
that these are the most common features an app developer would use but more
features of the Mailgun API will be added in the future. Full Documentation for
the library can be found in the
[Docs directory on Github](https://github.com/rackerlabs/objc-mailgun/tree/master/Docs)
 or on [cocoadocs.org](http://cocoadocs.org).

### Send a message

To quickly send a message via the Mailgun SDK, create a client using the Class
method `clientWithDomain:apiKey:` the arguments to this method being your specific
 Mailgun domain and API key. This example uses `samples.mailgun.org` and
 `key-3ax6xnjp29jd6fds4gc373sgvjxteol0`.

    Mailgun *mailgun = [Mailgun clientWithDomain:@"samples.mailgun.org" apiKey:@"key-3ax6xnjp29jd6fds4gc373sgvjxteol0"];

Message sending can happen in several ways. You can use the instance method
`sendMessageTo:from:subject:body` to quickly fire off a simple, "one off" message
like so:

    [mailgun sendMessageTo:@"Jay Baird <jay.baird@rackspace.com>"
                      from:@"Excited User <someone@sample.org>"
                   subject:@"Mailgun is awesome!"
                      body:@"A unicode snowman for you! ☃"];

You can also construct a more featureful message using the `MGMessage` object.
The following example creates an `MGMessage` object with an image attachment of
a cat because the Internet exists solely to proliferate pictures of cats, and
sends it via the SDK:

    UIImage *catImage = [UIImage imageNamed:@"cat-pic-01"];
    MGMessage *message = [MGMessage messageFrom:@"Excited User <someone@sample.org>"
                                             to:@"Jay Baird <jay.baird@rackspace.com>"
                                        subject:@"Mailgun is awesome!"
                                           body:@"Mailgun is great, here is a picture of a cat."];
    [message addImage:catImage withName:@"cat-pic-01" type:PNGFileType];

This attaches a `UIImage` to the `MGMessage` that was created. The data from
the `UIImage` is added as an attachment to the message.

*An identical interface exists for OS X that takes an `NSImage` and a `NSBitmapImageFileType`.*

Once your message is constructed, you can add recipients by using the
`addRecipient:` method and add CC and BCC recipients by using `addCC:` and
`addBCC:`. You can also add [tags](http://documentation.mailgun.net/user_manual.html#tagging),
variables and a whole host of other features supported by the
[Mailgun API](http://documentation.mailgun.net/user_manual.html#sending-messages).
[Take a look at the header](https://github.com/rackerlabs/objc-mailgun/blob/master/Classes/MGMessage.h)
of `MGMessage.h` to see everything that is supported.

To send this specially constructed message, you can use the client methods
`sendMessage:` or the block-based callback method `sendMessage:success:failure:`.
The following example uses the latter to show the user a message when the
`MGMessage` is successfully sent or display an error (if there was an error).

    [mailgun sendMessage:message success:^(NSString *messageId) {
        NSLog(@"Message %@ sent successfully!", messageId);
    } failure:^(NSError *error) {
        NSLog(@"Error sending message. The error was: %@", [error userInfo]);
    }];

### Subscribing and unsubscribing to mailing lists

Mailgun's mailing lists provide a convenient way to send to multiple recipients
by using an alias email address. Mailgun sends a copy of the message sent to the
alias address to each subscribed member of the mailing list. Adding a
subscribe and unsubscribe feature to your app can be a great way to stay engaged
and in touch with your customers by sending them periodic updates and tips. To
subscribe a user to a mailing list, we'll use the same Mailgun client we created
in the first example:

    Mailgun *mailgun = [Mailgun clientWithDomain:@"samples.mailgun.org" apiKey:@"key-3ax6xnjp29jd6fds4gc373sgvjxteol0"];

For this example, I have created an `AboutViewController` that has a `UITextField`
where a user can enter their email address and tap a subscribe button. Here's how
I handle the subscribe button's action:

    UITextField *mailTextField = [[UITextField alloc] initWithFrame:CGRectZero];

    [mailgun subscribeToList:@"news@sampleapp.org" email:mailTextField.text success:^{
        NSLog(@"Successfully subscribed user to mailing list!");
    } failure:^(NSError *error) {
        NSLog(@"There was an error while subscribing to the mailing list: %@", [error userInfo]);
    }];

The success and failure blocks can be used to display more information to the user,
track analytics and show/dismiss progress while the SDK is making the necessary
API calls.

To unsubscribe the process is similar. The following example takes the email of
a subscribed user, `jay.baird@rackspace.com`, and unsubscribes it from the
**SampleApp** mailing list:

    NSString *emailAddress = @"jay.baird@rackspace.com";
    [mailgun unsubscribeToList:@"news@sampleapp.org" email:emailAddress success:^{
        NSLog(@"Successfully removed %@ from the mailing list", emailAddress);
    } failure:^(NSError *error) {
        NSLog(@"Error removing address from mailing list: %@", [error userInfo]);
    }];

**NOTE**: If a user is not subscribed to a mailing list this method calls the
failure block with a `404` error. This is normal and should be handled
appropriately.

I hope this brief introduction to the new Mailgun SDK gets you as excited as I
am to add Mailgun features to your next OS X or iOS project. Feel free to fork
the project and contribute or file any issues you find on our
[Github page](https://github.com/rackerlabs/objc-mailgun).

_Jay Baird is an iOS developer at Rackspace's San Francisco office working on mobile products and services. His first computer was an Apple II and since then he knew most of his adult life would be consumed by technology. His favorite Steve Jobs-ism is that the Macintosh is "insanely great." Jay also holds a commercial pilot license and is studying to be a flight instructor. You can follow Jay on Twitter at [@skatterbean](https://twitter.com/skatterbean)._
