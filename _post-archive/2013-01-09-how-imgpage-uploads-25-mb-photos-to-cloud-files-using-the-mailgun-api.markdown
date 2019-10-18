---
layout: post
title: "How ImgPage uploads 25\_MB photos to Cloud Files using the Mailgun API"
date: '2013-01-09 15:41'
comments: true
author: Paul Finn
categories:
  - Mailgun
  - Python
---
*The team over at Mailgun just posted a Python tutorial written by Mailgun customer [Paul Finn](https://twitter.com/@paul_finn_) about how to use Python and the Mailgun API to upload large images to Cloud Files.  The use case for the post is uploading photos from your phone, but the same process could be used anytime to want to parse an email attachment and store it in the cloud.  You can check out the [full Mailgun and python tutorial](https://blog.mailgun.com/python-tutorial-how-imgpage-lets-you-upload-25-mb/) at the Mailgun blog, but we have the highlights here. --Hart*
<!-- more -->
##Parsing incoming emails using the Mailgun Routes API

Mailgun can automatically parse any email it receives and POST the whole message or just one part via HTTP.  To do this, you need to create a [route](https://documentation.mailgun.net/user_manual.html#routes) within Mailgun. A route is what Mailgun calls the logic that tells their system what to do with each incoming email it receives. For my photo upload app, [ImgPage](https://www.imgpage.com/), I configured Mailgun to parse each incoming email received at inbox@imgpage.com and POST the details to my server.

```python
requests.post("https://api.mailgun.net/v2/routes",
	auth=("api", os.environ.get("MAILGUN_KEY", "your-api-key"))),
	data=MultiDict([("description", "ImgPage Inbox Processing"),
		("expression", "match_recipient('inbox@imgpage.com')"),
		("action", "forward('https://imgpage.com/mailgun-endpoint/')"),
		("action", "stop()")]))
```

A cool trick about Mailgun: you aren’t limited by just matching on email recipients. You can match on email headers like subject line and also use regular expressions. You can create routes programmatically, as demonstrated above, or you can create routes using the Mailgun dashboard after logging in.  Here are the full [inbound email parsing API specs](https://documentation.mailgun.net/user_manual.html#routes).

When it comes to the attachments, Mailgun does the heavy lifting for us and will POST the information we need about any and all attachments up to 25MB (actually the max size is 1 or 2 KB less than 25 MB since space needs to be reserved for email headers). In this simplified example, I’m checking out the request to verify that there is at least one attachment and the attachment has a common photo file extension that we are expecting (if not, return an HTTP 415 error).

```python
@app.route('/mailgun-endpoint', methods=['POST'])
 def mailgun_endpoint(): 
  if(len(request.files) > 0):
   for attachment in request.files.values():
    file_name, file_extension = os.path.splitext(attachment.filename)
    if file_extension.lower() not in ['.jpg', '.gif', '.png', '.bmp']:
      abort(415) #Unsupported Media Type 
```

##Uploading photos to Rackspace Cloud Files 
Once the email was parsed by Mailgun, I was able to upload to Cloud Files using the Cloud Files API.  Here are the basic steps:

```python
import cloudfiles
import uuid
import os

conn = cloudfiles.get_connection(username=hsimpson, api_key='kwyjibo')
images = conn.create_container('images')

#Create a unique ID for a filename
image_attachment = images.create_object('%s%s') % (str(uuid.uuid4()), file_extension)
image_attachment.load_from_filename(attachment.filename)
```

In the case of ImgPage, it’s important that everything inside the images container is publicly reachable with a unique URL. After uploading, you can request the public URI from Cloud Files.

```python
image_attachment.public_uri()
	>>'https://c1234.cdn.cloudfiles.rackspacecloud.com/6a8f43...ab3cb7.jpg'
```

As you can see, Cloud Files is easy and simple to work with. 

##Conclusion
Routing incoming emails and parsing attachments is a breeze with Mailgun. I was able to pair Mailgun’s recipient matching and forwarding actions with Cloud Files to create ImgPage. Without having Mailgun, I probably wouldn’t have tackled this project to begin with due to the difficulties of parsing incoming email. Mailgun gets two thumbs up from me for solving a tough problem and creating a stable and well-documented API to go with it.
