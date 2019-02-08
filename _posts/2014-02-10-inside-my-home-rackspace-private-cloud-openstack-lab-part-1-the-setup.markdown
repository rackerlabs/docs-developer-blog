---
layout: post
title: 'Inside my home Rackspace Private Cloud, OpenStack lab, Part 1: The setup'
date: '2014-02-10 18:00'
comments: true
author: Kevin Jackson
published: true
categories:
  - OpenStack
  - Private Cloud
---

Over the past year I’ve been using a home lab for quick, hands-on testing of [OpenStack](http://openstack.org) and [Rackspace Private Cloud](http://www.rackspace.com/cloud/private/), and a number of people have requested information on the setup. Throughout the next few blog posts I will explain what I’ve got. This serves two purposes: 1) documentation of my own setup as well as 2) hopefully providing information that other people find useful – and not everything is about OpenStack.

This first post is about the tech involved and how it is set up. In subsequent posts I’ll go into further detail and then detail the installation of Rackspace Private Cloud.

<!-- more -->

### The servers

Let’s first take a look at the servers I’m using:
5 x [HP MicroServer N40L](http://www.amazon.co.uk/gp/product/B00AHQUX86/)

* openstack1
  * eth0 (onboard) 192.168.1.101
  * eth1 ([TG-3468 Low Profile Gigabit PCI-X Adapter](http://www.amazon.co.uk/dp/B001OQSZQ0))
  * 2Gb DIMM (Original Supplied)
  * 4Gb DIMM ([Integral 4GB DDR3-1333 DIMM](http://www.amazon.co.uk/dp/B005CN3B2E))
* openstack2
  * eth0 (onboard) 192.168.1.102
  * eth1 ([TG-3468 Low Profile Gigabit PCI-X Adapter](http://www.amazon.co.uk/dp/B001OQSZQ0))
  * 2Gb DIMM (Original Supplied)
  * 4Gb DIMM ([Integral 4GB DDR3-1333 DIMM](http://www.amazon.co.uk/dp/B005CN3B2E))
* openstack3
  * eth0 (onboard) 192.168.1.103
  * eth1 (TG-3468 Low Profile Gigabit PCI-X Adapter)
  * 4Gb DIMM (Integral 4GB DDR3-1333 DIMM)
* openstack4
  * eth0 (onboard) 192.168.1.104
  * eth1 ([TG-3468 Low Profile Gigabit PCI-X Adapter](http://www.amazon.co.uk/dp/B001OQSZQ0))
  * 4Gb DIMM ([Integral 4GB DDR3-1333 DIMM](http://www.amazon.co.uk/dp/B005CN3B2E))
* openstack5
  * eth0 (onboard) 192.168.1.105
  * eth1 ([TG-3468 Low Profile Gigabit PCI-X Adapter](http://www.amazon.co.uk/dp/B001OQSZQ0))
  * 2Gb DIMM (Original Supplied)
  * 2Gb DIMM (Original Supplied)

The N40L is an incredibly cheap, 4 SATA Bay (+ CDROM Bay), low-power server with supplied 250Gb SATA. It’s a single CPU AMD Turion II processor with two cores that supports Hardware-VT.  It has been superseded by the [HP MicroServer N45L](http://www.amazon.co.uk/gp/product/B00AHQUX86) and often found with cash-back deals, meaning these usually come in under $215/£130.

There seems to be some caution when choosing memory for these things, with the documentation reporting they support up to 8Gb. I’ve read about people successfully running 16Gb, and through my own trial I grabbed the [cheapest memory](http://www.amazon.co.uk/dp/B005CN3B2E) I could get and found it worked.

When choosing the PCI-X NICs and other cards, be aware that you need to use low-profile ones. The NICs I added to mine are low-profile, but the metal backing plate isn’t. A quick email to [TP-Link customer services](http://uk.tp-link.com/support/contact/?categoryid=530) will get you some low-profile backing plates free of charge.
Networked Attached Storage

I have two [QNAP](http://www.qnap.com/useng/index.php?sn=69&lang=en-us) NAS devices. One functions as my main network storage (nas / 192.168.1.1) with two drives in, running DHCP for my home subnet, DNS for all connected devices and Proxy (primarily used to compensate for the slow 6Mbps to 7Mbps ADSL speed I get when installing packages on my servers). The second (nas2 / 192.168.1.2) acts as a TFTP server and proxy for my servers, as well as providing a replication/backup for my primary NAS. The reason I run a proxy and TFTP next to my servers, rather than on the main NAS, is the wireless link I have between my servers and my router. Although WiFi speeds are OK, it’s a much more efficient setup (and I have two floors between my servers and WiFi router). Powerline adapters? I tried them, but due to my home having an [RCD](http://www.esc.org.uk/public/home-electrics/rcd-faqs/) (Residual Current Device), it made Powerline adapters useless.
* nas
  * [QNAP TS-210](http://www.amazon.co.uk/dp/B004LOANJ4) (QTS 4.0.2)
  * 2 x Western Digital Caviar Green 500GB SATA 6Gb/s 64MB Cache – OEM (WD5000AZRX)
  * Raid 1 EXT4
  * eth0 (onboard) 192.168.1.1
  * DHCP (Dnsmasq)
  * DNS (Dnsmasq)
  * Proxy (Squid)
* nas2
  * [QNAP TS-121](http://www.amazon.co.uk/dp/B00C1YMKSS) (QTS 4.0.2)
  * 1 x Western Digital Caviar Green 500GB SATA 6Gb/s 64MB Cache – OEM (WD5000AZRX)
  * EXT4
  * eth0 (onboard) 192.168.1.2
  * TFTP (Dnsmasq)
  * Proxy (Squid)
### Network Kit

Essentially, I have two parts to my network –separated by two floors of a house and connected using WiFi bridging – all on a 192.168.1.0/24 subnet. I have unmanaged switches connecting the servers and NAS so there’s nothing here that’s highly exciting, but it’s presented here for clarity and completeness (and useful if you think you’ll need to WiFi bridge two parts of your network together)

* TP-Link [TL-WA901ND](http://www.amazon.co.uk/dp/B002YETVXC) Wireless-N PoE Access Point (300Mbps)
  * Bridge Mode
  * Connects LAN based servers to wireless network/clients
* TP-Link [TD-W8980](http://www.amazon.co.uk/dp/B00B1NSB8S) N600 Dual Band Wireless ADSL Modem Router
  * WiFi Router (2.4GHz + 5GHz)
  * ADSL Router disabled (for now)
  * DHCP/DNS disabled (Dnsmasq used instead)
* TP-Link [TL-SG1024](http://www.amazon.co.uk/dp/B003UWXFM0) 24-port Ethernet Switch
  * 24-Port Switch connecting servers to NAS and Wifi Bridge (TL-WA901ND)
(I think I should get sponsorship from TP-Link for this post!)

Overall, it looks like this:

{% img center 2014-02-10-inside-my-home-rackspace-private-cloud-openstack-lab-part-1-the-setup/homelabsetup.png %}

Hopefully, having this detailed background info will aid you in setting up your own OpenStack environment big or small.

In the next post, I’ll cover QNAP Dnsmasq Configuration providing DHCP, DNS and TFTP for my network, which allows me to PXE boot my N40L servers to kick Ubuntu and Rackspace Private Cloud.

*This is a guest post from [Kevin Jackson](https://twitter.com/itarchitectkev) - it was originally published on his blog [right here](http://openstackr.wordpress.com/2014/02/02/home-rackspace-private-cloud-openstack-lab-part-1/).*

