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

In Part 1 of this two-part series we introduced License Plate Numbers (LPN) in
the Oracle&reg; Warehouse Management System (WMS). In this followup post we'll
discuss describe the various types of inventory transactions you can perform
with License Plate Numbers (LPN).

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

1. Log on to PuTTy on the mobile device.

2. Navigate to the **Miscellaneous Issue** page.

3. Select **Responsibility > WHSE Mgmt > Warehousing > Inventory > Issues >
   Misc Issue**.

   ![Screenshot]({% asset_path 2018-06-05-lpn-overview-part2/picture1.png %})

4. In the **Acct** field, enter the adjustment account for the issue and the
   corresponding receipt.

5. In the **LPN** field, enter the LPN to transact.

   **Note**: The LPN must be on hand in the current organization.

6. Optionally, enter a reason for the issue in the **Reason** field.

7. Select **Save/Next** to enter additional transfers, **Done** to complete
   the transaction, or **Cancel** to cancel the issue.

#### Perform a subinventory LPN transfer

To perform a subinventory LPN transfer, use the following steps:

1. Log on to PuTTy on the mobile device.

2. Navigate to the **Sub Transfer** page.

3. Select **Responsibility > WHSE Mgmt > Warehousing > Inventory > Transfers >
   Sub Transfer**.

   ![Screenshot]({% asset_path 2018-06-05-lpn-overview-part2/picture2.png %})

4. Enter or select the LPN from which you want to perform the transfer.

5. In the **To Sub** field, enter or select the subinventory you want
   to transfer the LPN to.

6. In the **To Loc** field, enter or select the destination locator for the
   LPN.

7. In the **Reason** field, optionally enter or select a reason for the
   transfer.

8. Select **Save/Next** to enter additional transfers, **Done** to complete
   the transfer, or **Cancel** to cancel the transfer.

#### Perform a direct inter-organization transfer

You can also transfer LPNs to Oracle Warehouse Management-enabled
organizations. To perform a direct inter-organization LPN transfer, use the following steps:

1. Log on to PuTTy on the mobile device.

2. Navigate to the **Sub Transfer** page.

3. Select **Responsibility > WHSE Mgmt > Warehousing > Inventory > Transfers >
   Org Transfer**.

   ![Screenshot]({% asset_path 2018-06-05-lpn-overview-part2/picture3.png %})

4. If necessary, enter or select the **from** organization.

5. Enter or select the **to** organization.

   **Note**: You can only transfer LPNs to Oracle Warehouse Management-enabled
   organizations.

6. Enter or select the **Transaction Type**.

7. Optionally, in the **LPN** field, enter or select the LPN to transfer.

   **Note**: If you do not enter an LPN you must enter the **Item**,
   **Subinventory**, and **Locator** information.

8. In the **To Sub** field, enter the destination subinventory.

9. In the **To Loc** field, enter the destination locator.

10. Select **Save/Next** to transfer another LPN, **Done** to complete the
    transfer, or **Cancel** to cancel the transfer.

### Mobile PuTTy shortcuts

You can use the following shortcuts when using PuTTy on your mobile device:

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
