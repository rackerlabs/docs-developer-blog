---
layout: post
title: "An overview of LPN and shortcuts to mobile Telnet: Part I"
date: 2018-06-04 00:00
comments: true
author: Sharad Kukreja
published: true
authorIsRacker: true
categories:
    - General
---

In this two-part series we'll discuss License Plate Numbers (LPN), their
usage, and useful shortcut keys for Mobile Telnet, which is commonly known as
Putty. Part I introduces LPN.

<!-- more -->

### What is LPN?

LPN in Oracle&reg; Warehouse Management (WMS) is an identity assigned to a group of items represented systematically, that travel through the Unit/Floor together. The LPN will help identify a group of items packed together in terms of its current sub-inventory, location, revision, lot, serial, organization and item contents.

![]({% asset_path 2018-06-04-lpn-overview-part1/picture1.png %})

![]({% asset_path 2018-06-04-lpn-overview-part1/picture2.png %})

### Uses of LPN

You can perform the following tasks by using LPNs in WMS:

* Store delivery related information such as its content items, revision, lot, serial, organization, sub inventory, or locator

* Track contents of any container in receiving, inventory, or in-transit

* Receive, store, and pick material by LPN

* View on hand balances by LPN

* Move multiple items in a transaction by LPN

* Transfer LPN contents

* Pack, unpack, consolidate, split, and update LPNs

* Print labels and reports for referencing container contents

* Reuse empty LPNs

* Receive and send LPN information on an ASN

### Transactions

LPNs in WMS support the following types of transactions:

* Pack Transaction: As the name suggests the Pack transaction enables the business to pack loose material into an LPN.

* Consolidate Transaction: this enables the business to nest a child LPN inside a parent LPN.

* Unpack Transaction: this enables the business to unpack either material or a nested LPN from a parent LPN.

* Split Transaction: this is essentially an Unpack and Pack combined together, creating a new LPN with some material from another LPN.

* Update LPN Transaction: The Update LPN transaction enables the users to update the weight, volume, and container item of an LPN. As in all other transactions, LPN transactions of lot, serial, or revision controlled material requires you to enter the item controls.

### LPN context and status codes

LPNs have the following context and status codes:

1. Resides in Inventory

   This context code indicates that material associated with this LPN has been costed and accounted for in an inventory. A LPN with this context may not be used when receiving material against a standard or inspection routed receipt, but may be used during a direct delivery routed receipt. However, outbound transactions can be performed on LPNs with this context.

2. Resides in WIP

   The context code indicates that material associated with this LPN is currently being transacted in WIP (Work in Process). Therefore, the associated material is not yet in inventory and has not been costed to inventory.

3. Resides in Receiving

   The context code indicates that material associated with this LPN have been received using a standard routing or inspection routing receipt and have not been delivered or put away yet. Therefore, the associated material is not yet in inventory and has not been costed to inventory.

4. Issued out of Stores

   An LPN in this status is no longer tracked by the system, and hence, no longer associated with a locator within the warehouse. LPNs shipped out of inventory receive this context and may not be re-received.

5. Defined but not used or pre-generated

   LPN in this status means they are not associated with any physical material. They can be printed and used to identify material during any stage of the material management process such as inbound, replenishment, outbound, and so on. This context refers to LPNs that are ready to be used.

6. In-transit

   As the name suggests, LPN in this context is an indication that it is currently moving from one location to another. Possible uses for this are when a LPN is moved from one organization to the next, for example while the LPN is on a Vehicle/in transit. This context is particularly used for Internal Sales Orders (ISO) or Inter-org transit where an indirect shipping network is defined between the organizations.

7. At Vendor

   This context comes into picture when a vendor sends an Advanced Shipment Notice (ASN) to Oracle WMS, the system internally generates LPNs and associates them with material information on the ASN. These LPNs receive this context. Material associated with LPNs of this context are not on-hand or costed until it is actually received.

8. Packing context

   This context is primarily used for setup of picking or put away rules, basically this status is temporary and used internally by the software as an intermediary.

9. Loaded to Dock/ Shipments

   An LPN loaded for shipment has just been loaded onto a carrier ready to leave the warehouse. Once the entire carrier leaves the dock, the LPN obtains a context of six Resides in in transit or four Issued out of stores.

10. Prepack for WIP

   This context value is used when the system has associated the LPN with material and printed the labels, but the material has not yet been physically packed.

11. Picked

    When LPNs are picked they are assigned with this context value. They are in-transit within the warehouse.

### Query to find the context of a LPN

You can find the context of an LPN by using the following SQL
statement as an example:

select LPN_CONTEXT from apps.wms_license_plate_numbers WHERE LICENSE_PLATE_NUMBER = ‘LPN_Number’

### How to view LPNs

You can view LPNs through a mobile user interface or through an application
that uses Oracle Material Workbench.

For example, you can view the attributes of a specific LPN in Material Workbench. Use the following instructions to view the contents of an LPN in Material Workbench:

1. Navigate to the Material Workbench window.

2. In the **View By** field, select **LPN** from the list of values.

3. Next, expand the **Organizations** folder to display a list of LPNs that
   are associated with the organization.

4. Select the LPN that you want to view.

5. The system displays the contents of the LPN in the right panel of the
   window. You can also expand an LPN in the left column to view its specific
   contents.

![]({% asset_path 2018-06-04-lpn-overview-part1/picture3.png %})

Note:

The **Status** field shows the material status for on-hand material at
status-enabled organizations.

### Viewing LPNs with the Mobile User Interface

1. Log in to the mobile user interface under the **Whse Mgmt** responsibility.

2. From the **Whse Mgmt** menu, select **Inquiry**.

3. From the **Inquiry** menu, select the **LPN** option.

4. Finally, in the **LPN** field, enter the LPN or select it from the list of
   values.

### Generating LPNs

You can submit an LPN generation request through the Oracle Warehouse Management Navigator or a through a mobile device.

You can generate LPNs by using one of the following methods:

#### Submit a concurrent request to generate LPNs

You can generate multiple LPNs with a single concurrent request through the Oracle Warehouse Management Navigator.

When you submit a request in the Oracle Warehouse Management Navigator, you must select the **Generate License Plates** option.

Each new LPN can be printed on stickers and accordingly and associated with a particular container item when required, or it can simply be labeled with no physical container association. LPNs can be generated at the sub-inventory and locator, or they can have no location until they are packed.

The LPN generation request creates the specified number of LPNs based on the starting prefix, suffix, and start number indicated either in the request, or at the organization level. Labels for these LPNs are printed accordingly, based on your label printing software and hardware.

#### Use a mobile device to generate LPNs

You can also use the Mobile Receipt & Task form to generate LPNs in Putty/Telnet. Place the cursor in the **LPN** field, then press **Generate** to automatically generate the LPN. The system default shortcut key for **Generate** is **Ctrl+G**.

### Conclusion

LPN’s are an easy method to use to accurately perform inventory transactions in WMS. They are also very user friendly and help save time. In the second part of the article we’ll learn more about generating LPN’s using mobile interface and different types of transactions associated with LPN’s.

I hope you find these hints valuable and are able to put them to good use. If you have any doubts feel free to reach out to me by clicking on the button below. You can also leave your comments and feedback in the field below.
