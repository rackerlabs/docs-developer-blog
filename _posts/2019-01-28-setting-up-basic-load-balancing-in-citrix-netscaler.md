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
tasks such as traffic optimization, L4-L7 load balancing and web app
acceleration while maintaining data security.

<!-- more -->

### Introduction

NetScaler ADC monitors server health and allocates network and application
traffic to additional servers for efficient use of resources. It also performs
several kinds of caching and compression. It can be used as a proxy server,
process Secure Socket Layer (SSL) requests instead of servers (SSL Offloading).

This blog covers the basic Hyper Text Transfer Protocol (HTTP) site load
balancing configuration.

### Typical load balancing traffic flow

The following step comprise the typical load balancing traffic flow for NetScaler:

1.	A user enters a URL into their browser.
2.	The URL's Domanin Name Server (DNS) record points to one of the public Virtual
   Internet Protocols (VIP) on the NetScaler and identifies the traffic's
   protocol (such as HTTP port 80 traffic).
3.	NetScaler then passes that traffic to one of the servers in the server pool,
   based on the balancing method defined (such as round robin, persistence, and
   so on).
4.	The servers send back the page or application that the user requested by
   using a Load Balancing Virtual IP (LBVIP).
5.	The LBVIP routes the traffic to internet by setting the source to `LBVIP`.
6.	The web page or application displays on the user computer.

The following image shows this traffic flow:

![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture1.png %})

*Image Source:* [https://docs.citrix.com/en-us/netscaler/12/load-balancing/load-balancing-configure-monitors.html](https://docs.citrix.com/en-us/netscaler/12/load-balancing/load-balancing-configure-monitors.html)

### Prerequisites

Before configuring NetScaler load balancing, perform the following steps:

1. Load the necessary license to NetScaler.
2. Configure the `MGMT` port for management access.
3. Configure DNS servers and Subnet IP Address (SNIP) in the same server subnet
   and allow the Virtual Local Area Network (LAN) in the switch trunk port that
   is connected to NetScaler.

### Configuration

To configure NetScaler load balancing, perform the following steps:

#### A. Add backend servers

To add the backend servers, perform the following steps:

1. Connect to the management IP of your NetScaler.
2. Select **Login > Configuration > Traffic Management > Load Balancing > Servers**.
3. Click **Add**.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture2.png %})

3. Choose a naming convention for the first server and enter its IP address.
   This example uses `Web-01`.
4. Click **Create**.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture3.png %})

5. Repeat steps 3 and 4 for the other backend web servers.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture4.png %})

#### B. Create a service group

To create a service group, perform the following steps:

1. Group these servers together in a service group configuration by choosing
   **Traffic Management > Load Balancing > Service Groups**.
2. Click **Add**.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture5.png %})

3. Name the service group and set the protocol to `HTTP`.
4. Click **OK**.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture6.png %})

5. Click **No Service Group members**.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture7.png %})

6. Click `Server Based`.
7. Select all the servers with the search arrow or add servers directly by IP
   base instead of creating them individually.
8. Set the server listening port (For example, the HTTP protocol is TCP port 80).
9. Click **Create**.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture8.png %})

10. Click **OK**.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture9.png %})

#### C. Change the monitoring

To change the monitoring, perform teh following steps:

1. Change the monitoring from `SNIP` to `Backend servers`.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture10.png %})

2. Click **No service Group Monitor Binding** and select the required monitoring
   binding. In this case, choose the HTTP NetScaler that has a monitor for HTTP
   pre-configured.
3. Click the search arrow, select **http-ecv > Bind**.
4. Click **Done**.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture11.png %})

#### D. Create a virtual server

To create a virtual server, perform teh following steps:

1. Create a virtual server by choosing **Configuration > Traffic Management >
   Load Balancing > Virtual Servers**.
2. Click **Add**.
3. Give the virtual server a name.
4. Set the protocol to `HTTP`.
5. Specify the IP address, which should be the VIP (the NetScaler presents to
   the outside world).
6. Set the port to `80`.
7. Click **OK**.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture12.png %})

8. Add the previously created group by clicking **No load balancing Virtual
   Servers Service Group Binding** and click **Select**.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture13.png %})

9. Click **Bind** and click **Done**.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture14.png %})

10. Save your work and wait for the VIP to come up.

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture15.png %})

### Test the configuration

To test the configuration, use a different web ‘Welcome’ pages on each of the
servers. When you refresh the page, you can see that the NetScaler is doing its
job and balancing the requests across both back-end web servers as shown in the
following image:

         ![]({% asset_path 2019-01-28-setting-up-basic-load-balancing-in-citrix-netscaler/Picture16.png %})

### Conclusion

Use a load balancer to distribute the load across multiple web and application
servers. Load balancers can also do SSL offloading to expose the application or
URL to internet in a secure way by installing SSL certificate. If you have only
one backend server with SSL offloading, you should install the SSL certificate
on the server and expose to internet with all the  appropriate security measures
and patches. You should open only the required ports on firewall for the LBVIPs
or the backend server with SSL offloading when you expose it to internet.

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
