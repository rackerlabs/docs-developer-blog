---
layout: post
title: Adding devices into an existing Swift cluster
date: '2014-09-29 13:46'
comments: true
author: Angela Streeter
published: true
categories: []
bio: "Angela Streeter is a cloud technology instructor at Rackspace, where she teaches OpenStack in public and private training sessions. Angela and her team spend their time evangelizing OpenStack through training, blogs and contributions. Angela graduated from Texas State University with a BS in computer science and a minor in mathematics. She has worked as a software developer and prior to the training team was a linux systems administrator at Rackspace for the customer support teams. Angela's twitter handle and freenode nick is angelastreeter. Angela blogs at https://streetstack.net."
---

If you already have an existing Swift cluster and you would like to add additional storage, you can use the swift-ring-builder command on the ring builder files from any server that you have the utility installed on. Once you update the files, you will need to push them out to all the nodes in your cluster.

<!-- more -->

#### My existing demo cluster with four zones.

*I am using loop devices for demonstration purposes on an all-in-one virtual machine.*

```
swift-ring-builder container.builder

container.builder, build version 10
512 partitions, 3.000000 replicas, 1 regions, 4 zones, 4 devices, 0.00 balance
The minimum number of hours before a partition can be reassigned is 1
Devices:    id  region  zone      ip address  port  replication ip  replication port      name weight partitions balance meta
             0       1     1   192.168.56.56  6001   192.168.56.56              6001     loop2 1000.00        384    0.00 
             1       1     2   192.168.56.56  6001   192.168.56.56              6001     loop3 1000.00        384    0.00 
             2       1     3   192.168.56.56  6001   192.168.56.56              6001     loop4 1000.00        384    0.00 
             3       1     4   192.168.56.56  6001   192.168.56.56              6001     loop5 1000.00        384    0.00
```

```
swift-ring-builder object.builder

object.builder, build version 10
512 partitions, 3.000000 replicas, 1 regions, 4 zones, 4 devices, 0.00 balance
The minimum number of hours before a partition can be reassigned is 1
Devices:    id  region  zone      ip address  port  replication ip  replication port      name weight partitions balance meta
             0       1     1   192.168.56.56  6000   192.168.56.56              6000     loop2 1000.00        384    0.00 
             1       1     2   192.168.56.56  6000   192.168.56.56              6000     loop3 1000.00        384    0.00 
             2       1     3   192.168.56.56  6000   192.168.56.56              6000     loop4 1000.00        384    0.00 
             3       1     4   192.168.56.56  6000   192.168.56.56              6000     loop5 1000.00        384    0.00
```

```
swift-ring-builder account.builder

account.builder, build version 10
512 partitions, 3.000000 replicas, 1 regions, 4 zones, 4 devices, 0.00 balance
The minimum number of hours before a partition can be reassigned is 1
Devices:    id  region  zone      ip address  port  replication ip  replication port      name weight partitions balance meta
             0       1     1   192.168.56.56  6002   192.168.56.56              6002     loop2 1000.00        384    0.00 
             1       1     2   192.168.56.56  6002   192.168.56.56              6002     loop3 1000.00        384    0.00 
             2       1     3   192.168.56.56  6002   192.168.56.56              6002     loop4 1000.00        384    0.00 
             3       1     4   192.168.56.56  6002   192.168.56.56              6002     loop5 1000.00        384    0.00
```

1. Use the **swift-ring-builder** command to add in the additional storage. I show an example for adding in two devices to the **account.builder** file. You will need to do the same for the object and container builder files as well. In this demo cluster all the rings will utilize the same storage devices. In a real production cluster you may do this differently and designate storage for the account, object and container rings separately. It is not necessarily recommended to do that because Swift will take care of distributing and replicating the data across all of the devices.

    **Note: You will need to determine what weight to use. In a production cluster, most likely, you will want to slowly add in new storage devices by using a lower weight (or percentage). When I originally built the rings in this cluster I used a 100% weight of 1000. I am using the same 1000 to add in these devices. If I only wanted to add in 20% of the storage I would use the weight 200.**

    ```
    cd /etc/swift

    swift-ring-builder account.builder add r1z5-192.168.56.56:6002/loop6 1000
    swift-ring-builder account.builder add r1z6-192.168.56.56:6002/loop7 1000
    ```

    **Account builder file after adding the new devices**

    ```
    swift-ring-builder account.builder

    account.builder, build version 12
    512 partitions, 3.000000 replicas, 1 regions, 6 zones, 6 devices, 100.00 balance
    The minimum number of hours before a partition can be reassigned is 1
    Devices:    id  region  zone      ip address  port  replication ip  replication port      name weight partitions balance meta
                 0       1     1   192.168.56.56  6002   192.168.56.56              6002     loop2 1000.00        384   50.00 
                 1       1     2   192.168.56.56  6002   192.168.56.56              6002     loop3 1000.00        384   50.00 
                 2       1     3   192.168.56.56  6002   192.168.56.56              6002     loop4 1000.00        384   50.00 
                 3       1     4   192.168.56.56  6002   192.168.56.56              6002     loop5 1000.00        384   50.00 
                 4       1     5   192.168.56.56  6002   192.168.56.56              6002     loop6 1000.00          0 -100.00 
                 5       1     6   192.168.56.56  6002   192.168.56.56              6002     loop7 1000.00          0 -100.00
    ```

2. Use the rebalance option along with the **seed** value you used to build your rings. In my case we used the **seed** value 1337.

    ```
    swift-ring-builder account.builder rebalance 1337
    swift-ring-builder container.builder rebalance 1337
    swift-ring-builder object.builder rebalance 1337
    ```

    **After the rebalance here is what my account builder file looks like:**

    ```
    account.builder, build version 13
    512 partitions, 3.000000 replicas, 1 regions, 6 zones, 6 devices, 1.17 balance
    The minimum number of hours before a partition can be reassigned is 1
    Devices:    id  region  zone      ip address  port  replication ip  replication port      name weight partitions balance meta
                 0       1     1   192.168.56.56  6002   192.168.56.56              6002     loop2 1000.00        259    1.17 
                 1       1     2   192.168.56.56  6002   192.168.56.56              6002     loop3 1000.00        256    0.00 
                 2       1     3   192.168.56.56  6002   192.168.56.56              6002     loop4 1000.00        256    0.00 
                 3       1     4   192.168.56.56  6002   192.168.56.56              6002     loop5 1000.00        256    0.00 
                 4       1     5   192.168.56.56  6002   192.168.56.56              6002     loop6 1000.00        254   -0.78 
                 5       1     6   192.168.56.56  6002   192.168.56.56              6002     loop7 1000.00        255   -0.39
    ```

3. Ensure the newly updated **ring** files are owned by the correct user and push them out to all nodes in the cluster.

    ```
    /etc/swift/account.ring.gz
    /etc/swift/container.ring.gz
    /etc/swift/object.ring.gz
    ```

#### Manual pages
[Ubuntu swift-ring-builder manual page](https://manpages.ubuntu.com/manpages/precise/man8/swift-ring-builder.8.html)

[Linux swift-ring-builder manual page](https://linux.die.net/man/1/swift-ring-builder)

#### Other resources
[SwiftStack Blog on how to add capacity gradually](https://swiftstack.com/blog/2012/04/09/swift-capacity-management)

#### Rackspace Training Team
[For the schedule of available public classes, or to inquire about private training for your organization contact the Rackspace Training Team.](https://training.rackspace.com)
