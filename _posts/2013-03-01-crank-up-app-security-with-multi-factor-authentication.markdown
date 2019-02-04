---
layout: post
title: Crank up app security with multi-factor authentication
date: '2013-03-01 06:59'
comments: true
author: Major Hayden
categories:
  - Security
---

{% img right 2013-03-01-crank-up-app-security/lockkey.png %}

_Major Hayden is the Chief Security Architect and a Linux engineer who has experience working on large-scale OpenStack deployments and automation in Rackspace Cloud. He enjoys writing posts about Linux system administration and security on the Rackspace blog as well as his [personal blog](http://rackerhacker.com/). Follow him on Twitter [@rackerhacker](http://twitter.com/rackerhacker)_

The password is dying, but I’m afraid it’s not dying fast enough.

The majority of us interact with web applications by logging on with a username and password. However, this single layer of protection leaves our applications, data and personal information at risk.

 <!-- more -->

 The single password is no longer an adequate form of security, and there are three main reasons that using single-factor authentication leaves you at risk:

1. The overwhelming population does not use a complex password. Many users still think that a password like “p@ssw0rd” or “abc123” is enough to properly secure an account.
2. For users who do create complex passwords, they can be cracked by brute force using an increasing number of libraries dedicated to this purpose. Password hashes are also available for the most commonly used passwords, which allows for an attacker to determine weak passwords almost instantly.
3. Attackers realize that there are other ways at getting your password, such as compromising a server with malware or viewing network traffic between you and the server you’re trying to reach.

With the need for increased security requirements in the workplace, it is imperative for any developer looking to design an application to consider two-factor authentication. Businesses run applications that often contain sensitive information and by showing that your application has an extra layer of security is necessary as you approach them with your software.

Let’s look at the three primary ways of authenticating a user:

* **What you know.** The standard password is an example of a user proving that they know information that should allow them to get into a system.
* **What you have.** With this type of authentication, the user has to prove that they have something in their possession at the time of the request, such as a [RSA token](http://www.emc.com/security/rsa-securid.htm), [Google Authenticator](http://support.google.com/accounts/bin/answer.py?hl=en&answer=1066447) code or [YubiKey](http://www.yubico.com/).
* **What you are.** Biometric data, such as fingerprint recognition, retina scanning and even the cadence you use when typing your password can be used to determine your identity.

Recognizing that a single password has a certain likelihood of being cracked, authenticating a user on two of these factors makes it one step harder for someone to exploit your system. Application developers would be remiss to not offer a two-factor authentication login option for users.

Before, authentication seemed to be on a scale from 0 to 1. You either supplied the correct information and you were able to get into a system, or you failed and were not allowed access. As security evolves, I believe that security shifts to a scale from 0 to 1,000. The user must achieve a certain level of “points” to be granted access to a system.

Consider the following scenario: providing a correct password earns the user 400 points, accessing the system on the company network gives the user 200 points and using a YubiKey gives the user 300 points. Let’s say that for a particular system, you need 600 points to login. This means that the user can both provide a password and use a YubiKey, or successfully entering a password while being connected to the company network.

However, you can even take this a step further, requiring a user to “step up” to do particularly sensitive tasks. For example, a user might need to achieve 800 points to modify a customer record in a database. Even though a user was authenticated from the initial 600 points to use the system, he will have to provide an additional piece of information in order to perform a more sensitive task. Multi-factor authentication delivers this additional level of security.

As developers looking to make their applications more secure, they should always remain considerate to people’s workflows. Developers must demonstrate the value of the security to their customer, and make the different points of authentication jibe with the level of security that is needed for a particular function.

Two-factor authentication can already be implemented for many applications via plugins or libraries. For Linux users, PAM modules are available for both the [YubiKey](http://code.google.com/p/yubico-pam/) and [Google Authenticator](http://code.google.com/p/google-authenticator/). WordPress, a popular CMS not just for bloggers [but also enterprises](http://en.wordpress.com/notable-users/), even has plugins that support [YubiKey](http://wordpress.org/extend/plugins/yubikey-plugin/) and [Google Authenticator](http://wordpress.org/extend/plugins/google-authenticator/).

In summary, authenticating users with multiple factors is beneficial for application developers and end users. For the end users, they get the peace of mind that an attacker must know (and have) multiple items that are personal to the user. For application developers, they can offer their application to larger businesses that have strict security requirements around user authentication.

There’s one last thing that is critical to understand: Multi-factor authentication will make it substantially more difficult for an attacker to gain access but it’s certainly not going to stop a determined attacker with the right tools and time to spare. Developers must combine multi-factor authentication with a secure codebase and a properly secured infrastructure.
