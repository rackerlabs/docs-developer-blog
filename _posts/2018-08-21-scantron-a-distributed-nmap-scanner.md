---
layout: post
title: "Scantron - A Distributed nmap Scanning Framework"
date: 2018-08-21 00:00
comments: true
author: Brennon Thomas
published: true
authorIsRacker: true
categories:
  - Security
  - Automation
  - Python
---

![scantron robot]({% asset_path 2018-08-21-scantron-a-distributed-nmap-scanner/scantron_300x300.jpg %})

# Background

The Threat and Vulnerability Analysis team at Rackspace is charged with providing internal vulnerability scanning, penetration testing, and red/purple teaming capabilities to reduce cyber-based threats, risk, and exposure for the company.  One of our tasks, as part of meeting certain compliance objectives, is to ensure systems are not exposed from various networking "perspectives" without going through a bastion first.

<!-- more -->

Another task our team handles is conducting penetration tests against tens of thousands of devices.  Every penetration test starts out with a network scan to see what devices are on the network.  Initial scanning and reconnaissance is done against thousands of devices and can take several days, so our scanning and target collection solution must scale.

As drivers of ruthless automation within the greater Global Enterprise Security organization (see [InsightVM Slack Bot](https://developer.rackspace.com/blog/insightvm-nexpose-slackbot/)), our team regularly squeezes every last capability out of an Application Programming Interface (API) when possible.  While we are big fans of [Rapid7's InsightVM (Nexpose) platform and API](https://www.rapid7.com/resources/rackspace-automates-and-scales-with-rapid7/), the capability was a little too heavy for what we were trying to accomplish, and for various other reasons, we pursued an alternative.

As a result, we developed Scantron to meet the network segmentation validation and penetration testing requirements to aid our team.  We wanted a system that could:

* Automate nmap scanning based off schedules
* Scale to scan thousands of devices form multiple locations
* Provide initial targets for penetration tests
* Collect results and perform post processing
* Normalize results for Splunk ingestion to facilitate system owner consumption and remediation

We use Scantron to answer questions like:

* What systems are accessible from the office or customer perspective without requiring a bastion?
* What out-of-band management interfaces (Dell Remote Access Controller - DRAC or Integrated Lights Out - iLO) are not properly segmented on their own network and are exposed to office or customer environments?
* How many devices have an nginx web server with a vulnerable banner?
* How exposed are we to some new or emerging threat?

Having the data in Splunk allows us to provide dashboards for system owners, quickly carve out mini missions for penetration tests, and provide an ingestible data source for our Threat Intelligence team.

# What is Scantron?

The juicy technical details can be found in the project's [Racker Labs GitHub page](https://github.com/rackerlabs/scantron).

Scantron is a distributed nmap scanner comprised of two components:

* A Master node that consists of a web front-end used for scheduling scans and storing nmap scan targets and results
* Agents that pull scan jobs from Master and conduct the actual nmap scanning

![]({% asset_path 2018-08-21-scantron-a-distributed-nmap-scanner/scantron_architecture_overview.png %})

A majority of the application's logic is purposely placed on Master to make the agents as "dumb" as possible.  All nmap target files and nmap results reside on Master and are shared through a network file share (NFS) leveraging SSH tunnels.  The agents call back to Master periodically using a REST API to check for scan tasks and provide scan status updates.

Scantron is coded for Python3 exclusively and leverages Django for the web front-end, Django REST Framework as the API endpoint, and PostgreSQL as the database.  It comes complete with Ubuntu-focused Ansible playbooks for smooth deployments.  Scantron has only been tested on Ubuntu 16.04.3 and 18.04.1, but it might be compatible with other operating systems with some slight modifications.

Scantron relies heavily on utilizing SSH port forwards (`-R` or `-L`) as an umbilical cord to the agents.  Either an SSH connection from `Master --> agent` or `agent --> Master` is acceptable and may be required depending on different firewall rules, but tweaking the port forwards and autossh commands will be necessary.  If you are unfamiliar with these concepts, there are some great overviews and tutorials out there such as the following sites:

* <https://help.ubuntu.com/community/SSH/OpenSSH/PortForwarding>
* <https://www.systutorials.com/39648/port-forwarding-using-ssh-tunnel/>
* <https://www.everythingcli.org/ssh-tunnelling-for-fun-and-profit-autossh/>

I was originally using the [python-nmap](https://xael.org/pages/python-nmap-en.html) library to wrap the nmap commands, but it lacked the `--resume` [nmap switch](https://nmap.org/book/man-output.html) that can be used to resume scans that have a normal (-oN) or gnmap (-oG) output file, and I didn't feel like customizing the library.  This switch was critical for some of the longer running scans that crashed sometimes.  Instead, nmap scans are kicked off using Python's `subprocess` module.

# Inspiration

Scantron's inspiration comes from these individuals and projects and definitely warrants a shout out.

* nmap by Gordon "fyodor" Lyon (<https://nmap.org/>)
* Original requirements document from nmap's creator (<https://nmap.org/soc/HostedScan>)
* dnmap (<https://sourceforge.net/projects/dnmap/>)
* Minions (<https://github.com/sixdub/Minions>)
* rainmap (<https://svn.nmap.org/rainmap/>) / (<https://github.com/axtl/rainmap>)
* rainmap-lite (<https://github.com/cldrn/rainmap-lite>)

# Summary

I want to thank my current teammates, a former teammate (for getting the beta into production), Global Enterprise Security leadership, and Rackspace for supporting this work and allowing it to be open-sourced.  Any bugs, feature requests, and issues can be submitted through the official GitHub repo for the project: <https://github.com/rackerlabs/scantron>.

Happy scanning!
