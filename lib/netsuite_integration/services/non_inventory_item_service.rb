module NetsuiteIntegration
  module Services
    class NonInventoryItemService < Base
      attr_reader :errors

      def find_or_create_by_name(name)
        unless item = inventory_item_service.find_by_name(name)
          new_item = NetSuite::Records::NonInventorySaleItem.new(
            item_id: name,
            display_name: name,
            external_id: name
          )

          if new_item.add
            # unfortunately, we have to reload the object
            item = inventory_item_service.find_by_name(name)
          else
            @errors = new_item.errors
          end
        end

        item
      end

      def error_messages
        if errors && errors.is_a?(Array)
          errors.map(&:message).join(", ")
        end
      end
    end
  end
end
