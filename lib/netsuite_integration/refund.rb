module NetsuiteIntegration
  class Refund < Base
    attr_reader :config, :user_id, :original, :order_payload, :sales_order

    def initialize(config, message)
      super(message, config)

      @config           = config
      @user_id          = original[:user_id]
      @order_payload    = payload[:order]
      @original_payload = payload[:original]

      @sales_order = sales_order_service.find_by_external_id(order_payload[:number])
    end

    def process!
      # raise AlreadyRefundedSalesOrderException if order_already_refunded?

      if customer_refund_service.create user_id, payment_method, account
        sales_order_service.close! sales_order
      else
        # raise error
      end
    end

    private
    def payment_method
      if original_payload[:credit_cards].count > 0
        original_payload[:credit_cards].first['cc_type']
      else
        'check'
      end
    end
  end
end
