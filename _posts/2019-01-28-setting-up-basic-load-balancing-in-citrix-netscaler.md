---
layout: post
title: "Setting up basic load balancing in Citrix NetScaler"
date: 2019-01-28 00:00
comments: true
author: Karthik Siva
published: true
authorIsRacker: true
categories:
  - general
metaTitle: "Setting up basic load balancing in Citrix NetScaler"
metaDescription: "Setting up basic load balancing in Citrix NetScaler"
ogTitle: "Setting up basic load balancing in Citrix NetScaler"
ogDescription: "Setting up basic load balancing in Citrix NetScaler"
---

The NetScaler Application Delivery Controller (ADC) is a Citrix&reg; Systems
core networking product. ADC improves the delivery speed and quality of
applications for an end user. The product helps business customers perform
tasks such as traffic optimization, L4-L7 load balancing, and web app
acceleration while maintaining data security.

<!-- more -->

### Introduction

NetScaler ADC monitors server health and allocates network and application
traffic to additional servers for efficient use of resources. It also performs
several kinds of caching and compression. It can be used as a proxy server to
process Secure Socket Layer (SSL) requests instead of servers (SSL offloading).

This blog covers the basic Hyper Text Transfer Protocol (HTTP) site load
balancing configuration.

### Typical load balancing traffic flow

The following steps comprise the typical load balancing traffic flow for NetScaler:

1.	A user enters a URL into their browser.
2.	The URL's Domain Name Server (DNS) record points to one of the public Virtual
   Internet Protocols (VIP) on NetScaler and identifies the traffic's
   protocol (such as HTTP port 80 traffic).
3.	NetScaler then passes that traffic to one of the servers in the server pool,
   based on the balancing method defined (such as round robin, persistence, and
   so on).
4.	The servers send back the page or application that the user requested by
   using a Load Balancing Virtual IP (LBVIP).
5.	The LBVIP routes the traffic to the Internet by setting the source to `LBVIP`.
6.	The web page or application displays on the user computer.

The following image shows this traffic flow:

![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture1.png %})

*Image Source:* [https://docs.citrix.com/en-us/netscaler/12/load-balancing/load-balancing-configure-monitors.html](https://docs.citrix.com/en-us/netscaler/12/load-balancing/load-balancing-configure-monitors.html)

### Prerequisites

Before configuring NetScaler load balancing, perform the following steps:

1. Load the necessary license to NetScaler.
2. Configure the `MGMT` port for management access.
3. Configure DNS servers and the Subnet IP Address (SNIP) in the same server subnet
   and allow the Virtual Local Area Network (LAN) in the switch trunk port that
   is connected to NetScaler.

### Configuration

To configure NetScaler load balancing, perform the following steps:

#### Add backend servers

To add the backend servers, perform the following steps:

1. Connect to the management IP of your NetScaler.
2. Select **Login > Configuration > Traffic Management > Load Balancing > Servers**.
3. Click **Add**.

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture2.png %})

<ol start=4>
    <li>Choose a naming convention for the first server and enter its IP address.
   This example uses `Web-01`.</li>
    <li>Click <b>Create</b>.</li>
</ol>

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture3.png %})

<ol start=6>
    <li>Repeat steps 3 and 4 for the other backend web servers.</li>
</ol>

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture4.png %})

#### Create a service group

To create a service group, perform the following steps:

1. Group these servers together in a service group configuration by choosing
   **Traffic Management > Load Balancing > Service Groups**.
2. Click **Add**.

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture5.png %})

<ol start=3>
    <li>Name the service group and set the protocol to <b>HTTP</b>.</li>
    <li>Click <b>OK</b>.</li>
</ol>

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture6.png %})

<ol start=5>
    <li>Click <b>No Service Group Member</b>.</li>
</ol>

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture7.png %})

<ol start=6>
    <li>Click <b>Server Based</b>.</li>
    <li>Select all the servers with the search arrow or add servers directly by
    IP base instead of creating them individually.</li>
    <li>Set the server listening port (For example, the HTTP protocol is TCP port 80).</li>
    <li>Click <b>Create</b>.</li>
</ol>

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture8.png %})

<ol start=10>
    <li>Click <b>OK</b>.</li>
</ol>

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture9.png %})

#### Change the monitoring

To change the monitoring, perform the following steps:

1. Change the monitoring from `SNIP` to `Backend servers`.

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture10.png %})

<ol start=2>
    <li>Click <b>No service Group Monitor Binding</b> and select the required
    monitoring binding. In this case, choose the HTTP NetScaler that has a
    monitor for HTTP preconfigured.</li>
    <li>Click the search arrow, select <b>http-ecv > Bind</b>.</li>
    <li>Click <b>Done</b>.</li>
</ol>

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture11.png %})

#### Create a virtual server

To create a virtual server, perform the following steps:

1. Create a virtual server by choosing **Configuration > Traffic Management >
   Load Balancing > Virtual Servers**.
2. Click **Add**.
3. Give the virtual server a name.
4. Set the protocol to `HTTP`.
5. Specify the IP address, which should be the VIP that NetScaler presents to
   the outside world.
6. Set the port to `80`.
7. Click **OK**.

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture12.png %})

<ol start=8>
    <li>Add the previously created group by clicking <b>No load balancing Virtual
   Servers Service Group Binding</b> and click <b>Select</b>.</li>
</ol>

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture13.png %})

<ol start=9>
    <li>Click <b>Bind</b> and click <b>Done</b>.</li>
</ol>

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture14.png %})

<ol start=10>
    <li>Save your work and wait for the VIP to come up.</li>
</ol>

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture15.png %})

### Test the configuration

To test the configuration, use different web **Welcome** pages on each of the
servers. When you refresh the page, you can see that the NetScaler is doing its
job and balancing the requests across both back-end web servers as shown in the
following image:

   ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture16.png %})

### Conclusion

Use a load balancer to distribute the load across multiple web and application
servers. Load balancers can also do SSL offloading to expose the application or
URL to the Internet in a secure way by installing an SSL certificate. If you
have only one back-end server with SSL offloading, you should install the SSL
certificate on the server and expose the server to the Internet with all the
appropriate security measures and patches. You should open only the required
ports on the firewall for the LBVIPs or the back-end server with SSL offloading
when you expose it to the Internet.

<table>
  <tr>If you liked this blog, share it by using the following icons:</tr>
  <tr>
   <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://twitter.com/home?status=https%3A//developer.rackspace.com/blog/setting-up-basic-load-balancing-in-citrix-netscaler/">
        <img src="{% asset_path shareT.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://www.facebook.com/sharer/sharer.php?u=https%3A//developer.rackspace.com/blog/setting-up-basic-load-balancing-in-citrix-netscaler/">
        <img src="{% asset_path shareFB.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://www.linkedin.com/shareArticle?mini=true&url=https%3A//developer.rackspace.com/blog/setting-up-basic-load-balancing-in-citrix-netscaler&summary=&source=">
        <img src="{% asset_path shareL.png %}">
      </a>
    </td>
  </tr>
</table>

</br>

If you have any questions on the topic, comment in the field below.

Learn more about [Rackspace application services](https://www.rackspace.com/application-management).
