require "sinatra"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/netsuite_integration')

class NetsuiteEndpoint < EndpointBase::Sinatra::Base
  post '/products' do
    begin
      products = NetsuiteIntegration::Product.new(@config)

      if products.collection.any?
        add_messages "product:import", products.messages
        add_parameter 'netsuite.last_updated_after', products.last_modified_date
        add_notification "info", "NetSuite Items imported as products up to #{products.last_modified_date}"
      else
        add_notification "info", "No product updated since #{@config.fetch('netsuite.last_updated_after')}"
      end

      process_result 200
    rescue Exception => e
      add_notification "error", e.message, nil, { backtrace: e.backtrace.to_a.join("\n\t") }
      process_result 500
    end
  end

  post '/orders' do
    begin
      order = NetsuiteIntegration::Order.new(@config, @message)

      if order.import
        add_notification "info", "Order #{order.sales_order.external_id} imported into NetSuite"
        process_result 200
      else
        add_notification "error", "Failed to import order #{order.sales_order.external_id} into Netsuite"
        process_result 500
      end
    rescue NetsuiteIntegration::Order::AlreadyImportedException
      add_notification "info", "Order #{@message[:payload][:order][:number]} has already been imported into NetSuite"

      process_result 200
    rescue Exception => e
      add_notification "error", e.message, nil, { backtrace: e.backtrace.to_a.join("\n\t") }

      process_result 500
    end
  end

  post '/inventory_stock' do
    begin
      stock = NetsuiteIntegration::InventoryStock.new(@config, @message)
      add_message 'stock:actual', { sku: stock.sku, quantity: stock.quantity_available }
      add_notification "info", "#{stock.quantity_available} units available of #{stock.sku} according to NetSuite"
    rescue NetsuiteIntegration::RecordNotFound
      add_notification "info", "Inventory Item #{@message[:payload][:sku]} not found on NetSuite"
    end

    process_result 200
  end

  post '/shipments' do
  end
end
