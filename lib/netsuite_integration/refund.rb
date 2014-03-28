module NetsuiteIntegration
  class Refund < Base
    attr_reader :user_id, :order_payload, :sales_order, :customer, :deposits, :refund_service

    def initialize(config, message, sales_order)
      super(message, config)

      @user_id          = original[:user_id]
      @order_payload    = payload[:order]

      @sales_order      = sales_order
      @deposits = customer_deposit_service.find_by_sales_order sales_order, order_payload[:payments]

      @customer = customer_service.find_by_external_id(order_payload[:email]) or
        raise RecordNotFoundCustomerException, "NetSuite Customer not found for Spree user_id #{user_id}"

      @refund_service = Services::CustomerRefund.new(config, customer.internal_id, payment_method_id)
    end

    def process!
      if refund_service.create sales_order, deposits
        sales_order_service.close! sales_order
      end
    end

    private
    def payment_method_id
      method = @payload[:order][:payments][0][:payment_method]
      @config['netsuite.payment_methods_mapping'][0].fetch(method).to_i
    rescue
      raise "Payment method #{method} not found in #{@config['netsuite.payment_methods_mapping'].inspect}"
    end
  end
end
