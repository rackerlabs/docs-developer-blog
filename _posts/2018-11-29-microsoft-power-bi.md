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

SUMMARY

<!-- more -->

Microsoft introduced the idea of Self-Service Business Intelligence (BI) back in 2009, announcing Power Pivot for Microsoft Excel 2010.  
After several years, the first release of Power BI was released, however the experience was not great. Later, feedback from end-users was collated and carefully considered to craft a newer version of Power BI that gained popularity. Power BI is not merely a business analytics tool, it is an ecosystem that can integrate existing corporate BI with Self-Service where data can be analyzed using key components like Power Excel, Power Query, Power View and much more.

The following image shows the Power BI workflow:

![]({% asset_path 2018-11-29-microsoft-power-bi/picture1.png %})

Source: [Microsoft Power BI Overview](https://www.slideshare.net/Netwoven/power-bi-overview-41399411)

### Differences between Power BI and SQL Server Reporting Services

The following table describes how Power BI differs from SQL Server Reporting
Services (SSRS):

<table>
  <tr>
    <th>Power BI</th>
    <th>SSRS</th>
  </tr>
  <tr>
    <td>A cloud-based business analytics tool that provides data acquisition and transformation, data modeling and visualization with greater speed, efficiency, and understanding.</td>
    <td>An enterprise visualization tool built on old technology that requires data to be delivered by some other system.</td>
  </tr>
  <tr>
    <td>Most of the enterprise clients are going towards visualization tools that are more adaptive and responsive. Users desire advanced tools that look modern and can cross filter on click of charts.</td>
    <td>It has none of those features and comes with static design. Also, there is a learning curve for developing reports.</td>
  </tr>
  <tr>
    <td>Available free of cost. You need to simply sign up and work with unstructured data. User creates their own reports by drag and drop of fields, minimal training required, and modern rendering.</td>
    <td>Requires purchasing SQL server licenses, define scope for requirements, developer to work on those requirements, consider deployment, schedule refresh of data, static reports with the dependence of BI developer to make changes.</td>
  </tr>
</table>

### Power BI features

- Natural Language Queries or Q&A question box
This feature is quite impressive. There is no special code or syntax that is required. Users simply search reports by name that make finding answers easy.

- Quick Insights
With this feature, Power BI searches a dataset via sophisticated algorithms. It provides users with a list of charts that helps to better understand the data.

- APIs
With the Microsoft Power BI REST API you can programmatically access certain Power BI resources such as Datasets, Tables, and Rows. The image below shows the overall flow for a Power BI app created using the REST API.

IMAGE HERE (no current reference)

- Power BI Embedded: With Power BI Embedded, you can integrate Power BI reports right into your web or mobile applications. It is an Azure service that enables application developers to add interactive Power BI reports into their own applications.

- Visual Interactions: Visual interactions can be configured in a highly precise way. Types of visual interactions are:

  - Filtering interaction: Selected chart will place the very same filter on the destination chart.
  - Pie chart - Default filtering behavior, where the filtering on one chart shows on the destination chart.

- No filtering interaction:  No filtration.

- Query Editor: The query language of Power BI Desktop is used by Query Editor.

### Content Packs

One of the essential features of Power BI is Content Packs which provide access to the data generated from different web services. They are also useful in deploying and sharing predefined models and reports within a company. Anybody can share a dashboard; however, pro-users can gain access to the content packs. There are two types of content packs.

#### Organizational Content Packs

For regularly distributing reports by email to your team, package your dashboards, reports, excel workbooks and datasets and publish them to as organizational content packs. Content packs you create are in the pack library and are easily accessible to your teams. The visibility is restricted to within organization only. The content pack creator has the admin rights to modify the workbook and dataset, to schedule a refresh or to delete them.

### You can connect to a number of services to run your business, such as Google Analytics, Salesforce and Microsoft Dynamics. Power BI creates a dashboard and a set of reports that automatically shows your data and provides visual insights into your business.
Dashboard Sharing and Groups

The dashboard is a container for visualizations created on top of datasets. A dashboard can be shared with users within an organization (via email or by sending URL of the dashboard) and a domain other than that of your Organization (via email only).

Creating App Workspace in Power BI

You can create an app to automatically share all the dashboards with the users and assign editing rights to certain users within that group.

Apps Workspace vs. Organization Content Pack
In the group or APP workspace, a single copy of report and dashboard is shared which is not visible to external users. APP workspace is an evolution and a simplification of content packs which makes it easier to understand and maintain in the long run because the app has a 1:1 relationship with its workspace.  
What if you want to share the results with other users outside the group?  
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
