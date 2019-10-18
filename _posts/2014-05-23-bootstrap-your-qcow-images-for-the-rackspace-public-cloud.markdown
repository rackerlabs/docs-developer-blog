---
layout: post
title: Bootstrap your QCOW Images for the Rackspace Public Cloud
date: '2014-05-23 10:30'
comments: true
author: Mike Metral
published: true
categories:
  - OpenStack
---

In the world of Cloud Computing, hypervisors and disk image formats come in
various shapes & sizes and are by no means made equal.
In the [Rackspace Public Cloud](https://rackspace.com/cloud/servers), we utilize Citrix XenServer as our
hypervisor, which requires that our disk images be in the
[VHD](https://en.wikipedia.org/wiki/VHD_\(file_format\)) format.

<!-- more -->

However, it is very common for folks who utilize the popular
[KVM](https://en.wikipedia.org/wiki/Kernel-based_Virtual_Machine) hypervisor to
want to leverage an existing, custom [QCOW](https://en.wikipedia.org/wiki/Qcow)
image when working with our Public Cloud.

To minimize the redundancy of recreating duplicate images, it would be beneficial
to be able take an existing or new QCOW image and modify it to operate on our Public
Cloud. This would immensely cut down the maintenance of base images customers
create that they wish to share across multiple cloud infrastructures.

In this tutorial, I will walk you through the following steps:

* Pull a vanilla
[UEC](https://en.wikipedia.org/wiki/Ubuntu_Enterprise_Cloud#Cloud_computing)
version of an [Ubuntu 14.04](https://cloud-images.ubuntu.com/trusty/current/) QCOW image
* Modify the OS to work with the Rackspace Public Cloud
* Convert it to the required VHD format XenServer expects
* Upload the image to [Cloud Files](https://rackspace.com/cloud/files) for registration with [Cloud Images](https://www.rackspace.com/cloud/images/)
* Utilize Cloud Images to register the image for future instantiation

## Notes
* This in an __unofficial__ tutorial, so the conversion is __not guaranteed__ to fully function in the entirety of the Rackspace Public
  Cloud platform
* Converted OS's other than Ubuntu 14.04 have not been thorougly tested with this tutorial.
  Therefore, it is recommended you too use Ubuntu 14.04

## Assumptions & Recommendations

* An existing [Public Cloud](https://mycloud.rackspace.com) account
* [python-novaclient](https://www.rackspace.com/knowledge_center/article/installing-python-novaclient-on-linux-and-mac-os) is installed
* [pyrax](https://github.com/rackspace/pyrax) is installed
    * __Note__: Public Cloud pyrax credentials are expected to be stored in ~/pyrax_rc, formatted as such:

```
[rackspace_cloud]
username = <RAX_USERNAME>
api_key = <RAX_API_KEY>
```
* At least an Ubuntu 12.04 __bare-metal__ machine is recommended to perform the conversion, as issues rose
  with QCOW image mounting in certain virtualized environments

## How-To Steps

__0. Preamble__

For the sake of not showing lengthy code-blocks, all the scripts referred to
below are located in a [Github repo](https://github.com/metral/rpc_rd/tree/master/qcow_image)

It is recommended you clone and operate out of this repo:
```
git clone https://github.com/metral/rpc_rd.git
cd rpc_rd/qcow_image/
```

__1. Compile Xen tool 'vhd-util'__

* Pulls Xen 4.4.0 source and __only__ compiles the tools sub-directory
* The tools subdirectory contains the `vhd-util` utility used to convert a RAW disk image into VHD format

```
./compile_vhdutil.sh
```

__2. Create a vanilla Ubuntu 14.04 UEC QCOW Image__

* Downloads a Ubuntu 14.04 UEC QCOW image, if an existing QCOW image is not provided
* Mounts the QCOW image
* Bootstraps the image with the necessary modifications needed for the Rackspace Public Cloud (via chroot)
* Unmounts the QCOW image

Usage: `./modify_qcow.sh <OPTIONAL_QCOW_IMAGE>`
```
$ ./modify_qcow.sh
```

Outputs: `trusty-server-cloudimg-amd64-disk1.img`

* A vanilla Ubuntu 14.04 QCOW image that has been modified for the Public Cloud

* __Note:__ If you want to make custom changes to the OS, this is your chance to do
  so
  * Mount the QCOW image as done in the
  [modify_qcow.sh](https://git.io/-4PHGQ), then via chroot, make any necessary changes you wish to persist

__3. Convert the QCOW to VHD__

* First, the script converts the QCOW to RAW as vhd-util expects RAW
* Then, it converts the RAW image into VHD using vhd-util

Usage: `./qcow_to_vhd.sh <QCOW_INPUT_PATH> <VHD_OUTPUT_PATH>`
```
$ ./qcow_to_vhd.sh ./trusty-server-cloudimg-amd64-disk1.img .
```

Outputs: `trusty-server-cloudimg-amd64-disk1.vhd`

* A Ubuntu 14.04 VHD image that is ready for the Public Cloud

__4. Upload the VHD image to Cloud Files & register the image in Cloud Images__

* Uses pyrax to upload the new VHD image up to the Rackspace Public Cloud region with the custom image name provided
    * Specifically, uploads the VHD to the Cloud Files in the specified region
    * Then, registers the image with Cloud Images

Usage: `python upload_to_cloudimages.py <PUBLIC_CLOUD_REGION> <VHD_PATH> <CUSTOM_IMAGE_NAME>`
```
python upload_to_cloudimages.py ORD trusty-server-cloudimg-amd64-disk1.vhd "my_ubuntu_1404"
```

__5. Boot a VM with the newly registered custom image__

```
nova boot --image="my_ubuntu_1404" --flavor=performance1-2 my_ubuntu_1404_test
```

## About the Author
Mike Metral is a Solution Architect at Rackspace in the Private Cloud Product
organization. Mike joined Rackspace in 2012 with the intent of helping
OpenStack become the open standard for cloud management. At Rackspace, Mike has
led the integration effort with strategic partner RightScale; aided in the
assessment, development, and evolution of Rackspace Private Cloud; as well as
served as the Chief Architect of the Service Provider Program. Prior to joining
Rackspace, Mike held senior technical roles at Sandia National Laboratories
performing research and development in Cyber Security with regards to
distributed systems, cloud and mobile computing. You can follow Mike on Twitter
[@mikemetral](https://twitter.com/mikemetral) and Github as
[metral](https://github.com/metral)

## Reference Material
* [Convert a raw image to XenServer – VHD](https://blogs.citrix.com/2012/10/04/convert-a-raw-image-to-xenserver-vhd/)
* [Cloud Images API Developer Guide](https://docs.rackspace.com/images/api/v2/ci-devguide/content/ch_image_preface.html)
* [Pyrax Images Doc](https://github.com/rackspace/pyrax/blob/master/docs/images.md)
