module NetsuiteIntegration
  class Base
    attr_accessor :payload, :message_name, :message_id, :config#, :original

    def initialize(message = {}, config)
      @config = config

      @payload = message[:payload].with_indifferent_access
      @original = payload[:original]
      @message_name = message[:message]
      @message_id = message[:message_id]

      NetSuite.configure do
        reset!
        api_version config.fetch('netsuite.api_version')
        wsdl        config.fetch('netsuite.wsdl_url')
        sandbox     config.fetch('netsuite.sandbox')
        email       config.fetch('netsuite.email')
        password    config.fetch('netsuite.password')
        account     config.fetch('netsuite.account')
        role        config.fetch('netsuite.role_id')
        log_level   :error
      end
    end

    def customer_service
      @customer_service ||= NetsuiteIntegration::Services::CustomerService.new(@config)
    end

    def inventory_item_service
      @inventory_item_service ||= NetsuiteIntegration::Services::InventoryItem.new(@config)
    end

    def non_inventory_item_service
      @non_inventory_item_service ||= NetsuiteIntegration::Services::NonInventoryItemService.new(@config)
    end

    def sales_order_service
      @sales_order_service ||= NetsuiteIntegration::Services::SalesOrderService.new(@config)
    end
  end

  class AlreadyPersistedCustomerException < Exception; end
  class UpdateFailCustomerException < Exception; end
  class CreationFailCustomerException < Exception; end
end
