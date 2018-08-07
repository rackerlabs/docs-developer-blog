---
layout: post
title: "Using IIS with QlikView and custom users"
date: 2018-08-07 00:00
comments: true
author: Ananda Yadavaram
published: true
authorIsRacker: true
categories:
    - General
---

This blog describes best practices for the implementation architecture
of the web client authentication solutions for QlikView&reg;.

<!-- more -->

### Introduction

Flexibility and trust are the basic principles for customization of authentication
in QlikView:

- Flexibility is achieved when authentication is performed outside the QlikView
platform.

- Trust is established between the authenticating party and QlikView, making
QlikView more secure. Based on this trust, QlikView accepts the identity of the
user that is supplied by the authenticating party.

Many commercial and open-source identity federation products permit the
separation of authentication from business applications like QlikView. The
applications receive information about users by transferring this information
by using HTTP headers. Such systems are typically integrated with
one of the following methods:

- By using filters that run inside of the web server, such as Internet Information
Services (IIS)

- By using reverse proxies that run in front of the web server
of the business application, such as QlikView Web Server (QVWS) services or
an IIS web server that runs QlikView

The following sections describe the steps to authenticate web clients for
Qlikview, to set up QVWS to use Document Metadata Service (DMS) and custom
users for authentication, and to test the configuration.

### Configure the IIS virtual folders and files

Configure the virtual folders in IIS, changing the defaults as described in the
following sections.

#### Configure the QlikView AJAX folder

To configure the **QvAJAXYfc** folder statuses, modify the settings as shown in
the following image:

- **Anonymous Authentication** should be ``Enabled``.

- **Windows Authentication** should be ``Disabled``.

![]({% asset_path 2018-08-07-using-iis-with-qlikview-and-cutom-users/Picture1.png %})

#### Configure the AccessPointSettings file

To make sure that the Web Server settings can be reached through the QlikView
Enterprise Management Console (QEMC), set the **AccessPointzSettings.apsx** file
statuses as shown in the following image:

- **Anonymous Authentication** should be ``Disabled``.

- **Windows Authentication** should be ``Enabled``.

![]({% asset_path 2018-08-07-using-iis-with-qlikview-and-cutom-users/Picture2.png %})

#### Set up QlikView for custom users

To set up QlikView for custom users, change the **Authorization** on the
**Security** tab of the QlikView server to ``DMS authorization`` as shown in
the following image:

![]({% asset_path 2018-08-07-using-iis-with-qlikview-and-cutom-users/Picture3.png %})

### Set up the directory service and custom users

The following sections provide the steps to set up the directory
service and add custom users.

#### Set up the directory service

To set up the directory service for custom users, first create the ``Custom``
group. Click on the green plus sign on the right side of the window and then
click **Edit**. This sets the default value to ``Custom``. Click **Apply** to
save the setting and to open a new tab labeled **Users**, as shown in the
following image:

![]({% asset_path 2018-08-07-using-iis-with-qlikview-and-cutom-users/Picture4.png %})

#### Add custom users

To add custom users, fill in the requested information in the **Users** tab for each custom user and
click **Add**.  Then select the user and click **Apply**, as shown in the
following image:

![]({% asset_path 2018-08-07-using-iis-with-qlikview-and-cutom-users/Picture5.png %})

#### Configure the Web Server to accept custom users

To configure the Web Server to accept custom users, change the **Type** to
``Custom User`` in the **Authentication** tab and set the **Login Address**
to ``Alternate Login Page`` as shown in the following image:

![]({% asset_path 2018-08-07-using-iis-with-qlikview-and-cutom-users/Picture6.png %})

#### Set up the documents for DMS authentication

To set up the documents for DMS authentication, select a document in the
**Documents** tab, click the **Authorization** tab, click **Add**, and enter the
username as shown in the following image. This can be done while the Publisher
is doing a reload and distribution.

![]({% asset_path 2018-08-07-using-iis-with-qlikview-and-cutom-users/Picture7.png %})

### Test the configuration

To test the configuration, insert your server name and in a web browser go to
``http://<servername>/qlikview``, as shown in the following
image:

![]({% asset_path 2018-08-07-using-iis-with-qlikview-and-cutom-users/Picture8.png %})

Enter your username and password and click **Login**. The following image shows
the result of user ``CUSTOM\BB`` logging in:

![]({% asset_path 2018-08-07-using-iis-with-qlikview-and-cutom-users/Picture9.png %})

### Conclusion:

The preceding steps support the principle of authenticating users from outside
QlikView and add flexibility to the QlikView product. The solution that you select
depends on the architecture where the solution is going to be applied. With the
processes in this post, you can overcome the limitation of extending access to
QlikView dashboards and reports for your external users.

If you have any questions on the topic, comment in the field below.


