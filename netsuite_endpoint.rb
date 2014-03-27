require "sinatra"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/netsuite_integration')

class NetsuiteEndpoint < EndpointBase::Sinatra::Base
  before do
    if @message
      puts "  Start NetSuite API Request at #{Time.now} for #{@message['message']}"
    end

    if config = @config
      @netsuite_client ||= NetSuite.configure do
        reset!
        api_version  '2013_2'
        wsdl         'https://webservices.na1.netsuite.com/wsdl/v2013_2_0/netsuite.wsdl'
        sandbox      false
        email        config.fetch('netsuite.email')
        password     config.fetch('netsuite.password')
        account      config.fetch('netsuite.account')
        read_timeout 175
        log_level    :info
      end
    end
  end

  after do
    if @message
      puts "  End NetSuite API Request at #{Time.now} for #{@message['message']}"
    end
  end

  post '/products' do
    begin
      products = NetsuiteIntegration::Product.new(@config)

      if products.collection.any?
        add_messages "product:import", products.messages
        add_parameter 'netsuite.last_updated_after', products.last_modified_date
        add_notification "info", "#{products.messages.count} items found in NetSuite"
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
    rescue NetSuite::RecordNotFound => e
      add_notification "error", e.message
      process_result 500
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
      process_result 200
    rescue => e
      add_notification "error", e.message, e.backtrace.to_a.join("\n")
      process_result 500
    end
  end

  post '/shipments' do
    begin
      order = NetsuiteIntegration::Shipment.new(@message, @config).import
      add_notification "info", "Order #{order.external_id} fulfilled in NetSuite # #{order.tran_id}"
      process_result 200
    rescue StandardError => e
      add_notification "error", e.message, e.backtrace.to_a.join("\n")
      process_result 500
    end
  end

  private
  def create_or_update_order
    order = NetsuiteIntegration::Order.new(@config, @message)

    if order.imported?
      if order.update
        add_notification "info", "Order #{order.existing_sales_order.external_id} updated on NetSuite # #{order.existing_sales_order.tran_id}"
      else
        add_notification "error", "Failed to import order #{order.sales_order.external_id} into Netsuite", order.errors
      end
    else
      if order.create
        add_notification "info", "Order #{order.sales_order.external_id} sent to NetSuite # #{order.sales_order.tran_id}"
      else
        add_notification "error", "Failed to import order #{order.sales_order.external_id} into Netsuite", order.errors
      end
    end

    if order.paid?
      customer_deposit = NetsuiteIntegration::Services::CustomerDeposit.new(@config, @message[:payload])
      records = customer_deposit.create_records order.sales_order

      errors = records.map(&:errors).compact.map(&:message).flatten

      if errors.any?
        add_notification "error", "Failed to set up Customer Deposit for #{order.existing_sales_order.external_id} in NetSuite", errors.join(", ")
      end

      if customer_deposit.persisted
        add_notification "info", "Customer Deposit set up for Sales Order #{(order.existing_sales_order || order.sales_order).tran_id}", errors.join(", ")
      end
    end

    if @notifications.any? { |n| n[:level] == "error" }
      process_result 500
    else
      process_result 200
    end
  end

  def cancel_order
    order = sales_order_service.find_by_external_id(@message[:payload][:order][:number]) or 
      raise RecordNotFoundSalesOrder, "NetSuite Sales Order not found for order #{order_payload[:number]}"

    if customer_record_exists?
      sales_order_service.close!(order)
      add_notification "info", "NetSuite Sales Order #{@message[:payload][:order][:number]} was closed"

      process_result 200
    else
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

  def customer_record_exists?
    @message[:payload][:original][:payment_state] == 'balance_due'
  end

  def sales_order_service
    @sales_order_service ||= NetsuiteIntegration::Services::SalesOrder.new(@config)
  end
end
