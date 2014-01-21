module NetsuiteIntegration
  module Services
    class CustomerRefund < Base

      def create(customer_id, total)
        refund                = NetSuite::Records::CustomerRefund.new
        refund.total          = "1"
        refund.customer       = NetSuite::Records::RecordRef.new(internal_id: '1700') # Client: Sameer
        refund.payment_method = NetSuite::Records::RecordRef.new(internal_id: '1') # Cash
        refund.account        = NetSuite::Records::RecordRef.new(internal_id: '182') # CC Receivables

        list = NetSuite::Records::CustomerRefundDepositList.new(customer_refund_deposit: [{apply: 'true', ref_num: '11', total: '2'}])
        list.replace_all = 'false'
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
