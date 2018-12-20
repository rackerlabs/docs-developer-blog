# Contributing to our Blog

First, thanks for your interest in contributing and helping us craft quality
content for our official Developer Blog. Second, in order to make contributing
a pleasant experience while maintaining a visual and content standard, complete
these steps before writing and submitting a blog entry for publishing.

#### Preparing for your blog entry

1. Fork this repo (https://github.com/rackerlabs/docs-developer-blog), then
   clone your fork.

2. Before you start working, make sure your local content is up-to-date and
   merged with the right upstream branch:

      ```bash
         git remote add upstream git@github.com:rackerlabs/docs-developer-blog.git
         git checkout master
         git fetch upstream
         git checkout -b name-of-your-branch
         git merge upstream/master
      ```

3. Create a file inside the `_posts/` directory with the following naming
   convention: `YYYY-MM-DD-title-of-your-post.md`, where `YYYY-MM-DD` is the
   date you want you entry to be published. The published URL for your post
   becomes `https://developer.rackspace.com/blog/title-of-your-post/` when
   published.

#### Formatting your post

The post should contain front-matter, an excerpt, and the actual content with
optional images.

##### Front-matter

Add Jekyll front-matter (or metadata) to the top of the file you created in
the previous step. for example:

```
---
layout: post
title: "Blog entry title"
date: YYYY-MM-DD 23:59
comments: true
author: Author(s) name(s)
published: true
authorIsRacker: true
categories:
    - This Category
    - That Category
    - Other Category
#
# The following properties are OPTIONAL and affect the text and image that
# appear by default in link previews when sharing blog posts. To customize
# any of the items, remove the `" #"` at the start of the line and fill in
# the desired value.
#
# metaTitle:
# metaDescription:
# ogTitle:
# ogDescription:
# ogImage:
# twitterCreator: "@your_twitter_handle" # NOTE: The quotes are required!
# twitterDescription:
# twitterTitle:
---
```

**NOTE:** The "ogImage" _must_ be a fully-qualified URL. If you'd like to use an
image asset that is being uploaded as part of your blog post, the pattern for the
final URL is as follows:

  `<rackspace CDN>/<image name>-<sha256 hash>.<image extension>`

Where:

  * `<rackspace CDN>` is `https://657cea1304d5d92ee105-33ee89321dddef28209b83f19f06774f.ssl.cf1.rackcdn.com`
  * `<image name>` is the case-sensitive name of the image _not including the extension_.
  * `<sha256 hash>` is the 64-character hex output from running the command `sha256sum /path/to/image`
  * `<image extension>` is `jpg`, `png`, etc.

Example:

  * `https://657cea1304d5d92ee105-33ee89321dddef28209b83f19f06774f.ssl.cf1.rackcdn.com/default-og-image-46fb3587dedfdf950188fabbddd596d67e6b699374a7f4e36b43046d7a24fd09.jpg`

If you'd like to use an image asset from your post that _shouldn't_ appear in the post itself, you can include `style="display: none"` on the `<img />` tag to hide it within the post while triggering the necessary plugin code to ensure it is made available on the CDN based on the above naming convention.

Make sure that the dates in the file name and front-matter match.

You can optionally add a picture from gravatar using the following metadata line:

```authorAvatar: 'https://gravatar.com/avatar/Whatever-the-Image-ID-is'```

Available categories include the following:

- Ansible
- Architecture
- Automation
- AWS
- Azure
- Chef
- Cloud Files
- Cloud Monitoring
- Cloud-networks
- Cloud Servers
- Configuration Management
- Database
- Developers
- DevOps
- Docker
- Events
- General
- Java
- Jclouds
- Jenkins
- Mailgun
- Neutron
- NodeJS
- OpenStack
- Oracle
- Orchestration
- OSAD
- Private Cloud
- Python
- Rackspace-private-cloud
- SDK
- Security

If you'd like to use a category that is not in the list, please send an email
to infodev@rackspace.com. To avoid being flooded with categories, which might apply
to only one or two blogs, we have automated throttling. However, notify us so
that we can discuss your ideas for a new category.

##### Excerpt

Include an excerpt marker after your first paragraph or so to separate the
preview text that appears on the blog index page from the full article. To do
so, use the following HTML comment:

```
The excerpt paragraph, which should give teh reader a taste of what's to come.

<!-- more -->

The rest of your article.
```

The marker comment ``<!-- more -->`` must be on its own line, starting at
column 1, and separated from content on either side by a single blank line.

##### Images

**To include images in your post**, place them in the directory
`_assets/img/` within a new subdirectory that has the same name as the file
containing your post. Within your post, use the following markup:

```markdown
![Alt text here]({% asset_path YYYY-MM-DD-title-of-your-post/filename.png %})
```

**To wrap text around an image on the right**, use code similar to the following:

```
<img class="blog-post right" src="{% asset_path 2015-06-17-built-an-app-on-openstack-at-qcon-ny-2015/qcon.png %}"/>Last week I went to QCon NY 2015 to be both a student and a teacher in their tutorial track. They follow the standard pattern of having 2 days of tutorials prior to the conference proper. To understand QCon a bit better, here's their mission statement.
```

#### Adding social media share icons

To add social media share icons at the end of your blog, include the following code:

Be sure to update the links with your blog name!  If your blog file is *2018-09-01-late-breaking-news.md*, you'd replace *applications-monitoring-creating-a-smoother-financial-close* with *late-breaking-news* in all three URLs.

```
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
```

#### Writing your post

We recommend that you conform as much as possible to the [Style Guide](https://developer.rackspace.com/docs/style-guide/).

#### Submitting your blog entries

Follow these steps to submit your entry for publication.

1. Submit a PR (pull request) against `master` branch.
2. Do everything in the PR template checklist.
3. Once the PR successfully builds, you can preview your entry by clicking on
   the preview link in the Git GUI.  Sometimes, if you push a new commit to your
   PR, the changes don't show up in the new staging link.  To force a rebuild,
   add a blank line to the bottom of your post and commit the change.
4. When you're satisfied, the InfoDev team will do a quick editorial review
   of the content and suggest changes, if necessary.
5. After the content is ready to go, the InfoDev team will publish the blog on
   the date that you selected.

Thanks again for your interest in contributing!
