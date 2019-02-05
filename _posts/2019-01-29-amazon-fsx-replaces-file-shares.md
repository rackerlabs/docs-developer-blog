---
layout: post
title: "Amazon's new FSx is a strong replacement for self-managed Windows File Server"
ogTitle: "Amazon's new FSx is a strong replacement for self-managed Windows File Server"
metaDescription: After decades of use Windows File Server are still around and being leveraged daily by corporate networks for sharing files. Now Amazon offers a managed serverless solution to reduce TCO for customers.
ogDescription: After decades of use Windows File Server are still around and being leveraged daily by corporate networks for sharing files. Now Amazon offers a managed serverless solution to reduce TCO for customers.
date: 2019-01-30 00:00
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

Windows File Server have been one of the longest running methods for sharing files in corporate america for decades. Amazon brings its expertise in Serverless to provide a solution for the Total Cost of Ownership traditional on-premise options in the past.

## History

Since before Microsoft Windows 95 graced the hearts of many, corporate america was using file shares to allow companies of all sizes manage the files their various business organizations needed. Early on these were largely Word and Excel documents but expanded to a wide variety of applications over the years. File Shares was an easy system to setup and everybody else could easily access the files they needed. Just setup an H: drive on your Microsoft Windows workstation and you were off and running. There was no specialized application, no Slack or Office365 or Google Drive. Just use Windows Explorer.

In college I setup a file share for my suite mates to use to share mp3 files. We also shared Quake 2 and class notes. It was convenient and built-in with Windows meaning everybody had it.

One of my more recent projects - which leveraged AWS, containers, and other modern architecture - still started with users dropping files in a Windows File Server share. That was the most appropriate interface we had available. Users didn't upload files to an internal portal, or use some desktop client, we just mounted a drive on their machine and asked them to copy files there. Training for this new system was done via an email. 

It is also highly compatible. The SMB protocol has been implemented on a number of other systems including Linux and MacOS, making it a great legacy method for sharing files.

However, while file shares are easy to setup, there is a lot to manage. You need to manage the hardware, like provisioning new drives, setting them up, adding them to pools. Software maintenance takes the form of regular patches to Windows, ensuring proper licensing, and scheduling regular backups.

```arnold
Old, but not obsolete
- Terminator, Terminator Genisys
```

## Amazon FSx

Amazon AWS FSx is Windows File Server on Amazon's world-class serverless infrastructure. Just pick your total size and your throughput and you now have a DFS compatible Windows File Share system accessibly from anywhere within the associated VPC.  There's no hardware to manage, to software to manage, you just pick your values and go.

The system is 100% compatible with SMB 3.1.1 (earlier is supported but not recommended) and is a drop-in replacement for your existing Windows File Server.

Authentication is supported using an AWS Active Directory service.


No more managing hardware. that just goes away.
No more software management. Patches, licenses, backups, and updates all go away.

Provides: 
100% Windows compatability
Performance options, tailor pricing and performance to your specific needs.

"Just works" - drop in replacement for existing systems and processes. Easy adoption.
No protocol implementation over EFS, no re-implementation, just an RDS-like fully managed service. AD and ACL support is all native. Nothing rebuilt.

AD and Windows ACL support
NTFS native 
VSS, volume shadow copies, will be coming.
SMB compat (3.1.1 but earlier are not recommended)
DFS namespaces and DFS replication supported


Directory Sharing with AD coming later.

"Fast and Flexible":
    * "Built on ssd"
    "high throughput"
    "high iops"
    "choose throughput independent of storage"
    "Consistent sub-millisecond latencies"


Ad connector support coming soon
backups in s3
replicates within AZ
monitored hardware
DFS multi-az

CloudFormation coming "in weeks"

secure
encrypted at-rest and in-transit
integrates with KMS/ad
network traffic access via VPC security groups
Admin API via AWS IAM
CloudTrail for monitor and log
PCI-DSS + ISO compliant and HIPAA eligible


Great support:
EC2, VMWare Cloud, WorkSpaces, AppStream, Server 2008+, Windows 7+ Linux (via smb)
cause all SMB 2.0-3.1.1

Fully Manage
provision hardware, manage software, manage backups

Some use cases:
Home directories, LoBs, web, software dev environments, media workflows, analytics

Storage: $0.130 per GB/month
Throughput cap: $2.2 per MBps/month
Backup: $0.050 per GB/month (incremental)

Coming soon
On premise access via Direct Connect and VPN - oh shite... so, no public access.
inter-vpc access via VPC Peering and Transit Gateway (including across accounts and regions)
over public internet is not supported now or in the foreseeable future.

Thanks to DFS, we can achieve up to 3 exabytes of data. Up to 50,000 shares and 3 EiB namespaces.
64 terrabytes per FSx

Robocopy on an ec2 instance is currently supported migration path


















## Conclusion

```arnold
Old, but not obsolete
- Terminator, Terminator Genisys
```

Technologies that are built well tend to last. File Share did exactly what we needed, at the time, and still fulfils a niche in corporate networks.
