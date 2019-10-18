---
layout: post
title: Improving your site speed with Redis
date: '2013-04-29 8:00'
comments: true
author: Hart Hoover
published: true
categories: []
---
{% img right 2013-04-29-speed-up-with-redis/redis_logo.png 200 200 %}
Adding Redis to your application stack is a fantastic way to gain speed with existing applications. Many of our customers aren't running the latest and greatest new hotness NoSQL-using cloud thing. A lot of them port over a full stack of an existing applications that once only existed on bare metal servers, or use a hybrid environment with a big MySQL configuration on bare metal with web/app servers in the cloud.

In any case, we advise that customers use caching... EVERYWHERE. Adding Redis to your application stack can greatly improve site speeds when used as a cache.<!-- more -->

##What's Redis?

From the "[Introduction to Redis](https://redis.io/topics/introduction)" page at [redis.io](https://redis.io):

> Redis is an open source, BSD licensed, advanced key-value store. It is often referred to as a data structure server since keys can contain strings, hashes, lists, sets and sorted sets. You can run atomic operations on these types, like appending to a string; incrementing the value in a hash; pushing to a list; computing set intersection, union and difference; or getting the member with highest ranking in a sorted set.

Want to try Redis? Check out [https://try.redis.io/](https://try.redis.io/)

##Why Redis?

There is a [ton](https://www.quora.com/Redis-vs-Memcached-which-one-should-I-use-for-a-web-based-application) of [debate](https://stackoverflow.com/questions/2873249/is-memcached-a-dinosaur-in-comparison-to-redis) out there on whether to use Redis or Memcached as a cache. Both are great, but Redis provides a few features over Memcached:

* Persistence: if you restart the memcached service, you have to warm up your cache again.
* Key/Value vs. Objects: Redis is more advanced in what it can store
* Selective deletion of cached items

##How do I set this up?

You can [install Redis](https://redis.io/download) on a Cloud Server if you like, but I recommend setting up a Redis instance at [RedisToGo](https://redistogo.com/). The instances are configured with Redis already, and RedisToGo makes Redis easy to scale. Other features of RedisToGo:

* Graphs of connections and memory use
* Monitoring notifications on memory use and connection limits
* 1-click upgrades to scale
* 1-click multi-zone redundancy.
* Hourly backups
* Paid plans persist data to disk on a RAM flush

Once Redis is installed and online, you need to configure your application to use it. The example below uses [Predis](https://github.com/nrk/predis/), a PHP client library. There are [plenty of clients](https://redistogo.com/documentation?language=en) to use with Redis, so you can pick and choose based on your preferred language.

The example below is from on a fantastic tutorial by [Jim Westgren](https://www.jimwestergren.com/wordpress-with-redis-as-a-frontend-cache/) and is specific to WordPress-based sites, but WordPress specific code can be stripped out for use with just about any website. Enjoy!

```php
<?php

/*
    Author: Jim Westergren & Jeedo Aquino
    File: index-with-redis.php
    Updated: 2012-10-25

    This is a redis caching system for wordpress.
    see more here: www.jimwestergren.com/wordpress-with-redis-as-a-frontend-cache/

    Originally written by Jim Westergren but improved by Jeedo Aquino.

    some caching mechanics are different from jim's script which is summarized below:

    - cached pages do not expire not unless explicitly deleted or reset
    - appending a ?c=y to a url deletes the entire cache of the domain, only works when you are logged in
    - appending a ?r=y to a url deletes the cache of that url
    - submitting a comment deletes the cache of that page
    - refreshing (f5) a page deletes the cache of that page
    - includes a debug mode, stats are displayed at the bottom most part after </html>

    for setup and configuration see more here:

    www.jeedo.net/lightning-fast-wordpress-with-nginx-redis/

    use this script at your own risk. i currently use this albeit a slightly modified version
    to display a redis badge whenever a cache is displayed.

*/

// change vars here
$cf = 1;			// set to 1 if you are using cloudflare
$debug = 0;			// set to 1 if you wish to see execution time and cache actions
$display_powered_by_redis = 1;  // set to 1 if you want to display a powered by redis message with execution time, see below

$start = microtime();   // start timing page exec

// if cloudflare is enabled
if ($cf) {
    if (isset($_SERVER['HTTP_CF_CONNECTING_IP'])) {
        $_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_CF_CONNECTING_IP'];
    }
}

// from wp
define('WP_USE_THEMES', true);

// init predis
include("predis.php");
$redis = new Predis\Client('');

// init vars
$domain = $_SERVER['HTTP_HOST'];
$url = "https://".$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];
$url = str_replace('?r=y', '', $url);
$url = str_replace('?c=y', '', $url);
$dkey = md5($domain);
$ukey = md5($url);

// check if page isn't a comment submission
(isset($_SERVER['HTTP_CACHE_CONTROL']) && $_SERVER['HTTP_CACHE_CONTROL'] == 'max-age=0') ? $submit = 1 : $submit = 0;

// check if logged in to wp
$cookie = var_export($_COOKIE, true);
$loggedin = preg_match("/wordpress_logged_in/", $cookie);

// check if a cache of the page exists
if ($redis->hexists($dkey, $ukey) && !$loggedin && !$submit && !strpos($url, '/feed/')) {

    echo $redis->hget($dkey, $ukey);
    $cached = 1;
    $msg = 'this is a cache';

// if a comment was submitted or clear page cache request was made delete cache of page
} else if ($submit || substr($_SERVER['REQUEST_URI'], -4) == '?r=y') {

    require('./wp-blog-header.php');
    $redis->hdel($dkey, $ukey);
    $msg = 'cache of page deleted';

// delete entire cache, works only if logged in
} else if ($loggedin && substr($_SERVER['REQUEST_URI'], -4) == '?c=y') {

    require('./wp-blog-header.php');
    if ($redis->exists($dkey)) {
        $redis->del($dkey);
        $msg = 'domain cache flushed';
    } else {
        $msg = 'no cache to flush';
    }

// if logged in don't cache anything
} else if ($loggedin) {

    require('./wp-blog-header.php');
    $msg = 'not cached';

// cache the page
} else {

    // turn on output buffering
    ob_start();

    require('./wp-blog-header.php');

    // get contents of output buffer
    $html = ob_get_contents();

    // clean output buffer
    ob_end_clean();
    echo $html;

    // Store to cache only if the page exist and is not a search result.
    if (!is_404() && !is_search()) {
        // store html contents to redis cache
        $redis->hset($dkey, $ukey, $html);
        $msg = 'cache is set';
    }
}

$end = microtime(); // get end execution time

// show messages if debug is enabled
if ($debug) {
    echo $msg.': ';
    echo t_exec($start, $end);
}

if ($cached && $display_powered_by_redis) {
	// You should move this CSS to your CSS file and change the: float:right;margin:20px 0;
	echo "<style>#redis_powered{float:right;margin:20px 0;background:url(https://images.staticjw.com/jim/3959/redis.png) 10px no-repeat #fff;border:1px solid #D7D8DF;padding:10px;width:190px;}
	#redis_powered div{width:190px;text-align:right;font:10px/11px arial,sans-serif;color:#000;}</style>";
	echo "<a href=\"https://www.jimwestergren.com/wordpress-with-redis-as-a-frontend-cache/\" style=\"text-decoration:none;\"><div id=\"redis_powered\"><div>Page generated in<br/> ".t_exec($start, $end)." sec</div></div></a>";
}

// time diff
function t_exec($start, $end) {
    $t = (getmicrotime($end) - getmicrotime($start));
    return round($t,5);
}

// get time
function getmicrotime($t) {
    list($usec, $sec) = explode(" ",$t);
    return ((float)$usec + (float)$sec);
}

?>
```
