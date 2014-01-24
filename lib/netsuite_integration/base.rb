module NetsuiteIntegration
  class Base
    attr_accessor :payload, :message_name, :message_id, :config, :original

    def initialize(message = {}, config)
      @config = config
      
      @payload = message[:payload].with_indifferent_access
      @original = payload[:original]
      @message_name = message[:message]
      @message_id = message[:message_id]
    end

    def customer_service
      @customer_service ||= NetsuiteIntegration::Services::CustomerService.new(@config)
    end

    def customer_refund_service
      @customer_refund_service ||= NetsuiteIntegration::Services::CustomerRefund.new(@config)
    end

    def customer_deposit_service
      @customer_deposit_service ||= NetsuiteIntegration::Services::CustomerDeposit.new(@config)
    end

    def inventory_item_service
      @inventory_item_service ||= NetsuiteIntegration::Services::InventoryItem.new(@config)
    end

    def non_inventory_item_service
      @non_inventory_item_service ||= NetsuiteIntegration::Services::NonInventoryItemService.new(@config)
    end

    def sales_order_service
      @sales_order_service ||= NetsuiteIntegration::Services::SalesOrder.new(@config)
    end
  end

  # Customer Errors
  class AlreadyPersistedCustomerException < Exception; end
  class UpdateFailCustomerException < Exception; end
  class CreationFailCustomerException < Exception; end
  class RecordNotFoundCustomerException < Exception; end

  # Customer Deposit Errors
  class RecordNotFoundCustomerDeposit < Exception; end

  # Sales Order Errors
  class RecordNotFoundSalesOrder < Exception; end

  # Customer Refund Errors
  class CreationFailCustomerRefundException < Exception; end
end
