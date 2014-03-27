module NetsuiteIntegration
  module Services
    class Base
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def customer_service
        @customer_service ||= NetsuiteIntegration::Services::Customer.new(@config)
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
