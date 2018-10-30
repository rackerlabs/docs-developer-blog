---
layout: post
title: "Stats from an SSH Honeypot"
date: 2018-10-30 23:59
comments: false
author: Rodney Beede
authorIsRacker: true
published: true
categories:
  - Security
  - Cloud Servers
---

I decided to run an ssh honeypot in my Cloud Server on the Internet.  While this has been done many times by others, I wanted to see what would happen and share my results.

<!-- more -->

## What is a honeypot?

In computer security, the term honeypot is used to refer to an environment setup that is used to capture malicious activity in a safe manner.  You place an attractive target on a network (internal or the Internet) and wait for attacks to come in.  Your honeypot then captures data about the attacker and can alert you if someone has been caught in it.

One visual is that of a jar of sticky honey.  If someone reaches into the jar, you will notice the contents being disturbed as well as the person having sticky honey on his or her hands.

A security honeypot may have an easy to guess login password or a fake document made to look like real confidential business data.

The honeypot aids a security researcher in understanding what actions an attacker takes so they can develop a behavior profile for detecting attacks against real systems.


## SSH Honeypot

I used a Linux cloud server with this modified [SSH server software](https://github.com/droberson/ssh-honeypot.git).

I placed the server on the Internet and turned off the firewall.  The results of attacks were recorded on disk in a log file.


## Timeline

Start:  Tue Sep 11 15:02:26 2018 UTC

End:    Wed Sep 19 13:54:16 2018 UTC

Duration:  7 days, 22 hours, 51 minutes and 50 seconds


## Results

### Total Attacks

1,115,930 attempts to guess a password and login to the system.


### Top 10 Usernames

| Attempts &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; | Username |
|-------|--------|
| 1,110,289 | root |
| 588 | admin |
| 476 | support |
| 169 | test |
| 161 | user |
| 117 | guest |
| 108 | oracle |
| 74 | postgres |
| 67 | ubnt |
| 63 | monitor |


### Top 10 Passwords

| Attempts &nbsp; &nbsp; | Password |
|-------|--------|
| 30,886 | password |
| 30,879 | 123456 |
| 30,632 | root |
| 30,089 | waldo |
| 30,067 | admintrup |
| 29,931 | admin |
| 29,894 | ubnt |
| 29,889 | system |
| 29,880 | 12345 |
| 29,877 | Zte521 |


### Top 10 Attack Origins

| Attempts &nbsp; &nbsp; &nbsp; &nbsp; | Country |
|-------|--------|
| 739,025 | Philippines |
| 368,494 | China |
| 4,541 | Germany |
| 1,070 | Mexico |
| 898 | Russian |
| 465 | Korea, Republic of |
| 416 | Ukraine |
| 322 | United States |
| 84 | Italy |
| 69 | France |



## Summary

This was an interesting experiment and shows that putting a server on the Internet results in millions of attacks against it in a very short time.

It behooves us, therefore, to ensure that a server has protections on it from the moment that we connect it to the network.
