module NetsuiteIntegration
  module Services
    class SalesOrder < Base
      def find_by_external_id(external_id)
        NetSuite::Records::SalesOrder.get external_id: external_id
      rescue NetSuite::RecordNotFound
        nil
      end

      def close!(sales_order)
        attributes = sales_order.attributes
        attributes[:item_list].items.each do |item|
          item.is_closed = true
          item.attributes = item.attributes.slice(:line, :is_closed)
        end

        sales_order.update({ item_list: attributes[:item_list] })
      end
    end
  end
end
