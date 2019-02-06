---
layout: post
title: Automating load testing to improve web application performance
date: '2013-08-22 14:00'
comments: true
author: Erik Torsner
published: true
categories:
-  General
---

Web application performance is a moving target. During design and implementation,
a lot of big and small decisions are made that affect application performance -
for good and bad. You've heard it before. But since performance can be ruined
many times throughout a project, good application performance simply can not be
added as an extra feature at the end of a project.

The modern solution to mitigate quality problems throughout the application
development life cycle is called *continuous integration*, or just CI. The benefits
of using CI are many, but for me, the most important factor for embracing CI is
the ability to run automated tests frequently and to trace application performance
because such tests need to be added to the stack of automated tests already being
generated. If you have load tests carried out throughout your project development,
you can proactively trace how performance is affected.

<!-- more -->

The key is being able to automate load testing. But how do we do that? Naturally,
it depends on your environment. Assuming that you're building a web application
and that your build environment is already in the cloud, it would be ideal to
start using a cloud based load testing service such as [Load Impact][1] or
Loader.io to automatically generate load and measure performance. In fact,
`libcurl` gets you almost all the way.

[Load Impact’s Continuous Delivery API][2] was created to enable developers to
run load tests programmatically. It's an HTTP based REST API that uses JSON for
passing parameters. In its most basic form, you can run the following from a
command line:

    $ curl -X POST https://api.loadimpact.com/v2/test-configs/X/start -u token: {"id":Y}
    $ curl -X GET https://api.loadimpact.com/v2/tests/Y/results -u token: > out.json

In this example, `X` = the LoadImpact test config id, `Y` = the test result
ID, and `token` = your LoadImpact API token. Note that `token` is sent as an HTTP
username but with a blank password.

Because JSON is not that easy to work with from the command line, using PHP or
Perl to wrap the calls in a script makes sense. A more complete sample doesn't
really fit into this blog post, but, at a pseudo-level, you want something
similar to the following example:

	<?php

	$token = '123456789';
	$urlbase = 'https://api.loadimpact.com/v2/';
	$config_id = 999;

	// Start test and get id from JSON return
	$test = http_post($urlbase . "/test-configs/$config_id/start"));

	$done = FALSE;
	while(!$done) {
	  sleep(30);
	  $status = http_get($urlbase . "/tests/{$test->id}");
	  $if($status->status > 2) $done = TRUE;
	}

	$result = http_get($urlbase . "/tests{$test-id}/results");
	$last = count($results->__li_user_load_time);
	echo $results->__li_user_load_time[$last]->value;

	?>

First, some variables are set, the existing test configuration id and my API
token being the most interesting.

Second, I ask Load Impact to launch the test configuration and store the test
ID. Wait for the test to finish by asking for its status code every 30 seconds.

Lastly, when I know the test if finished, I ask for the test result that I can
then query for values. In this example, I simply echo the last measurement of
the actual load time. If needed, the Load Impact API also allows me to manipulate
the target URL before I launched the test, change the number of simulated users
or make other relevant changes.

Running repeated load tests as part of your CI solution reveals a lot about
how an application’s performance is affected by all those small decisions.

Note that you probably don't want to run a full set of exhaustive performance
tests at every build. I recommend that you execute a few well-selected tests.
The key is to get a series of measurements that can be tracked over time.

### About the author

Erik Torsner is based in Stockholm, Sweden, and shares his time between being a
technical writer and customer projects manager within system development in his
own company. Erik co-founded mobile startup EHAND in the early 2000-nds and later
moved on to work as technology advisor and partner at the investment company that
seeded Load Impact. Since 2010, Erik manages Torgesta Technology. Read more about
Erik on his blog at <http://erik.torgesta.com> or on Twitter [@eriktorsner][3].

[1]: http://www.google.com/url?q=http%3A%2F%2Floadimpact.com%2F&sa=D&sntz=1&usg=AFQjCNHRodldaO8TULdq3M5vAyQFaXxKSA
[2]: http://developer.loadimpact.com/
[3]: http://twitter.com/eriktorsner