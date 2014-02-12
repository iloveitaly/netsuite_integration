module NetsuiteIntegration
  class Refund < Base
    attr_reader :config, :user_id, :original_payload, :order_payload, :sales_order, :customer_deposit, :customer

    def initialize(config, message, order)
      super(message, config)

      @config           = config
      @user_id          = original[:user_id]
      @order_payload    = payload[:order]
      @original_payload = payload[:original]

      @sales_order      = order
      @customer_deposit = customer_deposit_service.find_by_external_id(order_payload[:number]) or
        raise RecordNotFoundCustomerDeposit, "NetSuite Customer Deposit not found for order #{order_payload[:number]}"
      @customer = customer_service.find_by_external_id(order_payload[:email]) or
        raise RecordNotFoundCustomerException, "NetSuite Customer not found for Spree user_id #{user_id}"
    end

    def process!
      if customer_refund_service.create customer.internal_id, payment_method_id, customer_deposit.internal_id, order_payload[:number]
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
