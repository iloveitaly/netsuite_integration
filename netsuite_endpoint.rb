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
      if order = NetsuiteIntegration::Order.new(@config, @message).import
        add_notification "info", "Order #{order.external_id} imported into NetSuite"
      end

      process_result 200
    rescue NetsuiteIntegration::Order::AlreadyImportedException
      add_notification "info", "Order #{@message[:payload][:order][:number]} has already been imported into NetSuite"

      process_result 200
    rescue Exception => e
      add_notification "error", e.message, nil, { backtrace: e.backtrace.to_a.join("\n\t") }

      process_result 500
    end
  end
end
