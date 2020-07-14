---
layout: post
title: "Use Microsoft Flow to provision sites in Sharepoint Office 365"
date: 2020-07-15 00:01
comments: true
author: Saurabh Agarwal
published: true
authorIsRacker: true
authorAvatar: 'https://s.gravatar.com/avatar/35520014182eaf668b9dad65bfc38c62'
bio: "I am a SharePoint professional with 11 Years of work experience in
development and administration in various flavors of SharePoint including
SharePoint On-Prem versions and cloud-based technologies like Azure and
SharePoint O365."
categories:
    - General
metaTitle: "Use Microsoft Flow to provision sites in Sharepoint Office 365"
metaDescription: "A cloud-based solution, Microsoft&reg; (MS) Flow effectively
automates and simplifies business processes by creating automated workflows with
MS Flow. "
ogTitle: "Use Microsoft Flow to provision sites in Sharepoint Office 365"
ogDescription: "A cloud-based solution, Microsoft&reg; (MS) Flow effectively
automates and simplifies business processes by creating automated workflows with
MS Flow. "
---

A cloud-based solution, Microsoft&reg; (MS) Flow effectively automates and
simplifies business processes by creating automated workflows with MS Flow.

<!-- more -->

This post describes how to create a fully automated bulk solution to provision
a sub-site in SharePoint&reg; Office 365&reg; (SPO) for any site creation
requests that come through a custom list. You can achieve this goal by using a
scheduled MS Flow workflow and the REST API features.

When you create a workflow, keep the following considerations in mind:

- Create new requests in a custom list.

- The approval workflow might not run on the newly created item.

- A scheduled MS Flow (Power Automate) workflow picks up all the approved
  requests from the list and provisions a site. The scheduling time depends on
  your requirements.

- After you provision the site, you should update the value in a custom list
  so that the system won’t pick up the request when the next workflow runs.

Steps to build the solution:

- Create a custom list

- Create and schedule a workflow

### Create a SharePoint list

Create a custom SharePoint list, **Site Creation Request**, with the first eight
columns in **Figure 1**.

![]({% asset_path 2020-07-15-use-microsoft-flow-to-provision-sites-in-sharepoint-office-365/Picture1.png %})

**Figure 1** : Set of columns

Now add items to the **Site Creation Request** list.

For example, add two items to the list, one without a unique permission and
another with a unique permission, as shown in **Figure 2**.

The **IsUniquePermission** column indicates if the requested site inherits
permissions from its parent or is a unique permission.

The **Site Template** column contains the **Site Template ID** in the following
format:

- **Teams**: `STS#3`
- **Communication Site**: `SITEPAGEPUBLISHING#0`

![]({% asset_path 2020-07-15-use-microsoft-flow-to-provision-sites-in-sharepoint-office-365/Picture2.png %})

**Figure 2** : Add an item to *site creation request* list

### Create and schedule a workflow

Use the following steps to create and schedule an MS Flow workflow:

#### Step 1: Build a scheduled workflow

Build a scheduled flow, as shown in **Figure 3**, pass all the parameters, and
click **Create**.

![]({% asset_path 2020-07-15-use-microsoft-flow-to-provision-sites-in-sharepoint-office-365/Picture3.png %})

**Figure 3**: Create the scheduled workflow

#### Step 2: Add a variable action

In the next screen, after the recurrence step, add two **Initialize Variable**
actions for the **List Name** and **IsUniquePermission** variables, as shown in
**Figure 4**.

![]({% asset_path 2020-07-15-use-microsoft-flow-to-provision-sites-in-sharepoint-office-365/Picture4.png %})

**Figure 4**: Add the *initialize* variable action

#### Step 3: Add Get Items action

Add a **Get Items** action to fetch all the records from the **Site Creation**
list based on the condition, **Approved is equal to Yes and Site Created is equal
to No**, as shown in **Figure  5**.

**Note**: The **Filter Query** parameter receives only **OData Query**.

![]({% asset_path 2020-07-15-use-microsoft-flow-to-provision-sites-in-sharepoint-office-365/Picture5.png %})

**Figure 5**: Add the *get items* action

#### Step 4: Add an Apply to Each action

Add the **Apply to each** action and select the value from the previous
**Get Items** action, as shown in **Figure 6**.

![]({% asset_path 2020-07-15-use-microsoft-flow-to-provision-sites-in-sharepoint-office-365/Picture6.png %})

