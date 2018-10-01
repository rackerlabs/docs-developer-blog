---
layout: post
title: "Containers and Cloud Portability"
date: 2018-09-28 00:00
comments: true
author: Sri Rajan
published: true
authorIsRacker: true
categories:
  - Docker
  - Azure
  - aws

---

One of the benefits of containers is the promise of portability.  The Docker mantra is to build, ship, and run. Containers also promise the ability to, with few changes, move from a developer’s laptop to a production environment and, in the same vein, the ability to move from a data center to the cloud or to many clouds. However, adopting containers alone does not guarantee this.  At the core, containers are just a better way of packaging your applications. While they ensure a degree of technical compatibility across many clouds, they don’t ensure complete portability by themselves. In this post, we will look at some of the many considerations from the portability lens.

<!-- more -->

##Container networking


Each cloud provides its own constructs for building networks. They often map to traditional setups like subnets, load balancing, and access control lists. They provide additional features that are cloud specific, like being able to scale horizontally or managed VPNs. In addition, they often have container-specific features such as the [AWS VPC CNI](https://github.com/aws/amazon-vpc-cni-k8s) or [GKE integrated load balancing](https://cloud.google.com/kubernetes-engine/docs/how-to/internal-load-balancing). The portability question now hinges on where you draw the line on what you can use?  Do you make hard choices like avoiding features such as VPN and deploy your own network appliance?  Do you build your own load balancing setup that scales with load? This is complex problem to solve, and, correct answer lies in making smart trade-offs and to use the cloud-specific technologies to a certain extent. 

##Container infrastructure

All cloud providers started with providing virtual machines as a service. In many ways that is the lowest form of a cloud service today. They all provide comparable options and pricing models. You can choose to run your containers on the basic building block of virtual machine as that provides the best in terms of portability. But, you still need to be mindful of other features like auto scaling and instance grouping, which are provider specific. So, even if you chose the most basic building block, you have decisions to make on the other aspects. In general, this is easier to solve by adding some abstraction or mindfully using those cloud-specific features.

##Container orchestration platform

The container infrastructure needs to run something to be able to use containers at scale and in production. This *something* is provided by technologies like Docker Swarm or Apache Mesos + Marathon or the increasingly popular, [Kubernetes](https://kubernetes.io/).  To make this easier, cloud providers provide Platform as a Service (PaaS) options such as [AWS Elastic Kubernetes Service](https://aws.amazon.com/eks/), [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/), or [Azure Kubernetes Service](https://azure.microsoft.com/en-gb/services/kubernetes-service/). In this layer, Kubernetes seems like a good selection. It is open source, and all the major cloud providers have the infrastructure to run your own Kubernetes cluster or a PaaS offering. The PaaS offerings are [CNCF compliant](https://github.com/cncf/k8s-conformance), which helps with the portability. However, there is still some provider lock-in that you may need to avoid. For example, you can avoid using container-optimized operating systems from the providers and use your preferred operating system. Similarly, you could decide to run your own container image registry. Providers like Google Cloud Platform also offer [vulnerability scanning](https://cloud.google.com/container-registry/docs/get-image-vulnerabilities), which is very useful. This space will see an increasing number of services and options in the coming year. The portability question comes down to the degree of management burden you are willing to take on to run your own setup as opposed to these ready-to-use features.

##Application packaging

The container image packages your application with other dependencies. But, there is a layer around it that can almost be termed as the *true* packaging. This includes things such as mapping volumes, environment configuration, number of copies, and so on. This goes hand in hand with the orchestration platform.  Docker Compose and Kubernetes Objects are some examples. This layer needs to be the same across the all environments (including the developer’s environment), not just clouds. The decision of the container orchestration platform influences this heavily. In addition, the orchestration platform has specific cloud provider plugins that allow for a more seamless integration. An example of this is [GCP persistent volumes](https://cloud.google.com/kubernetes-engine/docs/concepts/persistent-volumes). This is another area of trade-offs, if portability is of concern.

##Application data

Data can be defined in many ways. From a business perspective, data includes things like user information, product catalogs, or any related information that lives in a database or a file system.  For portability, do you avoid using cloud provider services like AWS RDS,Azure SQL, or Google Big Query?  If yes, then how do you build a scalable data layer that is cloud portable? This is not an easy problem. There is a significant cost to running this yourselves, and, like with networking, the answer probably lies in making some trade-offs and to use the cloud-specific technologies to a certain extent. 

##Application metadata

This data is technical data and includes application configurations such as usernames, passwords, or environment settings. Best practices suggest that you should not store this embedded in containers. The question becomes where **do** you store this? Cloud providers have services for secret or configuration storage. Orchestration platforms like Kubernetes provide mechanisms that are a better fit when it comes to portability of this type of data. Package this data into the orchestration platform for easier portability. Even here, some subtleties hinder portability. Do you leverage [AWS KMS](https://aws.amazon.com/kms/) or [Cloud KMS](https://cloud.google.com/kms/docs/secret-management) for secrets or build your own systems?


##So, how do you approach it?

The questions posed so far paint a good picture of the challenges faced when it comes to portability. The answers are very subjective and depend on your goals and situation. A solution would be to write down the must-haves and the nice-to-haves and do a review with both technical and business viewpoints.  From the business side, you do need to understand the true management cost of these decisions and weigh them against the risk of lock-in. From the technical side, you need to understand the designs that are possible and weigh them against complexity, performance, and scalability. Containers help in some respects but don't necessarily solve for portability on the whole. Simply put, the more cloud-provider native you are, the less portable you become. Conversely, the less provider native you are, the more management burden is on your plate and the more complex your operations.  You need to figure out where you want to be in the sliding scale of portability vs complexity and portability vs management burden.

<table>
  <tr>If you liked this blog, share it by using the following icons:</tr>
  <tr>
   <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://twitter.com/home?status=https%3A//developer.rackspace.com/blog/applications-monitoring-creating-a-smoother-financial-close/">
        <img src="{% asset_path shareT.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://www.facebook.com/sharer/sharer.php?u=https%3A//developer.rackspace.com/blog/applications-monitoring-creating-a-smoother-financial-close/">
        <img src="{% asset_path shareFB.png %}">
      </a>
    </td>
    <td>
       <img src="{% asset_path line-tile.png %}" width=50 >
    </td>
    <td>
      <a href="https://www.linkedin.com/shareArticle?mini=true&url=https%3A//developer.rackspace.com/blog/applications-monitoring-creating-a-smoother-financial-close&summary=&source=">
        <img src="{% asset_path shareL.png %}">
      </a>
    </td>
  </tr>
</table>

</br>
