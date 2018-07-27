---
layout: post
title: "InsightVM (Nexpose) Slackbot"
date: 2018-07-26 23:59
comments: true
author: Trevor Steen
published: true
categories:
  - Security
  - Automation
  - Python
---

 A few months back, I decided to find a way to lighten the load of ad-hoc vulnerability scanning requests by our system owners.  Our most frequent requests used to go something like this: "Can you scan this"..."Ok I fixed it, scan again."

 Given the prevalence of Slack and associated bots, I thought it would be a good idea to try to write my own for scanning. Enter the InsightVM Slack Bot!

<!-- more -->

# Ruby Version
Initially, I wrote the entire bot in Ruby using the [Ruby Slack Client](https://github.com/slack-ruby/slack-ruby-client) and the [Nexpose API Ruby Gem](https://github.com/rapid7/nexpose-client).  At the time, the Nexpose Gem was the preferred (and only supported) way to interact with the Nexpose API, which was the primary mechanism for initiating scans. This approach worked...mostly, but there were a few problems:

* The Slack Ruby Client seemed a bit unstable for some reason. The bot would run for days at a time and then just randomly lose connection to Slack. At other times, the bot would only last a few hours before the connection was lost. This could 100% have been an issue with my code, but I was never able to determine the culprit.
* In order to rate limit the scans, I needed a queuing system, so I ended up using the [Ruby Resque Gem](https://github.com/resque/resque). This worked really well for my purposes and even provided a pretty cool web interface for tracking jobs. The downside was that this also required me to run a [Redis database](https://redis.io/) to house the queue information. This was just an additional dependency.
* Due to (probably my lack of coding expertise) the structure of the queue mechanism and the tasks I was trying to accomplish, the program structure was pretty ugly. I had a base script that ended up calling three other Ruby scripts that operated two different queues for scan initiation and scan status tracking. I could only figure out how to run the script directly (not as a service or anything else). This made debugging difficult and was definitely not the most user-friendly thing in the world.

Python Version
Then [Rapid7](https://www.rapid7.com/) released [version 3 of the InsightVM API](https://help.rapid7.com/insightvm/en-us/api/index.html) as a RESTful API, after they rebranded Nexpose as InsightVM. This update freed me from the Ruby requirement, and after a few months of debating, I finally decided to port the bot over to Python (3 of course). This decision was also largely due to the work my team did on developing an InsightVM Helpers class to assist in interacting with the API.

The Python version of the bot differs from the Ruby version in a few key ways:

* Instead of [Resque](https://github.com/resque/resque) and [Redis](https://redis.io/) as my queuing and rate limiting mechanism, I was able to make use of the native Python threading capabilities. This reduced my dependencies and also was much cleaner to implement in code.
* Using the new [InsightVM API](https://help.rapid7.com/insightvm/en-us/api/index.html, after they rebranded Nexpose as InsightVM, I was more cleanly able to execute the scan functions that I needed, **and** the new API is much faster in most cases. There are a few wonky spots, but I was able to overcome those with some interesting code features.
* The [Python Slack Client](https://github.com/slackapi/python-slackclient) seems much more stable, and I have not had any random crashes or disconnects using this client.
I forced myself to write tests for this project, which was a [rewarding experience](https://ratil.life/testing-with-python/) itself.

The major drawback of using the new V3 API is figuring out which site or sites an asset is part of. In the Ruby Gem, there was an ad hoc scan function that would simply scan the asset as part of whatever site the asset had been scanned with last time, without the need to specify a site parameter.  Therefore, I did not have to figure that part out.  In V3, I have to poll every site to determine which ones an asset is part of.  Using the `joblib` library and the associated `Parallel` and `delayed` classes, I was able to get this part done really quickly by making a bunch of parallel calls to determine site membership. The end effect on the speed of starting a scan is negligible (if not faster) when compared to how I was able to ignore this part in Ruby.

# Usage
The setup of the bot is covered in the following GitHub page, so I will not cover that here.  The bot is simple enough to use, after it's installed and running. A user simply has to either add the bot to a channel or do a direct message with the bot and then scan an asset like so: `@insightvm_bot scan 192.168.1.1`.

The bot then immediately responds to indicate receipt of the request and starts working on figuring out how exactly to scan the asset.  The bot accepts both IPs and hostnames, so the first task is to sort that out by regexing out IPs and hostnames.  Then those IPs and hostnames are checked against every site in InsightVM to determine what sites they are a part of. Unfortunately the API does not return site membership with the asset search function so this is a necessary inefficiency. If an IP or hostname is not part of a site, a forward or reverse lookup is conducted to ensure the asset is not listed as the opposite.  Assuming the assets are part of one site, a scan is triggered, and a message posted to Slack.  If there are any errors, they are returned to the user in Slack as a message.

If an asset is part of multiple sites, the site listing is returned, and the bot asks the user to pick a site to scan the asset in the context of using: `@insightvm_bot scan 192.168.1.1 site 123`

The bot then continues to check each minute for scan completion. After the scan is complete, the bot posts summary results to Slack. Errors in the scan return the error message as a message in Slack.

# Way Forward
I want to add additional features such as full site scans (already have a branch for that), report generation, and perhaps other maintenance tasks. One of the biggest challenges I have right now is authenticating users.  The bot runs as a low-privilege InsightVM user, which restricts some of the things it can do, including retrieving user access details.  

I have been reluctant to make the bot InsightVM user a `Global Admin` due to security concerns.  That being said, if I did this, then the bot could take a user's email from Slack and ensure that the user has access to the sites and assets they are trying to scan.  This would also be helpful for maintenance actions as only other `Global Admins` would be allowed to perform those actions.

# Summary
This is my first project beyond just simple scripting and my first open-source project. I learned a ton in creating this bot, and making the bot has certainly increased my confidence as a Python programmer.  I relied heavily on my teammates for knowledge and insight about how best to accomplish different parts of the bot. I also have to thank Rackspace for letting me open-source this so that others may benefit.

Well, here's the link.
https://github.com/rackerlabs/insightvm_slackbot

Post adapted and edited from https://ratil.life/nexpose-slack-bot/
