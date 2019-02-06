---
layout: post
title: Mailgun offers free email validation API for web forms
date: '2013-08-06 09:15'
comments: true
author: Hart Hoover
published: true
categories:
  - Mailgun
---

As many of you know, Rackspace acquired the transactional email provider Mailgun
almost a year ago. Mailgun has a super easy-to-use API for sending, receiving
and tracking on your application emails. They also support SMTP, if that's your
thing.  We've blogged about Mailgun a bunch this year, and recently Rackspace
integrated Mailgun into the Rackspace Cloud Control Panel, making it that much
easier to integrate Mailgun into your app (and to get 50,000 free emails per
month in the process). The Mailgunners just released a new feature that we are
really excited about: email validation for web forms. So today, we're reblogging
their post announcing the new feature which is completely free for Rackspace
and Mailgun customers.  Read on, and remember that you can enable your Mailgun
account directly through the Cloud Control Panel!

<!-- more -->

{% img center 2013-08-06-mailgun/cp.png %}

Email validation is a hard problem that every single developer, building
anything on the web, has to deal with.  We actually have been working on email
validation ourselves for years (more on that below). We looked at the validation
services available and weren’t satisfied with any of them, either for performance,
accuracy, or completeness reasons.  So today, we’re releasing our newest API
project, which we affectionately called *Guardpost*, and are also pulling back
the curtain to show exactly how we built it.

We’re launching this as a free service that anyone collecting email through web
forms can (and should!) use. You’ll need a Mailgun account to use the service,
but you don’t have to send your emails through Mailgun. If you want to get started
right away, check out the [API documentation][1], or a [little sample jquery app][2],
as an example of how to use Guardpost in a signup form.

We suggest using Guardpost as part of your email collection form to reduce typos
and false address submission in conjunction with a link emailed to the address
to confirm the email is valid (double opt-in). Of course, you can use Mailgun
to send the double opt-in email, as well. We do not intend this to be a bulk
mailing list cleaning service, and if we see it used as such, we reserve
the right to disable your account.

To call the Guardpost API, just use the publishable `API key` in the **My Account**
tab of your Mailgun account (the one with the `pub-key` prefix).

Now, on to to the technical details:

### Why is email validation so hard?

Address validation is hard for multiple reasons:

1. Email address syntax is fairly complex, complex enough that it is difficult
   to express with a regular expression, while being readable and maintainable
   for developers.
2. There is no single definition for valid syntax for an email address. The
   definitions that do exist frequently conflict.
3. The Internet runs on [the Robustness principle][3], so mail servers accept
   addresses that do not conform standards but are otherwise understandable.

### Why did we create an email validation API?

There are three main reasons we built our own service:

1. Our goal is not to make a perfect address validator to validate every
   single address that has ever been created. Our goal is to build a realistic
   address validator for the types of addresses that we see everyday.
2. We’ve sent billions of emails and collected a lot of ESP data. We know that
   *gmail.com* is a valid **MX** host while *gmali.com* is not.
3. Furthermore, the validator is Email Service Provider (ESP) specific. This
   means we can go way beyond valid syntax checks and bring in specific requirements
   for Gmail vs. Yahoo vs. Hotmail.

### What does the Validation service do?

Our validator service actually consists of five micro-services:

#### A recursive descent parser for syntax validation

Email address syntax is fairly complex, enough to make a pure
regular-expression-based approach cumbersome and unmaintainable. Check out
[RFC 2822][4] and [RFC 5322][5], which discuss proper email format, and then see
[this discussion on Stackoverflow][6], if you need some convincing. That's why
we wrote a parser that analyzes addresses and determines whether they are valid
based on a [formal grammar][7].

What is a formal grammar? Formal grammars (and specifically, in our case, a
context-free grammar) are a set of rules that define the structure of a string.
For example, it allows us to transform something we intuitively understand,
such as an address list, into something formal that a computer can parse.

So the context free grammar for an address list looks like the following example:

`address-list -> address ( delimiter address )*`

We have defined an address list, and we are saying it is composed
of a single address, followed by zero or more delimiter and single address pairs.
For example, the following is a valid address list:

`john@example.com, smith@example.com`

While the following is not valid:

`john@example.com smith@example.com`

What’s really nice about recursive, descent parsers is that we can take the grammar
rules and turn them into code in a fairly straightforward manner. Here is
pseudo-code for the above address list example:

