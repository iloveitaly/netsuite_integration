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
        # TODO Revisit searching for customer deposits for a specific sales order
        deposit.external_id = "#{prefix}#{order_number}" 

        # deposit.customer = NetSuite::Records::RecordRef.new(internal_id: sales_order.entity.internal_id)
        deposit.sales_order = NetSuite::Records::RecordRef.new(internal_id: sales_order.internal_id)
        deposit.account = NetSuite::Records::RecordRef.new(internal_id: 119)
        deposit.payment = total

        deposit.add
      end

      # Current limitation is that we can only get 1 customer deposit back
      def find_by_external_id(external_id)
        NetSuite::Records::CustomerDeposit.get external_id: "#{prefix}#{external_id}"
      rescue NetSuite::RecordNotFound
        nil
      end

      private
      # Prefix is used to avoid running into external_id duplications
      def prefix
        'cd_'
      end
    end
  end
end
