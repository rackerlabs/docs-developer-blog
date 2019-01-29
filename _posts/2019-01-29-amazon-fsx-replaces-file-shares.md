---
layout: post
title: "Amazon's new FSx is a strong replacement for self-managed Windows File Shares"
ogTitle: "Amazon's new FSx is a strong replacement for self-managed Windows File Shares"
metaDescription: After decades of use Windows File Shares are still around and being leveraged daily by corporate networks for sharing files. Now Amazon offers a managed serverless solution to reduce TCO for customers.
ogDescription: After decades of use Windows File Shares are still around and being leveraged daily by corporate networks for sharing files. Now Amazon offers a managed serverless solution to reduce TCO for customers.
date: 2019-01-29 00:00
comments: true
author: Matthew Bonig
twitterCreator: "@mattbonig"
published: false
authorIsRacker: true
authorAvatar: https://s.gravatar.com/avatar/17fefeb3c1832175bf6fbe9841368292?s=128
bio: "As a Senior Software Engineer at Rackspace, Matthew draws upon his 15 years of web application development experience to help architect highly-available, fault-tolerant, scalable, and secure AWS environments composed of a wide range of services in the AWS portfolio, including Compute, Storage, Database, Networking, Developer Tools, and more. He is an AWS certified Solutions Architect. His hobbies include hiking the foothills of Colorado and walks with his wife and dogs."
categories:
  - aws
  - Developers
---

Windows File Shares have been one of the longest running methods for sharing files in corporate america for decades. Amazon brings its expertise in Serverless to provide a solution for the Total Cost of Ownership traditional on-premise options in the past.

## History

Since before Microsoft Windows 95 graced the hearts of many, corporate america was using Microsoft Windows File Shares to allow companies of all sizes manage the files their various business organizations needed. Early on these were largely Word and Excel docs but expanded to a wide variety as applications began using file shares as well. File Share was an easy system to setup and everybody else could easily access the files they needed. Just setup an H: drive on your Microsoft Windows workstation and you were off and running. There was no specialized application, no Slack or Office365 or Google Drive, just use files.

In college I setup a file share for my suite mates to use to share mp3 files. We also shared Quake 2 and class notes. It was convenient and built-in with Windows meaning everybody had it (Apple hadn't taken over colleges yet).

One of my more recent projects - which leveraged AWS, containers, and other modern architecture - still started with users dropping files in a Windows File Share. That was the most appropriate interface we had available. Users didn't upload files to an internal portal, or use some desktop client, we just mounted a drive on their machine and asked them to copy files there. Training for this new system was done via an email. 

However, it's never known to be a resilient system. Largely, this is due to improper implementations. But, most large corporations have built strong and performant file shares for a decade. And while companies have largely migrated to SharePoint or Slack or Github for file sharing, Windows File Share still has a solid place in business networks.

```arnold
Old, but not obsolete
- Terminator, Terminator Genisys
```

## Enter Amazon FSx

Amazon AWS FSx is File Shares on Amazon's world-class serverless infrastructure.













## Conclusion

```arnold
Old, but not obsolete
- Terminator, Terminator Genisys
```

Technologies that are built well tend to last. File Share did exactly what we needed, at the time, and still fulfils a niche in corporate networks.