```
   def get-address-list():
      address_list = []

      # get address
      address = get_address()
      if address is None:
         return None
      address_list.append(addr)

      while True:
         # get delimiter
         delimiter = get_delimiter()
            if delimiter is None:
               break

         # get address
         address = get_address()
         if address is None:
             break
         address_list.append(address)

      return address_list
```

Just like that, one by one, we slowly built grammar for every part of an email
address. We spent hours pouring over RFCs, looking at bounces, looking at what
mail servers actually accept (which is different sometimes from what RFC says),
and reading how other people were solving this problem to eventually define our
own context free grammar for email addresses:

```
   address-list      ->    address { delimiter address }
   mailbox           ->    name-addr-rfc | name-addr-lax | addr-spec | url

   name-addr-rfc     ->    [ display-name-rfc ] angle-addr-rfc
   display-name-rfc  ->    [ whitespace ] word { whitespace word }
   angle-addr-rfc    ->    [ whitespace ] < addr-spec > [ whitespace ]

   name-addr-lax     ->    [ display-name-lax ] angle-addr-lax
   display-name-lax  ->    [ whitespace ] word { whitespace word } whitespace
   angle-addr-lax    ->    addr-spec [ whitespace ]

   addr-spec         ->    [ whitespace ] local-part @ domain [ whitespace ]
   local-part        ->    dot-atom | quoted-string
   domain            ->    dot-atom

   word              ->    word-ascii
   word-ascii        ->    atom | quoted-string
   whitespace        ->    whitespace-ascii
```

We built our parser around the preceding grammar for what we think is a realistic
email address syntax.  Again, this is not just based on RFC, but what we see
ESPs accepting from sending billions of emails.

#### Domain Name Service (DNS) lookups

Just because an email address is syntactically valid, doesn’t mean that anyone
receives mail at that address. To receive mail, you have to have a server that
listens for incoming messages, this server is called a Mail Exchanger (MX) and
is usually defined in your DNS records. That’s why, in addition to syntax checks,
we look up the domains DNS records to see if a MX server has been defined to
accept mail.

#### Mail Exchanger existence checks

Again, due to the robustness principle, just because a host does not define **MX**
records does not mean they can’t accept mail. Mail servers will often fall-back
to **A** records to try and deliver mail. That’s why we go one step further than
just a DNS query, we ping the Mail Exchanger to make sure that it actually exists.

#### Custom ESP grammar

Being liberal in what you accept is just one part of the robustness principle,
and the second is be conservative in what you send. Because of that, most ESPs
actually have a fairly stringent rules for the local-part (before the @ symbol)
you can actually create. For example, Yahoo Mail addresses can only contain
letters, numbers, underscores, and one period. So while an address like,
“John Smith”@yahoo.com is completely syntactically valid, it does not actually
exist at Yahoo Mail and will bounce. That’s why if we know the Mail Exchanger
the mail is going to, and we know the big ones like Yahoo, Google, Microsoft
(including Hotmail), AOL, and Apple we validate against their more stringent
rules.

#### Suggestion service

Email addresses are frequently mistyped. Instead of @yahoo.com, you might type
@yaho.com, that’s why, as part of our validation service, if we detect a
misspelled word, we offer suggestions so you don’t miss mail due to a typo. Here’s
what that looks like in the [jquery demo app][2] [[source][8]] we mentioned above.

{% img center 2013-08-06-mailgun/email-validator.png %}

### What we don’t provide

We’ve talked a lot about what we provide, but we should make clear a few things
that we don’t provide:

1. We don’t check if a mailbox actually exists on a server. This used to be a
   [feature of SMTP][9], but due to abuse by spammers, this was disabled by most
   major ESPs.
2. We are not a mailing list cleanup service. This service is meant to be used
   to increase sign-up accuracy, not to cleanup mailing lists purchased from
   questionable sources. We will be monitoring usage and reserve the right to
   shut down anyone that is using it inappropriately.

So that’s it.  We hope you enjoy the service and it makes your life easier.
If you have any questions or comments, let us know.

Happy emailing!

[1]: https://api.mailgun.net/v2/address
[2]: http://mailgun.github.io/validator-demo/
[3]: http://en.wikipedia.org/wiki/Robustness_principle
[4]: http://tools.ietf.org/html/rfc2822
[5]: http://tools.ietf.org/html/rfc5322
[6]: http://stackoverflow.com/a/719543
[7]: https://en.wikipedia.org/wiki/Parsing
[8]: https://github.com/mailgun/validator-demo/tree/gh-pages
[9]: http://cr.yp.to/smtp/vrfy.html