---
layout: post
title: "Serve Static Content From A Storage Account With A Default Document"
date: 2018-06-01 00:00
comments: true
author: Jimmy Rudley
published: true
authorIsRacker: true
categories:
    - General
---

Azure has provided the functionality to host static websites from an Azure Storage Account for some time, but it did not support setting a default document. This functionality is in preview and should hit public preview this month. Let's take a look on how to test out this great feature.

<!-- more -->

Microsoft has not announced the public preview as of today, but to access it, please click this link to enable static website support in the portal http://aka.ms/staticwebsites. Create a new storage account and make sure to keep the account kind **StorageV2** and the location **West Central US**. Once the Storage Account resource has been created, open up the storage account from the blade. A Static website (preview) setting will now display. Click on it then select Enabled which will bring up 2 text boxes to set your Index document name and Error document path. The Index document name is the default document that will be selected when a user browsers to the primary endpoint generated. The error document path will be the 404 page. Hit save after filling in the file names you will be using.

I created a sample index.html to generate the date. 
```
<!DOCTYPE html>

<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <title>Default page test</title>
</head>
<body>
     Storage account default page generated on:
    <p> 
        <script> document.write(new Date().toLocaleDateString()); </script>
    </p>
</body>
</html>
```

I then created a sample 404.html page as well
```
<!DOCTYPE html>

<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8" />
    <title>uh oh! </title>
</head>
<body>
     Looks like you hit a 404, please try again:
</body>
</html>
```
I noticed that I cannot find the web container when using Azure Storage Explorer. The workaround is to click the **$web** container and use the browser preview functionality to upload the index.html and 404.html files to the **$web** container.

Clicking on the primary endpoint URL, I now have a default document being used. I also tested out a 404 error and that works as well.



