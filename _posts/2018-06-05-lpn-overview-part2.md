---
layout: post
title: "An overview of LPN and shortcuts to mobile Telnet: Part 2"
date: 2018-06-05 00:00
comments: true
author: Sharad Kukreja
published: true
authorIsRacker: true
categories:
    - General
---

In Part 1 of this two-part series we...

In Part 2 we'll discuss describe the various types of inventory transactions associated with License Plate Numbers (LPN), its usage & useful shortcut keys for Mobile Telnet also commonly known as Putty.

<!-- more -->

### Performing Inventory Transactions with LPNs

Mobile devices can be used to perform LPN Inventory Transactions. Oracle WMS enables you to pack LPNs with any grouping of material into a locator. You can then enter the LPN to transact the material. The system transacts all contents of the LPN, including the contents of any LPN nested within the LPN. You can associate LPNs with the following inventory transactions:

* Miscellaneous issues

* Subinventory transfers

* Direct inter-organization transfers

How to Perform a Miscellaneous Issue

* Log on to the mobile device.

* Navigate to the Miscellaneous Issue page.

* Responsibility>WHSE Mgmt>Warehousing>Inventory>Issues>Misc Issue

* In the Acct field, enter the adjustment account for the issue and corresponding receipt.

* In the LPN field, enter the LPN to transact.

* Note: The LPN must be on-hand in the current organization.

* Optionally, enter a reason for the issue in the Reason field.

* Select <Save/Next> to enter additional transfers, <Done> to complete the transaction, or <Cancel> to cancel the issue

How to Perform a Subinventory LPN Transfer

* Log on to the mobile device.

* Navigate to the Sub Transfer page.

* Responsibility>WHSE Mgmt>Warehousing>Inventory>Transfers>Sub Transfer

* Enter or select the LPN from which you want to perform the transfer.

* In the To Sub field, enter or select the subinventory to which you want to transfer the LPN.

* In the To Loc field, enter or select the destination locator for the LPN.

* In the Reason field, optionally enter or select a reason for the transfer.

* Select <Save/Next> to enter additional transfers, <Done> to complete the transfer, or <Cancel> to cancel the transfer.

How to Perform a Direct Inter Organization Transfer

* Log on to the mobile device.

* Navigate to the Sub Transfer page.

* Responsibility>WHSE Mgmt>Warehousing>Inventory>Transfers>Org Transfer

* Enter or select the from organization if necessary

* Enter or select to organization.

* Note: You can only transfer LPNs to Oracle Warehouse Management enabled organizations

* Enter or select the Transaction Type.

* Optionally, in the LPN field, enter or select the LPN to transfer.

* Note: If you do not enter an LPN you must enter the Item, Subinventory, and Locator information.

* Enter the destination subinventory in the To Sub field.

* Enter the destination locator in the To Loc field.

* Select <Save/Next> to transfer another LPN, <Done>to complete the transfer, or <Cancel> to cancel the transfer.

### Conclusion

The above information helps to gain an understanding of LPN’s in Oracle Warehouse management using Mobile interface. It explains the current status, utilization, various inventory transactions that can be performed using LPN’s as well as the shortcuts to the mobile interface application named as Putty. LPNs help in processing the transactions swiftly. This has not only made the whole process easy but also viable for organizations with large warehouses.

I hope you have found my two part blog series informative and useful. For any questions click below (CTA). You can also leave your comments and feedback in the field below.
