# NetSuite Integration

## Overview

[NetSuite](http://www.netsuite.com) is a web-based business software suite,
including business accounting software, ERP software, CRM software and ecommerce.

#### Parameters

| Name | Value | example |
| :----| :-----|
| netsuite.email | netsuite account email | |
| netsuite.password | netsuite account password | |
| netsuite.account | netsuite account | |
| netsuite.last_updated_after | Update products after this timestamp | 2014-01-29T03:14:07+00:00 |
| netsuite.account_for_sales_id | Account used on customer deposits | |
| netsuite.shipping_methods_mapping | A list of mappings store shipping method name => NetSuite Id | [{"UPS Ground (USD)"=>"92", "UPS Two Day (USD)"=>"77", "UPS One Day (USD)"=>"712"}] |
| netsuite.payment_methods_mapping | A list of mappings store payment method name => NetSuite id | [{"Cash"=>"1", "Credit Card"=>"5"}] |

## Services

  * Product Import - poll products from NetSuite
  * Monitor Stock - poll inventory stock from NetSuite
  * Orders Export - Import orders from the store into NetSuite as Sales Order
  * Shipments Export - Fulfills Sales Order in NetSuite
