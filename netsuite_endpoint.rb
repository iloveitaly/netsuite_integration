require "sinatra"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/netsuite_integration')

class NetsuiteEndpoint < EndpointBase::Sinatra::Base
  before do
    if config = @config
      @netsuite_client ||= NetSuite.configure do
        reset!
        api_version  '2013_2'
        wsdl         'https://webservices.na1.netsuite.com/wsdl/v2013_2_0/netsuite.wsdl'
        sandbox      false
        email        config.fetch('netsuite_email')
        password     config.fetch('netsuite_password')
        account      config.fetch('netsuite_account')
        read_timeout 175
        log_level    :info
      end
    end
  end

  post '/get_products' do
    begin
      products = NetsuiteIntegration::Product.new(@config)

      if products.collection.any?
        add_object "product", products.messages
        add_parameter 'netsuite_last_updated_after', products.last_modified_date
        @summary = "#{products.messages.count} items found in NetSuite"
      end

      result 200, @summary
    rescue StandardError => e
      result 500, e.message
    end
  end

  post '/add_order' do
    begin
      create_or_update_order
    rescue NetSuite::RecordNotFound => e
      result 500, e.message
    rescue StandardError => e
      result 500, e.message
    end
  end

  post '/update_order' do
    begin
      create_or_update_order
    rescue NetSuite::RecordNotFound => e
      result 500, e.message
    rescue StandardError => e
      result 500, e.message
    end
  end

  post '/cancel_order' do
    begin
      order = sales_order_service.find_by_external_id(@payload[:order][:number]) or
        raise RecordNotFoundSalesOrder, "NetSuite Sales Order not found for order #{@payload[:order][:number]}"

      if customer_record_exists?
        refund = NetsuiteIntegration::Refund.new(@config, @payload, order)
        if refund.process!
          summary = "Customer Refund created and NetSuite Sales Order #{@payload[:order][:number]} was closed"
          result 200, summary
        else
          summary = "Failed to create a Customer Refund and close the NetSuite Sales Order #{@payload[:order][:number]}"
          result 500, summary
        end
      else
        sales_order_service.close!(order)
        result 200, "NetSuite Sales Order #{@payload[:order][:number]} was closed"
      end
    rescue => e
      result 500, e.message
    end
  end

  post '/get_inventory' do
    begin
      stock = NetsuiteIntegration::InventoryStock.new(@config, @payload)

      add_object :inventory, { sku: stock.sku, quantity: stock.quantity_available }
      summary = "#{stock.quantity_available} units available of #{stock.sku} according to NetSuite"
      result 200, summary
    rescue NetSuite::RecordNotFound
      result 200
    rescue => e
      result 500, e.message
    end
  end

  post '/add_shipment' do
    begin
      order = NetsuiteIntegration::Shipment.new(@config, @payload).import
      result 200, "Order #{order.external_id} fulfilled in NetSuite # #{order.tran_id}"
    rescue StandardError => e
      result 500, e.message
    end
  end

  private
  def create_or_update_order
    order = NetsuiteIntegration::Order.new(@config, @payload)

    error_notification = ""

    if order.imported?
      if order.update
        summary = "Order #{order.existing_sales_order.external_id} updated on NetSuite # #{order.existing_sales_order.tran_id}"
      else
        error_notification = "Failed to import order #{order.sales_order.external_id} into Netsuite"
      end
    else
      if order.create
        summary = "Order #{order.sales_order.external_id} sent to NetSuite # #{order.sales_order.tran_id}"
      else
        error_notification = "Failed to import order #{order.sales_order.external_id} into Netsuite"
      end
    end

    if order.paid?
      customer_deposit = NetsuiteIntegration::Services::CustomerDeposit.new(@config, @payload)
      records = customer_deposit.create_records order.sales_order

      errors = records.map(&:errors).compact.flatten
      errors = errors.map(&:message).flatten

      if errors.any?
        error_notification << " Failed to set up Customer Deposit for #{order.existing_sales_order.external_id} in NetSuite"
      end

      if customer_deposit.persisted
        summary << "Customer Deposit set up for Sales Order #{(order.existing_sales_order || order.sales_order).tran_id}"
      end
    end

    if any_payments_void?
      refund = NetsuiteIntegration::Refund.new(@config, @payload, order.existing_sales_order, "void")

      unless refund.service.find_by_external_id(refund.deposits)
        if refund.create
          summary << "Customer Refund created for #{@payload[:order][:number]}"
        else
          error_notification << "Failed to create a Customer Refund for order #{@payload[:order][:number]}"
        end
      end
    end

    if error_notification.present?
      result 500, error_notification
    else
      result 200, summary
    end
  end

  def customer_record_exists?
    @payload[:order][:payments] && @payload[:order][:payments].any?
  end

  def sales_order_service
    @sales_order_service ||= NetsuiteIntegration::Services::SalesOrder.new(@config)
  end

  def any_payments_void?
    @payload[:order][:payments].any? do |p|
      p[:status] == "void"
    end
  end
end
