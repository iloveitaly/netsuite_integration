module NetsuiteIntegration
  module Services
    class CustomerRefund < Base
      attr_reader :customer_id, :payment_method_id

      def initialize(config, customer_id, payment_method_id)
        super config

        @customer_id = customer_id
        @payment_method_id = payment_method_id
      end

      def create(sales_order, deposits)
        refund                = NetSuite::Records::CustomerRefund.new

        # Defaults to the full amount of the customer deposit record
        # refund.total = 100
        refund.customer       = NetSuite::Records::RecordRef.new(internal_id: customer_id) # '1397' -> Smith Supplies
        refund.payment_method = NetSuite::Records::RecordRef.new(internal_id: payment_method_id) # '1' -> Cash        

        # 'account' is an optional field
        # It defaults to the first entry in the UI list... I think
        refund.account        = NetSuite::Records::RecordRef.new(internal_id: config.fetch('netsuite_account_for_sales_id'))
        refund.external_id    = build_external_id deposits

        # doc -> customer_deposit_id

        deposits_to_refund = deposits.map do |d|
          { apply: true, doc: d.internal_id }
        end

        list = NetSuite::Records::CustomerRefundDepositList.new(replace_all: 'false', customer_refund_deposit: deposits_to_refund)
        refund.deposit_list   = list

        refund.add or raise CreationFailCustomerRefundException, "#{refund.errors.first.code}: #{refund.errors.first.message}"
      end

      def find_by_external_id(deposits)
        external_id = build_external_id deposits
        NetSuite::Records::CustomerRefund.get external_id: external_id
      end

      private
      # Customer refund prefix
      def prefix
        'cr_'
      end

      def build_external_id(deposits)
        deposit_ids = deposits.map { |d| d.internal_id }.join(".")
        "#{prefix}-#{deposit_ids}"
      end
    end
  end
end
