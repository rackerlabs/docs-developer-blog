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

In Part 1 of this two-part series, we introduced License Plate Numbers (LPNs)
in the Oracle&reg; Warehouse Management System (WMS). In this followup post
we'll discuss describe the various types of inventory transactions you can
perform with LPNs.

<!-- more -->

### Performing inventory transactions with LPNs

You can use mobile devices to perform LPN inventory transactions in WMS. The
system enables you to pack LPNs with any grouping of material into a locator.
You can then enter the LPN to transact the material. The system transacts all
of the contents of the LPN, including the nested contents of a multi-level
LPN. You can associate LPNs with the following inventory transactions:

* Miscellaneous issues

* Subinventory transfers

* Direct inter-organization transfers

#### Perform a miscellaneous issue

You can perform a miscellaneous issue on an LPN that's on hand in the current
organization. To perform a miscellaneous issue for an LPN, use the following
steps:

1. Log in to PuTTy on the mobile device.

2. From the **Miscellaneous Issue** page, select **Responsibility > WHSE Mgmt
   > Warehousing > Inventory > Issues > Misc Issue**.

   ![Screenshot]({% asset_path 2018-06-05-lpn-overview-part2/picture1.png %})

<ol start=4>
   <li>In the **Acct** field, enter the adjustment account for the issue and
   the corresponding receipt.</li>

   <li><p>In the **LPN** field, enter the LPN you want to transact.</p>

   <p>**Note**: The LPN must be physically located at the current organization.</p></li>

   <li>Optionally, in the **Reason** field, you may enter a reason for the
   issue.</li>

   <li>Select **Done**.</li>
</ol>

#### Perform a subinventory LPN transfer

To perform a subinventory LPN transfer, use the following steps:

1. Log in to PuTTy on the mobile device.

2. From the **Sub Transfer** page, select **Responsibility > WHSE Mgmt >
   Warehousing > Inventory > Transfers > Sub Transfer**.

   ![Screenshot]({% asset_path 2018-06-05-lpn-overview-part2/picture2.png %})

<ol start=4>
   <li>Enter the LPN you want to transfer from.</li>

   <li>In the **To Sub** field, enter the subinventory you want
   to transfer the LPN to.</li>

   <li>In the **To Loc** field, enter the destination locator for the
   LPN.</li>

   <li>Optionally, in the **Reason** field, you may enter a reason for the
   transfer.</li>

   <li>Select **Done**.</li>
</ol>   

#### Perform a direct inter-organization transfer

You can also transfer LPNs to Oracle Warehouse Management-enabled
organizations. To perform a direct inter-organization LPN transfer, use the following steps:

1. Log in to PuTTy on the mobile device.

2. From the **Sub Transfer** page, select **Responsibility > WHSE Mgmt >
   Warehousing > Inventory > Transfers > Org Transfer**.

   ![Screenshot]({% asset_path 2018-06-05-lpn-overview-part2/picture3.png %})

<ol start=4>
   <li>If necessary, enter the organization to transfer **from**.</li>

   <li><p>Enter the organization to transfer **to**.</p>

   <p>**Note**: You can only transfer LPNs to organizations that use Oracle Warehouse Management.</p></li>

   <li>Enter the **Transaction Type**.</li>

   <li><p>Optionally, in the **LPN** field, enter the LPN you want to
   transfer.</p>

   <p>**Note**: If you don't enter an LPN, you must enter the **Item**,
   **Subinventory**, and **Locator** information.</p></li>

   <li>In the **To Sub** field, enter the destination subinventory.</li>

   <li>In the **To Loc** field, enter the destination locator.</li>

   <li>Select **Done**.</li>

### Mobile PuTTy shortcuts

You can save time with the following shortcuts when using PuTTy on your mobile
device:

| Action | Shortcut |
|----------------------|--------|
| Help | F1 |
| Return to menu | F2 |
| Back | F3 |
| Forward | F4 |
| Clear | Ctrl+K |
| See values in LOV | Ctrl+L |
| Return to Main Menu | Ctrl+N |
| Expand popup message | Ctrl+B |
| Toggle | Ctrl+Q |
| Hot key | Esc |
| Page up | Ctrl+D |
| Page down | Ctrl+C |

### Conclusion

The information in this post is intended to help you gain an understanding of
how to work with LPNs in Oracle WMS by using a mobile interface. It explains
various inventory transactions you can perform with LPNs. Thanks to LPNs,
these transactions process quickly. LPNs simplify management for organizations
with large warehouses.

Have you used LPNs in in Oracle Warehouse management through a mobile
interface? Join the conversation by leaving a comment below.

### Reference

The [Oracle Warehouse Management User's
Guide](https://docs.oracle.com/cd/E18727_01/doc.121/e13433/T211976T321834.htm)
was used as a reference for this article.