**Figure 6**: Add the **Apply to each** action

#### Step 5: Add a Compose action

Inside the **Apply to each** block, add a **Compose** action to get the
**Site Template ID** of the current item in the loop. Split the selected
**Site Templated Id** and get only the Site ID from the value, by using the
following command, as shown in **Figure 7**.

    split(item()['SiteTemplate']?['Value'],'-')

![]({% asset_path 2020-07-15-use-microsoft-flow-to-provision-sites-in-sharepoint-office-365/Picture7.png %})

**Figure 7**: Add the **Apply to each** action

#### Step 6: Add a Send HTTP action to provision site

Inside the **Apply to each** block, add a **Send an HTTP request to SharePoint**
action to construct and execute a SharePoint REST API call to provision a site
based on the parameters, as shown in **Figure 8**.

The details of the map request follow:

- **Site Address**: Maps to the **RootSiteURL** column.
- **Method**: `POST`
- **URI**: **/_api/web/webinfos/add**
- **Accept header**: `application/json;odata=verbose`
- **Content Type header**: `application/json;odata=verbose`
- **Body:**
        { 'parameters':
        { '__metadata':
        { 'type': 'SP.WebInfoCreationInformation' },
          'Url':'@{items('Apply_to_each')['SubSite']}',
          'Title':'@{items('Apply_to_each')['SubSite']}',
          'Description':'My Description',
          'Language':'1033',
          'WebTemplate':'@{trim(outputs('Get_Site_Template_Id')[1])}',
          'UseUniquePermissions':'@{items('Apply_to_each')['isUniquePermission']}'
        }
        }

The body parameter details include the following elements:

- **Title**: Maps to the column **SubSite**.

- **WebTemplate**: Gets the output from the **Site Template ID** action by using
  the command: `trim(outputs('Get_Site_Template_Id')[1])`

- **UseUniquePermissions**:  Maps to the column **IsUniquePermission**.

![]({% asset_path 2020-07-15-use-microsoft-flow-to-provision-sites-in-sharepoint-office-365/Picture8.png %})

**Figure 8**: Add the HTTP request to provision the site

#### Step 7: Add a Send HTTP action to update column

Add a **Send an HTTP request to SharePoint** to update the **Site Created**
column of the current item to `YES`, as shown in **Figure 9**.

The details of the map request follow:

- **Site Address**: Maps to the **RootSiteURL** column.
- **Method**: `POST`
- **URI**: **_api/web/lists/GetByTitle('@{variables('ListName')}')/items(@{items('Apply_to_each')['ID']})**
- **Syntax**: **_api/web/lists/GetByTitle('ListName')/items(ID)**
- **Accept header**: `application/json;odata=verbose`
- **Content Type header**: `application/json;odata=verbose`
- **Body:**
        { '__metadata':
        { 'type': 'SP.Data.Site_x0020_Creation_x0020_RequestListItem'},
        'SiteCreated': true
        }

**Note**: The highlighted value in **Figure 9** is the static name of the
**Site Creation** list.

![]({% asset_path 2020-07-15-use-microsoft-flow-to-provision-sites-in-sharepoint-office-365/Picture9.png %})

**Figure 9**: Add the HTTP request to update an item

#### Step 8: Complete the Apply to each action

Complete the **Apply to each** action, as shown in **Figure 10**.

![]({% asset_path 2020-07-15-use-microsoft-flow-to-provision-sites-in-sharepoint-office-365/Picture10.png %})

**Figure 10**: **Apply to each** block

#### Step 9: Complete the scheduled workflow

Complete the scheduled workflow, as shown in **Figure 11**.

![]({% asset_path 2020-07-15-use-microsoft-flow-to-provision-sites-in-sharepoint-office-365/Picture11.png %})

**Figure 11**: Complete the workflow for site creation

### Conclusion

I hope this post helps you understand how MS Flow and the REST API work together
with SharePoint sites and list-based operations. One of the most significant
advantages of Flow is that it is incredibly easy to use, and even people with
no technical background can create workflows without trouble.

Use the Feedback tab to make any comments or ask questions. You can also
[chat now](https://www.rackspace.com/#chat) to start the conversation.

<a class="cta blue" id="cta" href="https://www.rackspace.com/microsoft/office-365">Learn more about Microsoft Office 365.</a>
