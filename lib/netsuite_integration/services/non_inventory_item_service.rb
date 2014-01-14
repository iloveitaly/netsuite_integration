module NetsuiteIntegration
  module Services
    class NonInventoryItemService < Base
      def find_or_create_by_name(name)
        unless item = inventory_item_service.find_by_name(name)
          if NetSuite::Records::NonInventorySaleItem.new({
            item_id: name,
            display_name: name,
            external_id: name
            }).add

            # unfortunately, we have to reload the object
            item = inventory_item_service.find_by_name(name)
          end
        end

        item
      end
    end
  end
end
