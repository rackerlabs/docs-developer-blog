---
layout: post
title: 'Cloud Block Storage volume cloning announced!'
date: '2014-03-19 10:01'
comments: true
author: Jose Malacara
published: true
categories:
  - General
---

Today our Control Panel team announced support for Cloud Block Storage volume
cloning. Some of our savvier users may have noticed that volume cloning was
silently released as an API-only feature back in early November. Volume
cloning (ergo volume copy) allows for the creation of a new volume from an
existing one. While this is a pretty big feature, it would have been easy to
miss, as its simply the addition of a source_volid parameter to the existing
create volume call.

<!-- more -->

Here’s what that looks like in the API:

```bash
curl https://dfw.blockstorage.api.rackspacecloud.com/v1/<Customer ID>/volumes \
 -X POST -H "X-Auth-Project-Id: <Customer ID>" \
 -H "User-Agent: curl 7.30.0 (x86_64-apple-darwin13.0) libcurl/7.30.0 SecureTransport zlib/1.2.5" -H \
 "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: <Auth Token>" \
 -d '{"volume": {"source_volid": "2fcbe723-f12b-4fdd-b71b-b1cf4786eceb", "size": 100, "display_name": "test01", "volume_type": "SATA"}}'
...

{
    "volume": {
        "attachments": [],
        "availability_zone": "nova",
        "bootable": "false",
        "created_at": "2014-02-13T04:56:52.000000",
        "display_description": null,
        "display_name": "test01",
        "id": "e35a2cc8-3353-4184-b07d-311cc6d9cc8f",
        "metadata": {},
        "size": 100,
        "snapshot_id": null,
        "source_volid": "2fcbe723-f12b-4fdd-b71b-b1cf4786eceb",
        "status": "creating",
        "volume_type": "SATA"
    }
}
```

This call kicks off a LVM copy on write and then transfers the data directly
over to a new blank volume on a separate storage node over a fast local
network. The key word in that sentence is direct, as you will no longer need
to use a Cloud Files snapshot as an intermediate step when moving data between
or increasing the size of your volumes. Do keep in mind if you do use cloning
to increase the size of your volumes, it’s simply a direct copy and will not
automagically resize your filesystem. Be sure to resize your filesytem
(if supported) in order to take advantage of the new larger clone.

A quick test show that the cloning process can take less than 5 minutes for a
100 GB volume. For those of you used to making volume copies using the
snapshot method, you can see how can be pretty advantageous. Before volume
cloning, creating a copy of a volume meant creating a snapshot of the volume,
snapshotting that volume into Cloud Files, and then creating a new volume
using from the snapshot. The entire volume-to-snapshot-to-volume process
could take upwards of an hour for that same 100 GB volume. Volume cloning
eliminates the need to copy data in and out of Cloud Files, which
translates to a faster and less complex volume copy procedure.

Volume cloning can also be used to change the size and type when creating a
copy of a volume:

```bash
curl https://dfw.blockstorage.api.rackspacecloud.com/v1/<Customer ID>/volumes \
-X POST -H "X-Auth-Project-Id: <Customer ID>" \
-H "User-Agent: curl 7.30.0 (x86_64-apple-darwin13.0) libcurl/7.30.0 SecureTransport zlib/1.2.5" \
-H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: <Auth Token>" \
-d '{"volume": {"source_volid": "2fcbe723-f12b-4fdd-b71b-b1cf4786eceb", "size": 100, "display_name": "test01", "volume_type": "SATA"}}'
```

Once you’ve created a clone of a volume, you can confirm the source volume ID when you list your volume’s details:

```bash
curl https://dfw.blockstorage.api.rackspacecloud.com/v1/<Customer ID>/volumes/detail \
-X GET -H "X-Auth-Project-Id: <Customer ID>" \
-H "User-Agent: curl 7.30.0 (x86_64-apple-darwin13.0) libcurl/7.30.0 SecureTransport zlib/1.2.5" \
-H "Accept: application/json" -H "X-Auth-Token: <Auth Token>"
...

{
    "volumes": [
        {
            "attachments": [],
            "availability_zone": "nova",
            "bootable": "false",
            "created_at": "2014-02-13T04:56:52.000000",
            "display_description": null,
            "display_name": "test01",
            "id": "e35a2cc8-3353-4184-b07d-311cc6d9cc8f",
            "metadata": {},
            "size": 100,
            "snapshot_id": null,
            "source_volid": "2fcbe723-f12b-4fdd-b71b-b1cf4786eceb",
            "status": "available",
            "volume_type": "SATA"
        },
        {
            "attachments": [
                {
                    "device": "/dev/xvdb",
                    "id": "2fcbe723-f12b-4fdd-b71b-b1cf4786eceb",
                    "server_id": "4e0392d4-c35e-4183-80a1-7d0feb79d016",
                    "volume_id": "2fcbe723-f12b-4fdd-b71b-b1cf4786eceb"
                }
            ],
            "availability_zone": "nova",
            "bootable": "false",
            "created_at": "2014-02-12T21:35:24.000000",
            "display_description": null,
            "display_name": "Volume-1",
            "id": "2fcbe723-f12b-4fdd-b71b-b1cf4786eceb",
            "metadata": {},
            "size": 100,
            "snapshot_id": null,
            "source_volid": null,
            "status": "in-use",
            "volume_type": "SATA"
        }
    ]
}
```

Speed is volume cloning’s main advantage when compared to snapshots, plus a few more differences to keep in mind:

* A snapshot cannot be directly used as a volume. You need to create a volume from the snapshot before you can attach it to your server.
* Snapshots are stored redundantly in Cloud Files, whereas volumes require the end user to handle redundancy (ie using RAID or LVM).
* Long-term storage of snapshots is less expensive than volumes. You could however, reduce the cost of an SSD volume by cloning it to a SATA volume.  A great use case would be to use an SSD volume for your production workloads and then keep a SATA clone around as a backup, plus you would still have the ability to snapshot it into Cloud Files for increased redundancy.

If you’re used to working with snapshots, you find similarities when working with clones:

* While not required, it is a good idea to detach your volume from your server before you create a clone.
* As soon as the initial clone call returns a 200 response, the point in time clone procedure has been initiated, and you may continue using the original volume.
* You cannot simultaneously create multiple clones (or mixing snapshots and clones) from the same volume at the same time.

We’ll continue to iterate based on customer feedback on CBS so please let us know how you plan to use volume cloning and how we can improve the feature based on your use case. While there are tradeoffs between snapshots and clones, if your application is time sensitive, volume cloning makes a lot of sense to the time it takes to create copies of your CBS volumes.

