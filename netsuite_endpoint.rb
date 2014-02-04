require "sinatra"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/netsuite_integration')

class NetsuiteEndpoint < EndpointBase::Sinatra::Base
  before do
    puts "  Start NetSuite API Request at #{Time.now}"
    sleep 3 # NetSuite does not allow concurrency, need to be safe

    if config = @config
      @netsuite_client ||= NetSuite.configure do
        reset!
        api_version  '2013_2'
        wsdl         'https://webservices.na1.netsuite.com/wsdl/v2013_2_0/netsuite.wsdl'
        sandbox      false
        email        config.fetch('netsuite.email')
        password     config.fetch('netsuite.password')
        account      config.fetch('netsuite.account')
        read_timeout 100000000
        log_level    :info
      end
    end
  end

  after do
    puts "  End NetSuite API Request at #{Time.now}"
  end

  post '/products' do
    begin
      products = NetsuiteIntegration::Product.new(@config)

      if products.collection.any?
        add_messages "product:import", products.messages
        add_parameter 'netsuite.last_updated_after', products.last_modified_date
        add_notification "info", "#{products.collection.count} items imported from NetSuite"
      end

      process_result 200
    rescue StandardError => e
      add_notification "error", e.message, nil, { backtrace: e.backtrace.to_a.join("\n\t") }
      process_result 500
    end
  end

  post '/orders' do
    begin
      case @message['message']
      when 'order:new', 'order:updated'
        create_or_update_order
      when 'order:canceled', 'order:cancelled'
        cancel_order
      end
    rescue StandardError => e
      add_notification "error", e.message, nil, { backtrace: e.backtrace.to_a.join("\n\t") }
      process_result 500
    end
  end

  post '/inventory_stock' do
    begin
      stock = NetsuiteIntegration::InventoryStock.new(@config, @message)
      add_message 'stock:actual', { sku: stock.sku, quantity: stock.quantity_available }
      add_notification "info", "#{stock.quantity_available} units available of #{stock.sku} according to NetSuite"
      process_result 200
    rescue NetSuite::RecordNotFound
      add_notification "info", "Inventory Item #{@message[:payload][:sku]} not found on NetSuite"
      process_result 200
    rescue => e
      add_notification "error", e.message, e.backtrace.to_a.join("\n")
      process_result 500
    end
  end

  post '/shipments' do
    begin
      order = NetsuiteIntegration::Shipment.new(@message, @config).import
      add_notification "info", "Order #{order.external_id} fulfilled in NetSuite (internal id #{order.internal_id})"
      process_result 200
    rescue StandardError => e
      add_notification "error", e.message, e.backtrace.to_a.join("\n")
      process_result 500
    end
  end

  private
  def create_or_update_order
    order = NetsuiteIntegration::Order.new(@config, @message)

    unless order.imported?
      if order.import
        add_notification "info", "Order #{order.sales_order.external_id} imported into NetSuite (internal id #{order.sales_order.internal_id})"
        process_result 200
      else
        add_notification "error", "Failed to import order #{order.sales_order.external_id} into Netsuite"
        process_result 500
      end
    else
      if order.got_paid?
        if order.create_customer_deposit
          add_notification "info", "Customer Deposit created for NetSuite Sales Order #{order.sales_order.external_id}"
          process_result 200
        else
          add_notification "error", "Failed to create a Customer Deposit for NetSuite Sales Order #{order.sales_order.external_id}"
          process_result 500
        end
      else
        process_result 200
      end
    end
  end

  def cancel_order
    order = sales_order_service.find_by_external_id(@message[:payload][:order][:number]) or 
      raise RecordNotFoundSalesOrder, "NetSuite Sales Order not found for order #{order_payload[:number]}"
    if balance_due? # No CustomerDeposit record
      sales_order_service.close!(order)

      add_notification "info", "NetSuite Sales Order #{@message[:payload][:order][:number]} was closed"
      process_result 200
    else # CustomerDeposit record exists
      refund = NetsuiteIntegration::Refund.new(@config, @message, order)
      if refund.process!
        add_notification "info", "Customer Refund created and NetSuite Sales Order #{@message[:payload][:order][:number]} was closed"
        process_result 200
      else
        add_notification "error", "Failed to create a Customer Refund and close the NetSuite Sales Order #{@message[:payload][:order][:number]}"
        process_result 500
      end      
    end
  end

  # 'balance_due' means that there is no customer deposit
  # associated with the order in the NetSuite system
  def balance_due?
    @message[:payload][:original][:payment_state] == 'balance_due'
  end

  def sales_order_service
    @sales_order_service ||= NetsuiteIntegration::Services::SalesOrder.new(@config)
  end
end
