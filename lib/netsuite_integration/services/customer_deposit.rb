module NetsuiteIntegration
  module Services
    class CustomerDeposit < Base
      # Apparently we dont need to pass the customer reference. Tried that for a
      # while and was either getting "permission error" or "Invalid reference
      # for customer key 4353 (customer internal id)"
      #
      # TODO Check whether SalesOrder doesn't have a total attribute returned
      # by webservices
      def create(sales_order, total, order_number)
        deposit = NetSuite::Records::CustomerDeposit.new
        # Setting external_id to Spree's order number, so we could search by it later
        # Warning: external_id must be unique across all NetSuite data objects
        # TODO We might need to revisit searching for customer deposits for a specific sales order in the future
        deposit.external_id = order_number 
        deposit.sales_order = NetSuite::Records::RecordRef.new(internal_id: sales_order.internal_id)
        deposit.payment = total

        deposit.add
      end

      # Current limitation is that we can only get 1 customer deposit back
      def find_by_external_id(external_id)
        NetSuite::Records::CustomerDeposit.get external_id: external_id
      rescue NetSuite::RecordNotFound
        nil
      end      
    end
  end
end
