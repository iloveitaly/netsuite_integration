module NetsuiteIntegration
  module Services
    class CustomerDeposit < Base
      # Apparently we dont need to pass the customer reference. Tried that for a
      # while and was either getting "permission error" or "Invalid reference
      # for customer key 4353 (customer internal id)"
      def create(sales_order_id)
        deposit = NetSuite::Records::CustomerDeposit.new
        deposit.sales_order = NetSuite::Records::RecordRef.new(internal_id: sales_order_id)
        deposit.payment = 20

        deposit.add
      end
    end
  end
end
