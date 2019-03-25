---
layout: post
title: "Web proxy server and deployment"
date: 2019-03-26 00:00
comments: true
author: Syed Zabiullah
published: true
authorIsRacker: true
categories:
  - General
  - Developers
  - Architecture
  - Configuration Management
metaTitle: "Web proxy server and deployment"
metaDescription: "This post discusses web proxy servers and how to deploy them."
ogTitle: "Web proxy server and deployment"
ogDescription: "This post discusses web proxy servers and how to deploy them."
---

A proxy server is a computer system that sits between the client, who requests
a web document, and the target server (another computer system), which serves
the document. In its simplest form, a proxy server facilitates communication
between the client and the target server without modifying requests or replies.

<!-- more -->

When you initiate a request for a resource from the target server, the proxy
server hijacks the connection, represents itself as a client to the target
server, and requests the resource on your behalf. If a reply is received, the
proxy server returns it, establishing communication with the target server.

![]({% asset_path 2019-03-26-web-proxy-server-and-deployment/Picture1.png %})

*Image source*: Wikipedia [https://mn.wikipedia.org/wiki/%D0%9F%D1%80%D0%BE%D0%BA%D1%81%D0%B8_%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80](https://https://mn.wikipedia.org/wiki/%D0%9F%D1%80%D0%BE%D0%BA%D1%81%D0%B8_%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80)

### What is a proxy?

A proxy represents someone else or has the authority to act on behalf of another.

Proxy servers have the following characteristics:

- Act as an intermediary for requests sent by a client that wants resources
  from other servers in the computer network.
- Can be any computer system or an application.
- Are created when you install and run proxy software on a computer.
- Enable you to cache your web content and return it quickly on subsequent
  requests. This helps system administrators, who often struggle with delays
  and bandwidth usage issues.

Proxy servers have the following advantages:

- Obscure client IP addresses by using network address translation
  (NAT) to remap the private IP address to another IP address. This hides
  the client IP address.
- Block malicious traffic by controlling inbound & outbound traffic.
- Block sites, such as unauthorized sites, adult sites, and so on.
- Log activity by maintaining log records of traffic.
- Improve performance by caching the uniform resource locators (URLs). The
  proxy server reuses the cached URL when a client sends the data to the same
  URL that they used previously.
- Reduce bandwidth usage.

### Proxy server architecture

The following image shows basic web proxy architecture:

![]({% asset_path 2019-03-26-web-proxy-server-and-deployment/Picture2.png %})

*Image source*: [https://jagvindernetwokingvideos.blogspot.com/2013/07/proxy-server-installation-video-4.html](https://jagvindernetwokingvideos.blogspot.com/2013/07/proxy-server-installation-video-4.html)

As shown in the preceding image, you can install a web proxy server between the
switch and the router. Following are a few available web proxy servers:

- FreeProxy
- Wingate
- UltraSurf
- Apache HttpServer
- Freegaree
- Anonymizer
- Provoxy
- HAProxy
- SquidProxy

### Proxy server installation prerequisites

Before you install web proxy server software, ensure that the server has two
network interface cards (NICs). One NIC should connect to an internal switch
and the other NIC should connect to the router that is connected to the Internet.

### Download, install, and deploy a Wingate proxy server

Use the following steps to download, install, and deploy a Wingate proxy server:

1. Download the [Wingate software](www.wingate.com) and install it.

2. Enter the 30-day trial license or your purchased license when prompted.

3.	Configure the web proxy server with an IP address, a gateway, and Domain Name
   Servers (DNS).

### Block a site

The following steps demonstrate how to block a site from your network by using
a proxy server:

1. Start Wingate. The following window with a left-side navigation pane displays:

   ![]({% asset_path 2019-03-26-web-proxy-server-and-deployment/Picture3.png %})

<ol start=2>
    <li>Select <b>Wingate->Web Access Control->Access Rule</b> and click <b>Add rule</b>.</li>
    <li>Fill in the rule name and the site to block (such as XYZ.com), and
    click <b>Add</b>, as shown in the following image:</li>
</ol>

   ![]({% asset_path 2019-03-26-web-proxy-server-and-deployment/Picture3.png %})

<ol start=4>
    <li>Enable the time interval to block a website as shown in the following image:</li>
</ol>

   ![]({% asset_path 2019-03-26-web-proxy-server-and-deployment/Picture4.png %})

<ol start=5>
    <li>Click <b>Finish</b> to block the site URL. When someone tries to access
    the site, a screen similar to the following one displays:</li>
</ol>

   ![]({% asset_path 2019-03-26-web-proxy-server-and-deployment/Picture5.png %})


### Conclusion

Proxy servers on large networks help to improve reliability by blocking malicious
data, and they enable you to cache your web content and return it quickly on
subsequent requests.


<table>
  <tr>If you liked this blog, share it by using the following icons:</tr>
  <tr>
   <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://twitter.com/home?status=https%3A//developer.rackspace.com/blog/web-proxy-server-and-deployment/">
        <img src="{% asset_path shareT.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://www.facebook.com/sharer/sharer.php?u=https%3A/web-proxy-server-and-deployment/">
        <img src="{% asset_path shareFB.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://www.linkedin.com/shareArticle?mini=true&url=https%3A//developer.rackspace.com/blog/web-proxy-server-and-deployment&summary=&source=">
        <img src="{% asset_path shareL.png %}">
      </a>
    </td>
  </tr>
</table>

</br>

Learn more about [Rackspace Application services](https://www.rackspace.com/application-management/managed-services).

If you have any questions on the topic, comment in the field below.
