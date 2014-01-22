module NetsuiteIntegration
  module Services
    class CustomerRefund < Base

      def create(customer_id)
        refund                = NetSuite::Records::CustomerRefund.new
        # refund.total = 100
        # Defaults to the full amount of the associated customer deposit record
        refund.customer       = NetSuite::Records::RecordRef.new(internal_id: '1277') # Client: johnson & johnson
        refund.payment_method = NetSuite::Records::RecordRef.new(internal_id: '1') # Cash
        refund.account        = NetSuite::Records::RecordRef.new(internal_id: '182') # CC Receivables

        # doc: ID of the associated customer deposit record
        # ref_num: Ref No. of the associated customer deposit record
        customer_deposit_hash = {apply: 'true', doc: '5966', ref_num: '5'}
        list = NetSuite::Records::CustomerRefundDepositList.new(replace_all: 'false', customer_refund_deposit: [customer_deposit_hash])

        refund.deposit_list   = list

        if refund.add
          refund
        else
          nil
        end
      end
    end
  end
end
