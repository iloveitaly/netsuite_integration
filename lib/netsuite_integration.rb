$:.unshift File.dirname(__FILE__)

require 'netsuite'

require 'netsuite_integration/services/base'
require 'netsuite_integration/services/inventory_item'
require 'netsuite_integration/services/customer_service'
require 'netsuite_integration/services/non_inventory_item_service'

require 'netsuite_integration/base'
require 'netsuite_integration/customer_importer'
require 'netsuite_integration/product'
require 'netsuite_integration/order'