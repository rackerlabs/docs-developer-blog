---
layout: post
title: "New features and performance improvements with TM1 Planning Analytics"
date: 2018-06-13 00:00
comments: true
author: Raghavendra Taluri
published: true
authorIsRacker: true
categories:
    - General
---

Planning Analytics Local is the latest release and rebranding for IBM&reg;
Cognos TM1&reg;. Planning Analytics Local offers substantial changes and updates
to the TM1 product and adds new functions that enhance performance.

<!-- more -->

### Introduction

IBM released Planning Analytics Local, a rebranding of the  TM1 product,
which combines TM1 with Planning Analytics on the Cloud. This release provides
significant enhancements and performance improvements.

Planning Analytics Workspace, a highlight among the new features, completely
transforms the user experience. This new face of TM1 provides a rich, interactive
workspace, which is visual, intuitive, insightful, social, and mobile.

Planning Analytics Local uses hierarchies to provide a deeper analysis of TM1
data. It turns attributes into virtual dimensions, saves RAM, increases query
performance, and adds flexibility. Planning Analytics Local introduces
hierarchies for queries, provides dimension versioning, and enables users to
have smaller, faster cubes.

The following sections highlight some of the interfaces and new features of
Planning Analytics Local.

### Planning Analytics Workspace (PAW)

PAW, the new foundation for Planning Analytics Local, is a web-based tool that
provides a rich, user interface ideal for exploring and visualizing TM1 data.
PAW includes support for all of the new Planning Analytics Local features
including hierarchies support.

The following diagram shows some features of PAW:

![]({% asset_path 2018-06-13-new-features-and-performance-improvements-with-tm1-planning-analytics/Workspace.png %})

### Planning Analytics for Excel (PAx)

PAx is the new Excel interface for Planning Analytics and takes the place of
Café. PAx has a new look and supports many features that TM1 Perspectives users
have come to love. PAx even incorporates a new cube browser and the same set
editor that is used in PAW. PAx is the future of TM1 data access from Microsoft&reg;
Excel, but it does not include all of the Perspectives reporting features.
Therefore, TM1 Perspectives is still available in Planning Analytics Local.
Each release of PAx will incorporate more Perspectives features.

The following diagram shows some features of PAx:

![]({% asset_path 2018-06-13-new-features-and-performance-improvements-with-tm1-planning-analytics/Pax.png %})

### TM1 Web

The updated TM1 Web matches the look and feel of the other Planning Analytics
Local applications. TM1 Websheets can access relational data directly when they
are published from PAx, which expands existing drill-through and comparison
capabilities. TM1 Web supports the new hierarchy features when Quick Reports
are published from PAx (formerly known as Flex Views in Café).

The following diagram shows some features of TM1 Web:

![]({% asset_path 2018-06-13-new-features-and-performance-improvements-with-tm1-planning-analytics/Web.png %})

### Hierarchies feature for modeling and analysis

Planning Analytics Local brings the long-awaited hierarchies feature to the TM1
product line. Because it is a fundamental shift in standard TM1 architecture,
hierarchies change the way you model your business in TM1 as shown in the
following diagram:

![]({% asset_path 2018-06-13-new-features-and-performance-improvements-with-tm1-planning-analytics/Arch.png %})

In the new architecture, a *dimension* is a collection of hierarchies and not
elements. Dimensions allow users to turn attributes (or other information) into
virtual dimensions to better filter and consolidate data. Hierarchies also makes
it easier to separate and use alternate hierarchies in a dimension. Hierarchies
also let you add a dimension to a cube-view multiple times. For example, you
can browse products by color, category, and size all at the same time. Most
importantly, hierarchies provide simpler cubes with fewer dimensions, a smaller
RAM footprint, and increased query performance.

### Improved server performance and features

Planning Analytics Local also improves the performance of the underlying TM1
Server, including the following new features:

-	**Encryption at rest:** Encrypt TM1 data folders to meet Federal Information
   Processing Standard (FIPS)  certification.
-	**TI Debugger:** Track variables, set breakpoints, and view locks.
-	**Multithreaded Feeder Propagation:** The MTQ Framework has been applied to
   feeder generation, greatly speeding up TM1 rule saves and server startup.
-	**Reduced locking contention:** More frequent metadata updates and reduced
   locking, which is typically caused by logins and other updates, improves
   performance.


### Conclusion:

Among many other features from migrating to planning, Planning Analytics Local
improves TM1 performance, reduces RAM consumption, and provides end users with
self-service, interactive dashboards and visualizations from a variety of data
sources.

If you have any questions on this topic, comment in the field below.

Much if this content came directly from
[https://blog.quebit.com/blog/qubit-blog-introducing-planning-analytics-local](https://blog.quebit.com/blog/qubit-blog-introducing-planning-analytics-local).

