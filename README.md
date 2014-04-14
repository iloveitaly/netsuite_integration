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

### Product polling

| Name | Value | example |
| :----| :-----| :------ |
| netsuite_last_updated_after | Fetch products updated after this timestamp | 2014-01-29T03:14:07+00:00 |

### Push Orders

| Name | Value | example |
| :----| :-----| :------ |
| netsuite_account_for_sales_id | Account id used on customer deposit and refund (required) | 2 |
| netsuite_payment_methods_mapping | A list of mappings store payment method name => NetSuite id (required for refunds) | [{"Cash"=>"1", "Credit Card"=>"5"}] |
| netsuite_item_for_discounts | Item name to represent store discounts | Spree Discount |
| netsuite_item_for_taxes | Item name to represent store taxes | Spree Tax |

### Push shipments
