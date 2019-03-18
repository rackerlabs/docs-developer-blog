---
layout: post
title: "Amazon's new FSx is a strong replacement for self-managed Windows File Server"
ogTitle: "Amazon's new FSx is a strong replacement for self-managed Windows File Server"
metaDescription: After decades of use Windows File Server are still around and being leveraged daily by corporate networks for sharing files. Now Amazon offers a managed serverless solution to reduce TCO for customers.
ogDescription: After decades of use Windows File Server are still around and being leveraged daily by corporate networks for sharing files. Now Amazon offers a managed serverless solution to reduce TCO for customers.
date: 2019-02-12 00:00
comments: true
author: Matthew Bonig
twitterCreator: "@mattbonig"
published: true
authorIsRacker: true
authorAvatar: https://s.gravatar.com/avatar/17fefeb3c1832175bf6fbe9841368292?s=128
bio: "As a Senior Software Engineer at Rackspace, Matthew draws upon his 15 years of web application development experience to help architect highly-available, fault-tolerant, scalable, and secure AWS environments composed of a wide range of services in the AWS portfolio, including Compute, Storage, Database, Networking, Developer Tools, and more. He is an AWS certified Solutions Architect. His hobbies include hiking the foothills of Colorado and walks with his wife and dogs."
categories:
  - aws
---

Windows File Server have been one of the longest running methods for sharing files in corporate america for decades. Amazon brings its expertise in serverless to provide a solution for the problem of the large Total Cost of Ownership that on-premise options have had in the past.

<!-- more -->

### History

Since before Microsoft Windows 95 graced the hearts of many, companies of all sizes were using file shares to distribute the files their various business organizations needed. Early on these were largely Word and Excel documents but expanded to a wide variety of applications over the years. File shares were an easy system to setup and everybody could access the files they needed. Just setup an H: drive on your Microsoft Windows workstation, and you were off and running. There was no specialized application, no Slack or Office365 or Google Drive. Just use Windows Explorer.

I've setup file shares in my home, my parent's home, college, and small businesses and used them in any company with a Windows laptop.

One of my more recent projects - which leveraged AWS, containers, and other modern architecture - we still started with users dropping files in a Windows File Server share. That was the most appropriate interface we had available. Users didn't upload files to an internal portal, or use some desktop client, we just mounted a drive on their machine and asked them to copy files there. Training for this new system was done via an email. 

It is also highly compatible. The SMB protocol has been implemented on a number of other systems including Linux and MacOS, making it a great legacy method for sharing files.

However, while file shares are easy to setup, there is a lot to manage. You need to manage the hardware, like provisioning new drives, setting them up, adding them to pools. Software maintenance takes the form of regular patches to Windows, ensuring proper licensing, and scheduling regular backups.

### Amazon FSx

**Amazon FSx for Windows File Server** is Windows File Server on Amazon's world-class serverless infrastructure. Just pick your total size and your throughput, and you now have a DFS compatible Windows File Share system accessible from anywhere within the associated VPC.  There's no hardware to manage, no software to manage, you just pick your values and go.

The system is 100% compatible with SMB 3.1.1 (earlier is supported but not recommended) and is a drop-in replacement for your existing Windows File Server. This is because AWS made a conscious decision to not re-implement any APIs, so they're spinning up Windows Servers for you and managing everything. Another full managed-service offering.

Authentication is supported using an AWS Active Directory (AD) service. You can use an AWS managed Active Directory service. AD Connector support is coming soon.

By default, your shares are **not** Multi-AZ. So, if high availability is a must, you can use DFS Namespaces across a few FSx instances. In fact, using Namespaces could get you 3 EB (3 million TBs) of storage (64TB per 50,000 shares).

Currently, this is only accessible from within the associated Virtual Private Cloud (VPC.), so machines on-prem (e.g. your laptops and workstations) don't have access yet. CloudFormation templates also don't exist yet, so management is via the Console or through client API's like Python, Node, or others.  We should soon see CloudFormation support, AD Connector support, and VPN support, resolving many of the initial limitations of FSx. 

### Conclusion

Technologies that are built well tend to last. File Share did exactly what we needed at the time and still serves a powerful role in corporate networks.

While there are some key features lacking here in the beginning, Amazon FSx for Windows File Server is going to be a strong offering once we're past some of these initial growing pains. Yet, this does work well for a lot of legacy software running in EC2 instances that have been using file shares for deployment artifacts, shared content files, and many other use cases. Adoption in this space is available now and yields a high return on value. 

**Update - March 2019**: FSx now [supports](https://aws.amazon.com/about-aws/whats-new/2019/02/amazon-fsx-for-windows-file-server-now-supports-on-premises-access/) on-premise access through AWS Direct Connect or VPN connections, making it very viable in the enterprise.

```
I'm old, not obsolete.
- Terminator, Terminator Genisys
```

<table>
  <tr>If you liked this blog, share it by using the following icons:</tr>
  <tr>
   <td>
       <img src="{% asset_path line-tile.png %}" width=50>
    </td>
    <td>
      <a href="https://twitter.com/home?status=https%3A//developer.rackspace.com/blog/amazon-fsx-replaces-file-shares/">
        <img src="{% asset_path shareT.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50>
    </td>
    <td>
      <a href="https://www.facebook.com/sharer/sharer.php?u=https%3A//developer.rackspace.com/blog/amazon-fsx-replaces-file-shares/">
        <img src="{% asset_path shareFB.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50>
    </td>
    <td>
      <a href="https://www.linkedin.com/shareArticle?mini=true&url=https%3A//developer.rackspace.com/blog/amazon-fsx-replaces-file-shares&summary=&source=">
        <img src="{% asset_path shareL.png %}">
      </a>
    </td>
  </tr>
</table>

</br>

If you have any questions on the topic, comment in the field below.

Learn more about [Rackspace application services](https://www.rackspace.com/application-management).

