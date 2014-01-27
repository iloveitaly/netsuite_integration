module NetsuiteIntegration
  module Services
    class CustomerRefund < Base

      def create(customer_id, payment_method_id, customer_deposit_id, order_number)
        refund                = NetSuite::Records::CustomerRefund.new
        # Defaults to the full amount of the customer deposit record
        # refund.total = 100
        refund.customer       = NetSuite::Records::RecordRef.new(internal_id: customer_id) # '1397' -> Smith Supplies
        refund.payment_method = NetSuite::Records::RecordRef.new(internal_id: payment_method_id) # '1' -> Cash        
        # 'account' is an optional field
        # It defaults to the first entry in the UI list... I think
        refund.account        = NetSuite::Records::RecordRef.new(internal_id: config.fetch('netsuite.account_for_sales_id'))
        refund.external_id    = "#{prefix}#{order_number}"
        # doc -> customer_deposit_id
        customer_deposit_hash = {apply: true, doc: customer_deposit_id}
        list = NetSuite::Records::CustomerRefundDepositList.new(replace_all: 'false', customer_refund_deposit: [customer_deposit_hash])

        refund.deposit_list   = list

        refund.add or raise CreationFailCustomerRefundException, "#{refund.errors.first.code}: #{refund.errors.first.message}"
      end

      private
      # Customer refund prefix
      def prefix
        'cr_'
      end
    end
  end
end
