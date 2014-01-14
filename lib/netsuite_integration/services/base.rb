module NetsuiteIntegration
  module Services
    class Base
      attr_reader :config

      class << self
        attr_accessor :client
      end

      def initialize(config)
        @config = config

        self.class.client ||= NetSuite.configure do
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
    end
  end
end
