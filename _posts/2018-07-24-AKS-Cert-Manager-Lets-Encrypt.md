---
layout: post
title: "AKS - Cert Manager certificate rate limit"
date: 2018-07-24 00:00
comments: true
author: Jimmy Rudley
published: true
authorIsRacker: true
authorAvatar: 'https://en.gravatar.com/userimage/151177997/5bed7e07ee47533cbd34b951d463bcb7.jpg'
bio: “Jimmy Rudley is an Azure Architect at Rackspace and an active member of the Azure community. He focuses on solving large and complex architecture and automation problems within Azure."
categories:
    - Azure
---

Microsoft&reg; Azure&reg; recently went GA with their Azure Kubernetes Service,
but following the Microsoft documentation for setting up an HTTPS ingress
controller could make you go in circles. Let me share what I have found out
Microsoft's recent changes in their HTTPS ingress controller
[document](https://docs.microsoft.com/en-us/azure/aks/ingress).

<!-- more -->

Microsoft is really putting the spotlight on their Kubernetes offering, so I
spent some time setting it up. It truly is simple to deploy and manage. Microsoft
has also done great work integrating it into their existing tooling set. If you
have not used their cloud shell, please try it out. It has the majority of
tooling already installed to manage your AKS cluster. I do want to focus on the
HTTPS ingress controller to save some people the headaches I ran into.

The Microsoft AKS offering uses [Cert-Manager](https://github.com/jetstack/cert-manager)
to retrieve and configure certificates for HTTPS. Cert-Manager makes use of
``Let's Encrypt`` tool to create the certificates. If you read the Cert-Manager
readme, under current status it mentions it is not ready for a critical production
stack. OK, fair enough, they warn us, but Microsoft does not.

As I am writing
this article, Microsoft changed their document to make use of the ``Let's Encrypt``
staging environment. Previously, they were using the production environment setting.
I am sure the author of their document missed this tidbit, but ``Let's Encrypt``
rate limits your requests, especially when using the production enviornment setting.
In Microsoft's example, they are using the domain **demo-aks-ingress.eastus.cloudapp.azure.com**,
but when I initially tested it out using **demo-jimmy-ingress.eastus.cloudapp.azure.com**.
I noticed my certificate never provisioned. I did a **kubectl describe certificate**
and was presented with the following:

```
Message:  Failed to finalize order: acme: urn:ietf:params:acme:error:rateLimited:
Error finalizing order :: too many certificates already issued for exact set of
domains: demo-jimmy-ingress.eastus.cloudapp.azure.com:
see https://letsencrypt.org/docs/rate-limits/
```

I am puzzled. I was being rate limited for a domain I just submitted a request
for? It turns out that ``Let's Encrypt`` looks at **Azure.com**. Here is the
snippet from the rate limit document:

```
The main limit is Certificates per Registered Domain, (20 per week).
A registered domain is, generally speaking, the part of the domain you purchased
from your domain name registrar.

For instance, in the name www.example.com, the registered domain is example.com.
In new.blog.example.co.uk, the registered domain is example.co.uk. We use the Public Suffix List to calculate the registered domain.
```

Today, Microsoft changed their document to use the staging environment, which
has these limits:

```
The Certificates per Registered Domain limit is 30,000 per week.
The Duplicate Certificate limit is 30,000 per week.
The Failed Validations limit is 60 per hour.
The Accounts per IP Address limit is 50 accounts per 3 hour period per IP.
For ACME v2, the New Orders limit is 1,500 new orders per 3 hour period per account.
```

Great for testing, but just be aware when you move to production using the free
dns name for your Azure Public IP.

Use the Feedback tab to make any comments or ask questions.
