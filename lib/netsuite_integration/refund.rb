module NetsuiteIntegration
  class Refund < Base
    attr_reader :config, :user_id, :original_payload, :order_payload, :sales_order, :customer_deposit

    def initialize(config, message)
      super(message, config)

      @config           = config
      @user_id          = original[:user_id]
      @order_payload    = payload[:order]
      @original_payload = payload[:original]

      @sales_order      = sales_order_service.find_by_external_id(order_payload[:number]) or 
        raise RecordNotFoundSalesOrder, "NetSuite Sales Order not found for order #{order_payload[:number]}"
      @customer_deposit = customer_deposit_service.find_by_external_id(order_payload[:number]) or
        raise RecordNotFoundCustomerDeposit, "NetSuite Customer Deposit not found for order #{order_payload[:number]}"
    end

    def process!
      if customer_refund_service.create user_id, payment_method_id, customer_deposit.internal_id, order_payload[:number]
        sales_order_service.close! sales_order
      end
    end

    private
    def payment_method_id
      '1' # TODO Implement payment_method list parameter
    end
  end
end
