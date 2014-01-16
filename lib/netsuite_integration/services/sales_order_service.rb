module NetsuiteIntegration
  module Services
    class SalesOrderService < Base
      def find_by_external_id(external_id)
        NetSuite::Records::SalesOrder.get external_id: external_id
      rescue NetSuite::RecordNotFound
        nil
      end
    end
  end
end

