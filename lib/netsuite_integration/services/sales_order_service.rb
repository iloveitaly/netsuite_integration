module NetsuiteIntegration
  module Services
    class SalesOrderService < Base
      def find_by_external_id(external_id)
        NetSuite::Records::SalesOrder.get external_id: external_id
      rescue NetSuite::RecordNotFound
        nil
      end

      def close!(sales_order)
        # TODO: Mark all sales order items as _closed
        # sales_order.item_list.items
        # https://system.netsuite.com/help/helpcenter/en_US/SchemaBrowser/transactions/v2013_2_0/sales.html#tranSales:SalesOrderItemList
      end
    end
  end
end

