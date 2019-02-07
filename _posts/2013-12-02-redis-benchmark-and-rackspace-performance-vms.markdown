---
layout: post
title: 'Redis-Benchmark &amp; Rackspace performance VMs'
date: '2013-12-09 12:30'
comments: true
author: Ken Perkins
published: true
categories:
  - node.js
---
While I was visiting the [Concurix team](http://www.concurix.com) getting a demo of
some of the awesomeness they have for node.js profiling,
[Bryce Baril](https://github.com/brycebaril) mentioned that he was a new
[node-redis](https://github.com/mranney/node_redis) core-committer and how
performance was really critical for the redis package (and redis in general).

I asked what he used to benchmark and he informed me that redis has a very
robust benchmarking tool built in.

```
> redis-benchmark
```

I immediatley thought of using `redis-benchmark` to illustrate the difference
between our (soon to be deprecated) standard flavors and our new performance
flavors. Based on some reading on the redis-benchmark page, I decided to use
the same critiera as the Redis Benchmarks page for
[evaluating bare-metal and virtual machines](http://redis.io/topics/benchmarks).

<!-- more -->

```
> redis-benchmark -r 1000000 -n 2000000 -t get,set,lpush,lpop -q -P 16
> redis-benchmark -r 1000000 -n 2000000 -t get,set,lpush,lpop -q
```

In both cases, I used 1gb virtual machines, running
`Ubuntu 13.04 (Raring Ringtail) (PVHVM beta)` in the ORD datacenter. Redis is
version `2.6.7` and I ran the test 5 times on each machine.

### Redis-Benchmark w/o pipelining

<img src="{% asset_path 2013-12-02-redis-benchmark-rackspace-performance-vm/redis-benchmark-no-pipelining.png %}">

### Redis-Benchmark with pipelining enabled (16 commands):

<img src="{% asset_path 2013-12-02-redis-benchmark-rackspace-performance-vm/redis-benchmark-with-pipelining.png %}">

#### The raw data

<table class="stats">
 <tr>
  <td></td>
  <td>Pipelined (16)</td>
  <td></td>
  <td></td>
  <td></td>
  <td>No Pipeline</td>
  <td></td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td></td>
  <td>SET</td>
  <td>GET</td>
  <td>LPUSH</td>
  <td>LPOP</td>
  <td>SET</td>
  <td>GET</td>
  <td>LPUSH</td>
  <td>LPOP</td>
 </tr>
 <tr>
  <td>Standard 1GB</td>
  <td>213389</td>
  <td>239944</td>
  <td>267172</td>
  <td>263396</td>
  <td>47248</td>
  <td>46276</td>
  <td>51107</td>
  <td>48871</td>
 </tr>
 <tr>
  <td>Performance 1GB</td>
  <td>264623</td>
  <td>280678</td>
  <td>350185</td>
  <td>316509</td>
  <td>64228</td>
  <td>65097</td>
  <td>69382</td>
  <td>70907</td>
 </tr>
 <tr>
  <td>Difference</td>
  <td>24.01%</td>
  <td>16.98%</td>
  <td>31.07%</td>
  <td>20.16%</td>
  <td>35.94%</td>
  <td>40.67%</td>
  <td>35.76%</td>
  <td>45.09%</td>
 </tr>
</table>

I'm not claiming to be an expert on Redis performance, but it's obvious that
**our new performance flavors kick ass**. We're seeing 35-45% faster results
in the non-pipelined case, and 16-31% in the pipelined case. Not bad
considering we made the pricing even more competitive.

