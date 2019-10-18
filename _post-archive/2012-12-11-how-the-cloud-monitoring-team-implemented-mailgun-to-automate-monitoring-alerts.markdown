---
layout: post
title: How the Cloud Monitoring team implemented Mailgun to automate monitoring alerts
date: '2012-12-11 11:52'
comments: true
author: Wayne A. Walls
categories:
  - Mailgun
  - Cloud Monitoring
---
The team over at Mailgun just posted a [case study](https://blog.mailgun.com/how-node-js-app-cloud-monitoring-uses-the-mailgun-api/) about how the Rackspace Cloud Monitoring team successfully migrated their email alerts to the [Mailgun email automation platform](https://www.mailgun.com/). It's a really interesting read that is as much about how to plan for and deploy 3rd party tools in a production application as it is about using Mailgun to automate and monitor email alerts.
<!-- more -->
When it comes to Mailgun, the monitoring team implemented Mailgun in their node.js app to dynamically generate and deliver monitoring notifications. These notifications include details about the alert and need to be generated on the fly as soon as an alert is trigged. If you don't head over to the Mailgun blog to read the full post (you should!), here's how the team did it.

During the test, we added code to look at the special [test] account during the Deliver Alert stage to start routing messages to Mailgun.  This process was simple because very little code was involved.

Here’s what a snippet looks like:

{% codeblock lang:javascript %}
if (tenantId === ‘XXX’) {
 emailUtil.sendMailgunEmail(address, subject, body, {headers: headers}, function(err, res) {
   var delta = (Date.now() - startTime);
   accessLog.logAccess(ctx, 'mailgun', misc.getUnixTimestamp(), delta, err);

   if (err) {
     log.error('error performing email notification', {
       ctx: ctx,
       err: err
     });
     callback(err);
     return;
   }

   callback(null, 'Email successfully sent', body);
 });
} else {
…
}
{% endcodeblock %}

What’s going on above? First, we call the sendMailgunEmail function to deliver the monitoring notification email.  In a quest to measure EVERYTHING, we also measure the time it takes to use the Mailgun API. And there is a series of retries that wraps this code with a fallback option, a best practice when relying on any 3rd-party system in your application.

Want to see how simple the sendMailgunEmail function is?

{% codeblock lang:javascript %}
exports.sendMailGunEmail = function(address, subject, body, options, callback) {
 options = options || {};
 options.headers = options.headers || {};
 options.apiUrl = options.apiUrl || settings.MAILGUN_API_URL;
 options.domain = options.domain || settings.MAILGUN_DOMAIN;
 options.apiKey = options.apiKey || settings.MAILGUN_API_KEY;
 options.fromAddress = options.fromAddress || settings.MAILGUN_FROM_ADDRESS;
 options.testMode = options.testMode || settings.MAILGUN_TEST_MODE;

 var url = options.apiUrl + options.domain + '/messages', bodyObj, k, httpOptions;

 httpOptions = {                    // 1)  set up some defaults
   'expected_status_codes': [200],
   'return_response': true,
   'parse_json': true,
   'username': 'api',
   'password': options.apiKey,
   'headers': {'Content-Type': 'application/x-www-form-urlencoded'}
 };

 bodyObj = {
   'to': address,
   'subject': subject,
   'from': options.fromAddress
 };

 if (options.isHTML) {              // 2)  switch based on the content type we want to send
   bodyObj.html = body;
 } else {
   bodyObj.text = body;
 }

 for (k in options.headers) {       // 3)  merge in the headers so we can provide id’s as headers in the emails
   if (options.headers.hasOwnProperty(k)) {
     bodyObj['h:' + k] = options.headers[k];
   }
 }

 if (options.testMode) {            // 4) enable sandbox testing
   bodyObj['o:testmode'] = true;
 }

 if (options.tags) {                // 5)  set some tags to automatically pivot analytics for visibility. (we view reporting in the Mailgun control panel but data is also available via API or webhook)
   bodyObj['o:tag'] = options.tags;
 }

 body = querystring.stringify(bodyObj);

 request(url, 'POST', body, httpOptions, callback);   
};
{% endcodeblock %}

1. The request function abstracts some dealing with complex HTTP requests and handling of response codes, so expected_response_codes is used for that.
2. Easily deal with sending HTML, which is generally a pain.
3. Merge in headers allowing for easy way to enrich emails.  These headers allow us to create customized emails for each user with details about their alert like alarmId, checkId, and tenantId. You can pass almost anything to customize your emails in these headers that would just normally clutter the body of the email.
4. Easily flip a bit for sending test emails
5. User-defined tags allow tracking and analytical faceting used in our production testing scenarios.

Look at how easy this was.  We’ve fully automated email creation, delivery, and analytics using Mailgun, something that is difficult with with a traditional DIY setup.

In case you haven't heard, Rackspace customers receive a $19/month credit to use Mailgun. That means that when you signup for the [Mailgun standard plan](https://www.mailgun.com/pricing), you can send up to 19,000 emails per month, for free. Email sales@mailgunhq.com for details about how to receive your Mailgun discount.
