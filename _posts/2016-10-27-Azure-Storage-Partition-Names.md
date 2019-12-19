---
layout: post
title: "Azure storage partition names"
date: 2016-10-27 10:22
comments: false
author: Jimmy Rudley
authorAvatar: 'https://en.gravatar.com/userimage/151177997/5bed7e07ee47533cbd34b951d463bcb7.jpg'
bio: “Jimmy Rudley is an Azure Architect at Rackspace and an active member of the Azure community. He focuses on solving large and complex architecture and automation problems within Azure."
published: true
categories:
    - DevOps
    - Azure
---

If you are using Microsoft&reg; Azure&reg; Blob Storage and have a heavy workload, here's something
you can do to improve performance that the majority of people are not doing -
pay attention to the name you use for an Azure storage account.

<!-- more -->

A whitepaper released in 2011 describes the
internals of how Azure Storage works under the hood. It describes how the
partitioning layer uses a range-based partitioning scheme to scale and load
balance the storage system. Using the range-based scheme makes sense in a multi-tenant
world. Objects are now stored within a set of ranges and can help isolate bad
neighbor effect. A hash-based system would help spread out the load, but then
you lose the performance gain of ranges and the bad-neighbor effect is now more profound
across a set of nodes, instead of potentially a smaller group.

If you create multiple storage accounts in an Azure
Resource Manager template, you normally see some kind of storage account
prefix parameter that is consumed during the storage account creation process.
Here is an example of this: ``` "name":
"[concat(parameters('storageAccount'), copyindex())]" ``` , which returns this output: myStorage0, myStorage1, myStorage2, etc. Here is another example that shows hashing the resource group name by using the function **uniqueString** ``` "storageAccountName":
"[concat(uniquestring(resourceGroup().id), 'standardsa')]". ``` This
creates a hash based on the resourceGroup id and concatenate standardsa to
it, but it would be the same prefix hash, not randomly-generated names. The
prefixes generated could potentially put the partitions on the same partition
server due to the sequential naming. A potentially performance impact occurs
when the storage location service decides to rebalance the partition ranges to
different partition servers. This rebalancing operation causes latency of
storage calls. However, if you create a way distribute writes across multiple
partition servers using a non sequential naming pattern, you can scale our
performance linearly with load.

How can you generate unique names that are not following a prefix pattern? This
is a good question. Researching what ARM template functions exist, I was surprised
there was nothing on generating a random name. There have been requests to
Microsoft for providing this functionality, but these suggestions were
[turned down](https://feedback.azure.com/forums/281804-azure-resource-manager/suggestions/8499160-provide-a-template-function-to-generate-a-name).

Talking with a peer, Alex Campos, from our Rackspace Azure team, I learned that he
wrote a generic storage template that answers the question of how to generate a unique
name. There is a function available in an ARM template called uniqueString
which will generate a hash based on the objects passed in. In my ARM template,
I create two storage accounts for each VM in my copy loop: Premium_LRS and
Standard_LRS storage account types.

 ```
"name":
"[concat(substring(uniqueString(subscription().id, resourceGroup().id,
'cd', string(copyindex())) ,0,10), 'cd', copyIndex())]",
 ```

 ```
"name":
"[concat(substring(uniqueString(subscription().id, resourceGroup().id,
deployment().name, string(copyIndex())) ,0,10), 'cd',
copyIndex(),'ssd')]",
```

For the first storage account, I generate a hash based on
the subscription id, resourcegroup id, a string called 'cd', and the current
integer of my index loop. I then concatenate the hash, 'cd', and the current
integer of my index loop. With the second storage account, I add the
deployment name to my hash function. I want my hash to be unique, so it must
differ from the uniqueString call that I did previously. I also now add 'ssd' to the
end of my storage account name since this is being used to generate my
premium_lrs storage and will help me identify it.



The output generates the following messages:

    15:20:57 - [VERBOSE] 3:20:57 PM - Resource
    Microsoft.Storage/storageAccounts 'tnisayz3qdcd0' provisioning status is
    running

    15:20:57 - [VERBOSE] 3:20:57 PM - Resource
    Microsoft.Storage/storageAccounts 'hi4fn4pgjccd1' provisioning status is
    running

    15:21:22 - [VERBOSE] 3:21:22 PM - Resource
    Microsoft.Storage/storageAccounts 'v4pfo5nwdkcd0ssd' provisioning status is
    succeeded

    15:21:28 - [VERBOSE] 3:21:28 PM - Resource
    Microsoft.Storage/storageAccounts 'a725b73hpkcd1ssd' provisioning status is
    succeeded

Using the examples above, the partition map which tracks the index range
partitions, intially may have had mystorage0, mystorage1, mystorage2 on partition
server 1. With my modified code to generate a unique prefix hash, the partitions
now should be spread out on multiple partition servers since I did not follow a
sequential naming pattern.

I encourage you to read [the whitepaper](http://sigops.org/sosp/sosp11/current/2011-Cascais/printable/11-calder.pdf)
and the [Azure storage performance checklist](https://azure.microsoft.com/en-us/documentation/articles/storage-performance-checklist/#subheading47)
article for more insight into the Azure Storage system for designing partitioning strategies.



