---
layout: post
title: 'Cloud Files update and new features'
date: '2013-05-21 8:00'
comments: true
author: Hart Hoover
published: true
categories:
  - Cloud Files
---
{% img right 2013-05-21-cloud-files/cloud_files_logo.png 250 %}

We've announced some [new features for Cloud Files][1] on the [Rackspace Blog][2]
this week. Cloud Files now supports the following features:

**API-only:**

* Container Quotas
* TempURL File Name Overrides
* Bulk Operations (Delete & Auto-Expand Archive)
* Static Large Object support

**Now in Control Panel:**

* Multiple File Upload
* Editing Headers

Features in the Control Panel are great, but I'd rather get my hands dirty with
the API. Let's take a look at the new API features one by one.

<!-- more -->

### Container quotas

You can now set quotas on your Cloud Files containers. The **X-Container-Meta-Quota-Bytes**
header is used to limit the maximum size of a container, in bytes. The
**X-Container-Meta-Quota-Count** header is used to set the maximum object count
of the container. To set either one of these, you can use a `PUT` operation with cURL:

```bash
curl -X PUT -H "X-Container-Meta-Quota-Count: 3" \
> -H "X-Container-Meta-Quota-Bytes: 2097152" \
> -H "X-Auth-Token: 1234567890abcdef" \
> https://storage101.dfw1.clouddrive.com/v1/MossoCloudFS_1234567890abcdef/CONTAINER
```

You can use either header to set the quota you prefer. When the user tries to
exceed the quota, they get a **Upload exceeds quota** message.

### TempURL file name overrides

With the new TempURL file name override feature, you can specify a `filename`
query parameter to override a TempURL’s Content-Disposition header in order to
instruct their browser to save a TempURL file with a specific name. This is done
by appending `&filename=my_file_name` to the end of a TempURL. Basically, if you
have a file called **1234567890abcdefgh** and you want your users to save it as
**file.pdf**, you can use the following URL:

`https://storage101.dfw1.clouddrive.com/v1/MossoCloudFS_1234567890abcdef/CONTAINER/1234567890abcdefgh?temp_url_sig=da39a3ee5e6b4b0d3255bfef95601890afd80709&temp_url_expires=1323479485&filename=file.pdf`

### Bulk operations (delete & auto-expand archive)

Two new bulk operations are now available: delete and archive auto extractions.
You can upload and auto-extract tar archives upon a `PUT` request to your Cloud
Files account. This is done using the query parameter `?extract-archive=format`
and specifying the format of archive file. Accepted formats are tar, tar.gz, and
tar.bz2. Root directories in the archive are converted to containers (if they are
uploaded at the account level) or mapped to pseudo-directory names (if they are
uploaded into existing containers).

#### Upload and extract

Assuming you have a tar archive called `archive.tar`, you can upload and extract
it as a container with the following command:

```bash
curl -X PUT -T archive.tar \
> -H "Content-Type: text/plain"
> -H "X-Auth-Token: 1234567890abcdef" \
> https://storage101.dfw1.clouddrive.com/v1/MossoCloudFS_1234567890abcdef/?extract-archive=tar
```

If you want to upload the contents of `archive.tar` to an existing container,
you can use this command:

```bash
curl -X PUT -T archive.tar \
> -H "Content-Type: text/plain" \
> -H "X-Auth-Token: 1234567890abcdef" \
> https://storage101.dfw1.clouddrive.com/v1/MossoCloudFS_1234567890abcdef/CONTAINER/?extract-archive=tar
```

#### Bulk delete

To delete objects in bulk, create a list of files you wish to delete, then pass
the list in a `DELETE` request:

```bash
$ cat to_delete
CONTAINER/datafile_1
CONTAINER/datafile_2
```

```bash
curl -ik -X DELETE \
> -H "X-Auth-Token: 1234567890abcdef"
> https://storage101.dfw1.clouddrive.com/v1/MossoCloudFS_1234567890abcdef/?bulk-delete -T to_delete
```

### Static Large Object support

Static Large Object Support (SLO) is very similar to Dynamic Large Object (DLO)
support in that it allows the user to upload many objects concurrently and
afterwards download them as a single object. It is different than DLO in that
it does not rely on eventually consistent container listings to do so. Instead,
a user defined manifest of the object segments is used to help guarantee that
every segment in the manifest exists and has matched the specifications. If
everything does match, the user will receive a 2xx response and the SLO object
is ready for downloading. This can improve consistency when uploading multiple
segments concurrently and subsequently downloading the resulting large object a
short time after. Documentation on how to upload multiple objects and a manifest
is available [here][3].

We hope you enjoy these new features!

[1]: http://www.rackspace.com/blog/cloud-files-update-new-api-only-and-control-panel-features/
[2]: http://www.rackspace.com/blog
[3]: http://docs.rackspace.com/files/api/v1/cf-devguide/content/Static_Large_Object-d1e2226.html