# NetSuite Integration

## Overview

[NetSuite](http://www.netsuite.com) is a web-based business software suite,
including business accounting software, ERP software, CRM software and ecommerce.

#### Connection Parameters

| Name | Value | example |
| :----| :-----| :------ |
| netsuite_email | netsuite account email (required) | spree@example.com |
| netsuite_password | netsuite account password (required) | commerce |
| netsuite_account | netsuite account (required) | TSWQEFREGR2342 |
| netsuite_wsdl_url | NetSuite URL (optional as it's also defined by netsuite gem) | https://webservices.na1.netsuite.com/wsdl/v2013_2_0/netsuite.wsdl |
| netsuite_api_version | Optional api version (defaults to 2013_2) | 2012_2 |
| netsuite_sandbox | Optional sandbox flag (defaults `false`) | true |
| netsuite_role | NetSuite user role ID (defaults to 3) | 3 |

### Product polling

/get_products webhook

| Name | Value | example |
| :----| :-----| :------ |
| netsuite_last_updated_after | Fetch products updated after this timestamp | 2014-01-29T03:14:07+00:00 |
| netsuite_item_types | List of item types you want to poll (default to InventoryItem) | InventoryItem; NonInventoryItem |

See https://system.netsuite.com/help/helpcenter/en_US/SchemaBrowser/lists/v2013_2_0/accountingTypes.html#listAcctTyp:ItemType
for a list of valid item types.

### Inventory polling

/get_inventory webhook

| Name | Value | example |
| :----| :-----| :------ |
| netsuite_poll_stock_timestamp | Fetch inventories quantity updated after this timestamp | 2014-01-29T03:14:07+00:00 |

### Push Orders

/add_order and /update_order webhooks

| Name | Value | example |
| :----| :-----| :------ |
| netsuite_account_for_sales_id | Account id used on customer deposit and refund (required) | 2 |
| netsuite_sales_order_custom_form_id | Depending on your NS instance a custom form id will need to be set to close the sales order | 164 |
| netsuite_item_for_discounts | Item name to represent store discounts | Spree Discount |
| netsuite_item_for_taxes | Item name to represent store taxes | Spree Tax |
| netsuite_payment_methods_mapping | A list of mappings store payment method name => NetSuite id | [{"Cash"=>"1", "Credit Card"=>"5"}] |
| netsuite_department_id | Sales Order Department ID (optional) | 5 |

The Sales Order shipping cost will be set according to `order[:totals][:shipping]`.
Taxes and Discounts are set from values within `order[:adjustments]`. e.g.

```json
{
  "totals": {
    "shipping": 7
  },
  "adjustments": [
    { "name": "Tax", "value": 7 },
    { "name": "Discount", "value": -5 }
  ]
}
```

See http://spreecommerce.com/docs/hub/order_object.html for examples on the order object.

### Cancel Orders / Refunds

/cancel_order webhook

| Name | Value | example |
| :----| :-----| :------ |
| netsuite_account_for_sales_id | Account id used on customer deposit and refund (required) | 2 |
| netsuite_payment_methods_mapping | A list of mappings store payment method name => NetSuite id | [{"Cash"=>"1", "Credit Card"=>"5"}] |

### Push shipments

/add_shipment webhooks.

Doesn't require any config parameter

### Get shipments

/get_shipments

| Name | Value | example |
| :----| :-----| :------ |
| netsuite_poll_fulfillment_timestamp | Fetch Item Fulfillments updated after this timestamp | 2014-01-29T03:14:07+00:00 |
