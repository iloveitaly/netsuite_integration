# NetSuite Integration

[NetSuite](http://www.netsuite.com) is a web-based business software suite,
including business accounting software, ERP software, CRM software and ecommerce.

This is a fully hosted and supported integration for use with the [Wombat](http://wombat.co)
product. With this integration you can perform the following functions:

* Send orders to NetSuite as Sales Orders
* Send customers to NetSuite (through orders)
* Poll for Inventory Item (or any other kind of Item) from NetSuite
* Create refunds and close Sales Orders in NetSuite once order is canceled
* Poll for Items in NetSuite (they're persisted as products in wombat.co)
* Poll for shipments (Item Fulfillments) from NetSuite
* Send shipments as Item Fulfillment to NetSuite along with Invoice creation

See The [SuiteTalk Web Services](https://system.netsuite.com/help/helpcenter/en_US/Output/Help/SuiteCloudCustomizationScriptingWebServices/SuiteTalkWebServices/SuiteTalkWebServices.html) for further info on how integration can be improved.

Also view the [wiki](https://github.com/wombat/netsuite_integration/wiki) for
more details about parameters and webhooks.

> NOTE: To run the specs on this repo you need to check out the [cassetes](https://github.com/wombat/netsuite_integration/tree/cassetes)
branch. No cassetes should be recorded on master. Also all commits in
master are regurlarly merged into the cassetes branch.

[Wombat](http://wombat.co) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

![Wombat Logo](http://spreecommerce.com/images/wombat_logo.png)

This integration is 100% open source an licensed under the terms of the New BSD License.

