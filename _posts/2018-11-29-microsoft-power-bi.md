---
layout: post
title: "Power BI: A Suite of Business Analytics Tools"
date: 2018-11-29 00:00
comments: true
author: Ramandeep Kaur
published: true
authorIsRacker: false
categories:
    - General
---

Originally published by TriCore: November 7, 2017

Microsoft&reg; introduced the idea of self-service business intelligence (BI)
back in 2009, announcing Power Pivot for Microsoft Excel&reg; 2010.
After several years, Microsoft release version 1 of [Power
BI&reg;](https://powerbi.microsoft.com/en-us/), but the user experience wasn't
great. Microsoft collected feedback from end-users and used it to craft a
newer version of Power BI that gained popularity. This blog post provides an
introduction to this tool.

<!-- more -->

Microsoft Power BI is more than a business analytics tool. It's an ecosystem
that can integrate existing corporate BI with self-service, and analyze data
by using key components like Power Excel, Power Query, Power View, and other
functionality.

The following image shows the Power BI workflow:

![]({% asset_path 2018-11-29-microsoft-power-bi/picture1.png %})

Source: [Microsoft Power BI Overview](https://www.slideshare.net/Netwoven/power-bi-overview-41399411).

### Differences between Power BI and SQL Server Reporting Services

The following table describes how Power BI differs from Microsoft SQL&reg;
Server&reg; Reporting Services (SSRS):

<table>
  <tr>
    <th>Power BI</th>
    <th>SSRS</th>
  </tr>
  <tr>
    <td>A cloud-based business analytics tool that performs data acquisition and transformation, data modeling, and data visualization with greater speed, efficiency, and understanding.</td>
    <td>An enterprise visualization tool built on old technology that requires another system to deliver data.</td>
  </tr>
  <tr>
    <td>Most enterprise clients are adopting visualization tools that are more adaptive and responsive. Users want advanced tools that look modern and can cross-filter when they click on charts.</td>
    <td>SSRS has a static design. There's also a learning curve for developing reports.</td>
  </tr>
  <tr>
    <td>Power BI is available for free and requires minimal training. Users creates their own reports by dragging and dropping fields. Power BI also offers modern rendering.</td>
    <td>A SQL server license is required. You must also define the scope for your requirements, have a developer work on those requirements, consider how to deploy the software, and schedule data refreshes. Reports are static. In addition, you're dependent on a BI developer to make changes.</td>
  </tr>
</table>

### Power BI features

Power BI has the following features:

- **Natural Language Queries or Q&A question box**: This feature is quite impressive. There is no special code or syntax that is required. Users simply search reports by name that make finding answers easy.

- **Quick Insights**: With this feature, Power BI searches a dataset via sophisticated algorithms. It provides users with a list of charts that helps to better understand the data.

- **APIs**: With the Microsoft Power BI REST API you can programmatically access certain Power BI resources such as Datasets, Tables, and Rows. The image below shows the overall flow for a Power BI app created using the REST API.

IMAGE HERE (no current reference)

- **Power BI Embedded**: With Power BI Embedded, you can integrate Power BI reports right into your web or mobile applications. It is an Azure service that enables application developers to add interactive Power BI reports into their own applications.

- **Visual Interactions**: Visual interactions can be configured in a highly precise way. Types of visual interactions are:

  - **Filtering interaction**: Selected chart will place the very same filter on the destination chart.
  - **Pie chart**: Default filtering behavior, where the filtering on one chart shows on the destination chart.

- **No filtering interaction**: No filtration.

- **Query Editor**: The query language of Power BI Desktop is used by Query
  Editor.

### Content packs

Content packs are an essential feature of Power BI that provide access to the data that different web services generate. They're also useful for deploying and sharing predefined models and reports within a company. While anyone can share a dashboard, pro-users can gain access to the content packs. There are two types of content packs: organizational content packs and service content packs.

#### Organizational content packs

Organizational content packs make it easy to distribute reports to your team
by enabling you to package your dashboards, reports, Excel workbooks, and
datasets and publish them together. Power BI stores the content packs that you
create in the _pack library_, where they're easily accessible to your teams.
Content pack visibility is restricted only to users within the organization.
The content pack creator has administrative rights to modify the workbook and
dataset, schedule a refresh, or delete them.

#### Service content packs

You can connect to a number of external services, such as Google&reg;
Analytics&trade;, Salesforce&reg; and Microsoft Dynamics&reg;. Power BI
creates a dashboard and a set of reports that automatically display your data
from these services and provide visual insights into your business.

### Dashboard sharing and groups

The dashboard is a container for visualizations that Power BI generates from
your datasets. You can share your dashboards with the following users:

- Other users in your organization (either by email or by sharing a link to
  the dashboard)
- Users who are associated with a domain other than that of your organization
  (by email only)

### Create an app workspace in Power BI

Alternatively, you can create an app that enables you to automatically share
all of your dashboards with your users, and assign editing rights to certain
users within that group.

### App workspaces vs. organization content packs

In the group or app workspace, a single copy of report and dashboard is shared which is not visible to external users. App workspace is an evolution and a simplification of content packs which makes it easier to understand and maintain in the long run because the app has a 1:1 relationship with its workspace.

#### What if you want to share the results with other users outside the group?

The content pack for an organization is a good solution. Users receive a copy of these objects that are automatically synchronized in case a new version of the same content pack is published. If users customize one of these objects, they will work on their own copy of the reports, that will no longer be synchronized with the original one.

Security and Roles

Security plays an essential role in all aspects. In Power BI, Row-level security (RLS) can be used to restrict data access for given users using filters which can be define within roles. RLS for data models can be configured on datasets that are using DirectQuery such as SQL Server.
Only the owners of the dataset will see the security available. If the dataset is in a Group, only Administrators of the group will see the security option.

Connecting to a Database

In Power BI, data can be loaded from varied sources. Some of them are discussed below:  

Import

Import is useful when data refresh is not required constantly. When you choose Import, Power BI Desktop connects to the database, loads the information, and stores it within its internal data model. You can then work on your data in Power BI Desktop without being connected to the database. Connection is required only when you want to refresh the data.

IMAGE HERE (no reference)

DirectQuery

To load or update data frequently, DirectQuery is the most convenient method. With DirectQuery, Power BI Desktop does not load the data into its internal database. Instead, it runs a query to the original database every time it needs to draw a chart. Thus, the connection between Power BI Desktop and the database will be permanent. However, it comes with the following limitations:

- All tables must come from a single database.
- There is a limit of 1 million rows for returning data.

IMAGE HERE (no reference)

### One gateway for all of your cloud services

In both the cases, after you publish the Power BI Desktop file to the Power BI service, the refresh Operation requires either a Personal Gateway or an Enterprise Gateway.

The gateway acts as a bridge between the cloud and on-premises server. Data transfer between the cloud and the gateway is secured through Azure Service Bus. The Service Bus creates a secure channel between the cloud and on-premise server through an outbound connection on the gateway. There are no inbound connections that you need to open an on-premise firewall. The closer the gateway is to the server, the faster the connection will be. If you can get the gateway on the same server as the data source, that works best as it helps avoid network latency between the gateway and the server.

### Conclusion

In a nutshell, Power BI is an open ecosystem that is constantly growing. It is a suite of business analytics tools to analyze data that deliver useful insights. Power BI dashboards provide a 360-degree view for business users with their most important metrics in one place, available on all their devices and updated in real time. With one click, users can explore the data from their dashboard to make timely and important business decisions.
