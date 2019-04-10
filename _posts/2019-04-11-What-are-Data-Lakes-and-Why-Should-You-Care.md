---
layout: post
title: "What are Data Lakes, and why should you care"
date: 2019-04-11 00:01
comments: true
author: Ash Hornbeck
published: true
authorIsRacker: true
authorAvatar: https://www.gravatar.com/avatar/f96915d3f29e5623f9a9ff8c7cb3148f
bio: "Ash Hornbeck is a Sr. Product Architect on the Rackspace Managed Public Clouds Product Architecture Team."
categories:
    - AWS
    - Database
metaTitle: "What are Data Lakes, and why should you care?"
metaDescription: "A look at Data Lakes as a source of future business value."
ogTitle: "What are Data Lakes, and why should you care?"
ogDescription: "A look at Data Lakes as a source of future business value."
---
In recent years, Data Lakes have moved from the technology boondocks to the prime beachfront real estate of the data sciences. Why is this happening, and why are they important? The short answer ... there's value in there.

<!-- more -->

### Data Has Value

Increasingly, it is apparent a company's data contains huge potential value. For many of the Internet giants like Google, Facebook, and others, their value is largely derived from their data.  But you don't have to be an Internet giant to get value from your data. Data is being used by industrial companies to predict machine failure, by financial institutions to better manage risk, by online retailers to increase customer retention, and by countless other institutions to discover new insights. It seems like a fairly simple formula: feed data to business analytics tools or machine learning (ML) systems and gain insights. In reality, it is not that simple. We must satisfy one essential prerequisite before we can tackle the analysis problem. We must actually have the data that contains the insights.

### Isn't This Just Another Data Warehouse Solution?

You may be thinking, "isn't this the problem data warehouses solve?" Not really. Data warehouses are built to solve a defined set of business problems. Data warehouse data ingestion uses an extract, transform, load (ETL) workflow. Data is extracted from the source system, transformed into the data warehouse's structure, and then loaded into the data warehouse.  By this time, the data has already been structured, filtered, and otherwise manipulated to exclude data not relevant to the defined business problem set. In the ETL process, we have, either implicitly or explicitly, kept some data values and discarded others, augmented the data, formed relationships between data items, and disregarded others. What if a new business problem is discovered that needs the discarded information? Business environments are always changing, and future problems cannot be predicted. No matter how correct the ETL process is for the current business problem set, a huge amount of future potential value is being lost by making these decisions when populating the data warehouse.

### Enter Data Lakes

In order to retain as much potential value as possible, we cannot discard the original data. Why don't we just keep all the data in its raw format and decide how to use it later? We could just let the data flow like rivers into a central repository, forming a "lake" of "data." :) Put another way, extract and store the data, then transform and load it as needed (often called Extract, Load, and Transform, ELT – transposing the 'T' and the 'L' in ETL).

Historically, the cost of storage and extracting meaningful structure at some future date far outweighed the potential value of the information it may contain. However, the cost of storage and cost of distilling useful structure out of the chaos has dropped, making it increasingly economical for more and more companies to do just that.

#### Any Collection of Raw Data is a Data Lake, Right?

Ok, simple enough. Just dump all of the raw data into a single location, and we are done, right?  Far from it! Data ingestion must be done properly to protect customers, companies, and the data while making the it available to future data scientists and analysts. To do this, we must consider many important factors.

* How will future data scientists and analysts find what they are looking for? _The raw data must be indexed._

* How can the data be extracted in an efficient way? _The data must be stored in an efficient file format, such as a columnar format._

* What about Personally Identifiable Information (PII), Protected Health Information (PHI), Cardholder Data (CD), and other sensitive data? _Data obfuscation is needed._

* How will you handle data privacy (e.g., GDPR), data sovereignty, and control access so that you are not in the headlines for another data breach? _Identity and access management must be implemented to apply appropriate permissions and access controls._

What about deduplication or matching records that do not share some identifying key? Is _123 Main St, Some Town, USA_ the same location as _123 Main Street, Some Town, USA_? What about _Robert Smith_ and _Bob Smith_? As you can imagine, these are simple scenarios. Much more complex situations exist in real data sets.

Once the data is in the data lake and has the proper indexing and controls in place, it needs to be converted into a structured format before it can be used. Typically, this means applying the just-in-time schema as it is read. The various raw source formats are projected into a known structure so they can be consumed by ML, warehousing, or Business Intelligence (BI) systems.  (I prefer to call this process EtS-TL, Extract transform Store – Transform and Load, because some lossless data transformation is performed as the data enters the lake.  But discussion of nomenclature is a topic for another time.)

#### Using the Data

The data is now in the lake but cannot be used in its current form. The data transformation decisions that were delayed must now be decided. Once a schema is decided upon and the data extracted, then it must be cleaned in a schema-specific way. Invalid data for one schema/analysis may be perfectly valid for another. For example, consider a land ownership dataset that contains owner's name, property address, property values, payment delinquency, land use (e.g., residential, office building, or industrial), and property tax account numbers.  Determining if there is a correlation between land use and payment delinquency does not require the owner's name. At the same time, looking for a correlation between property values and land use does not require delinquency data. If a data item is missing from a row in one data slice, it does not invalidate the same row for another data slice. Data Lakes let you keep your data analytics options open, but they come with their own complexities and costs.

Once all these steps are completed, we are at a point where our data analytics tools, BI systems, or ML models can begin their work. However, by leveraging a data lake, we have not inadvertently destroyed potential future value found in the data. Future business questions can be explored without requiring us to know the future.

### Summary 

While Data Warehouses are filtered, prepared, and ready to use, data lakes are reservoirs, not intended to be consumed in their raw forms. Instead, the data in them must be prepared before it can be consumed. Like any reservoir, they must be managed properly to keep them available for future consumption. This is done through managing the inflow (storage file formats and data obfuscation), understanding the content (indexing and deduplication), securing from misuse (Identity and Access Management), and purification facilities (data extraction, application of schemas, and data cleaning).

### The Tip of the Iceberg 

Luckily, in the cloud era, we do not need to roll our own tools and technologies to implement a data lake.  For example, AWS Lake Formation addresses the tools and technology issues directly associated with the data lake itself.  However, there are many tough questions remaining. Do you know how to properly use these tools? Do you have the expertise to set up proper network connectivity to allow ingestion of your data? Is a VPN sufficient, or do you needed a dedicated circuit (Direct Connect)? You are putting a goldmine of company data into the cloud. Are you sure you have secured it properly to prevent unauthorized access? Are you accessing the data in a cost-efficient way? Remember, transferring out is not free.

At Rackspace, we have the Cloud Architects and expertise to help you get your data lake up and running quickly, securely, and efficiently.  Give us a call or visit us at [Rackspace Managed AWS](https://www.rackspace.com/en-us/managed-aws) for more information.
