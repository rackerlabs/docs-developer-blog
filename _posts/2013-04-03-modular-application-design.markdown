---
layout: post
title: Modular application design with services
date: '2013-04-04 08:00'
comments: true
author: Hart Hoover
published: true
categories:
  - Cloud Servers
---
{% img right pillars/pillar.png 160 160 %}

Wayne Walls posted a [great article](http://www.rackspace.com/blog/pillars-of-cloudiness-no-2-modular-design/)
on the Rackspace Blog regarding the importance of modularity in cloud application
design. Traditionally, when technical people talked about modular design they
meant something like this:

{% img center 2013-04-04-modular/modular1.png 350 %}

As you can see, we have a typical web application that is indeed very modular.
It has a few Varnish caching servers, a few web servers, a few application
servers and a few database servers. Basically, we've taken what was once a
monolithic application and split it into atomic components that are scalable and
replaceable.

In the cloud though, we don't have to stop there. The preceding is a "bare metal
servers on a cloud" mentality. What you should strive for is a true modular
application that not only is broken up into smaller pieces, but also consumes services.

<!-- more -->

{% img center 2013-04-04-modular/modular2.png 350 %}

This demonstrates a departure from only consuming an infrastructure service to
consuming a mixture of IaaS and platform services. Why maintain your own storage
platform when you can consume
[Cloud Files via an API](https://developer.rackspace.com/docs/cloud-files/v1/getting-started/)?
Why run your own email server when you can consume [Mailgun via an API](http://documentation.mailgun.net/)?
Compute is expensive: you should only use it for tasks that actually require compute power!

Imagine scaling a payment system. You have to check for compliance. You have to
check that proper firewall rules are in place. You likely have to scale a database.
Let's take a look at a way to integrate a payment partner service into your application.
 Using a third-party payment gateway gives you the dual benefit of being more modular
 while also taking management of payment services off of your teams, allowing
 them to focus on making better products.

I want to walk through how to set up [Stripe](https://stripe.com) to start
charging customers for your products. I am going to use Python here, but Stripe
has more documentation for other languages on its [website](https://stripe.com/docs).

### Install the client library

Stripe makes it easy to install the library you require:

**Install using pip:**

`sudo pip install --index-url https://code.stripe.com --upgrade stripe`

### Install using easy_install:

`sudo easy_install --index-url https://code.stripe.com --upgrade stripe`

#### Add a form to your checkout page

You need a form on your site to collect information from your customer. Because
we're already using Python, let's use [Flask](http://flask.pocoo.org/).

First, create a dictionary with Stripe’s tokens, publishable\_key and secret\_key,
which are being pulled out of the current environmental variables. We’re not
hardcoding these keys because we don't want to put sensitive data into source control.

**app.py**

```python
import os
from flask import Flask, render_template, request
import stripe

stripe_keys = {
    'secret_key': os.environ['SECRET_KEY'],
    'publishable_key': os.environ['PUBLISHABLE_KEY']
}

stripe.api_key = stripe_keys['secret_key']

app = Flask(__name__)
```

### Next, add some Flask methods to display the payment form and to accept charges.

```python
@app.route('/')
def index():
    return render_template('index.html', key=stripe_keys['publishable_key'])

@app.route('/charge', methods=['POST'])
def charge():
    # Amount in cents
    amount = 500

    customer = stripe.Customer.create(
        email='customer@example.com',
        card=request.form['stripeToken']
    )

    charge = stripe.Charge.create(
        customer=customer.id,
        amount=amount,
        currency='usd',
        description='Flask Charge'
    )

    return render_template('charge.html', amount=amount)

if __name__ == '__main__':
    app.run(debug=True)
```

More detail on setting up the Flask application is available in
[Stripe's checkout tutorial](https://stripe.com/docs/checkout/guides/flask).

### Add the code to your application

Once you have a Flask application running, grab the Stripe token in the POST
parameters submitted by your payment form. Once you do, it's one simple call to
charge the card with Stripe:

```python
# Set your secret key: remember to change this to your live secret key in production
# See your keys here https://manage.stripe.com/account
stripe.api_key = "1234567890"

# Get the credit card details submitted by the form
token = request.POST['stripeToken']

# Create the charge on Stripe's servers - this will charge the user's card
try:
  charge = stripe.Charge.create(
      amount=1000, # amount in cents, again
      currency="usd",
      card=token,
      description="payinguser@example.com"
  )
except stripe.CardError, e:
  # The card has been declined
  pass
```

That's all there is to it! You've integrated a payment service into an application,
and more importantly it is a service that collects money for you! Having a modular
application doesn't just mean breaking apart application pieces into tiers of
scalable compute. It also means breaking apart your application to consume
services programmatically.
