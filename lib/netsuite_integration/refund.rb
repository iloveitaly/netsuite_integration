module NetsuiteIntegration
  class Refund < Base
    attr_reader :user_id, :order_payload, :sales_order, :customer, :deposits,
      :service, :payment_state

    def initialize(config, message, sales_order, payment_state = "completed")
      super(config, message)

      @order_payload    = payload[:order]
      @payment_state = payment_state

      @sales_order      = sales_order
      @deposits = customer_deposit_service.find_by_sales_order sales_order, targetted_payments

      @customer = customer_service.find_by_external_id(order_payload[:email]) or
        raise RecordNotFoundCustomerException, "NetSuite Customer not found for Spree user #{order_payload[:email]}"

      @service = Services::CustomerRefund.new(config, customer.internal_id, payment_method_id)
    end

    def process!
      if service.create sales_order, deposits
        sales_order_service.close! sales_order
      end
    end

    def create
      service.create sales_order, deposits
    end

    private
    def payment_method_id
      method = @payload[:order][:payments][0][:payment_method]

      # NOTE due to bug which might send the mapping as a string. e.g.
      #
      #   "[{\"Credit Card\":\"5\"}]"
      #
      if @config.fetch("netsuite_payment_methods_mapping").is_a? String
        JSON.parse(@config.fetch("netsuite_payment_methods_mapping"))
      else
        @config.fetch('netsuite_payment_methods_mapping')
      end[0].fetch(method).to_i

    rescue
      raise "Payment method #{method} not found in #{@config['netsuite_payment_methods_mapping'].inspect}"
    end

    def targetted_payments
      order_payload[:payments].select { |p| p[:status] == payment_state }
    end
  end
end
