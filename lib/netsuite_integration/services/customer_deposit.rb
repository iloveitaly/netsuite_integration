module NetsuiteIntegration
  module Services
    class CustomerDeposit < Base
      attr_reader :payments, :persisted

      def initialize(config, payload = {})
        super config
        @payments = payload[:order][:payments] if payload[:order]
      end

      def create_records(sales_order)
        payments.map do |payment|
          external_id = "#{prefix}-#{sales_order.external_id}-#{payment[:number]}"

          if payment[:amount] > 0
            unless record = find_by_external_id(external_id)
              record = build(sales_order, payment)
              # Need to know if at least one of them was persisted
              @persisted ||= record.add
            end
          end

          record
        end.compact
      end

      # Apparently we dont need to pass the customer reference. Tried that for a
      # while and was either getting "permission error" or "Invalid reference
      # for customer key 4353 (customer internal id)"
      def build(sales_order, payment)
        deposit = NetSuite::Records::CustomerDeposit.new

        # Setting external_id to Spree's order number, so we could search by it later
        # Warning: external_id must be unique across all NetSuite data objects
        # TODO Revisit searching for customer deposits for a specific sales order
        deposit.external_id = "#{prefix}-#{sales_order.external_id}-#{payment[:number]}"

        # deposit.customer = NetSuite::Records::RecordRef.new(internal_id: sales_order.entity.internal_id)
        deposit.sales_order = NetSuite::Records::RecordRef.new(internal_id: sales_order.internal_id)
        # TODO check for reference error between customer and account
        deposit.account = NetSuite::Records::RecordRef.new(internal_id: config.fetch('netsuite.account_for_sales_id'))
        deposit.payment = payment[:amount]

        deposit
      end

      # Current limitation is that we can only get 1 customer deposit back
      def find_by_external_id(external_id)
        NetSuite::Records::CustomerDeposit.get external_id: external_id
      rescue NetSuite::RecordNotFound
        nil
      end

      def find_by_sales_order(sales_order, payments)
        payments.map do |p|
          next unless p[:amount] > 0

          external_id = build_id sales_order, p
          NetSuite::Records::CustomerDeposit.get external_id: external_id
        end.compact
      end

      private
        def build_id(sales_order, payment)
          "#{prefix}-#{sales_order.external_id}-#{payment[:number]}"
        end

        # Prefix is used to avoid running into external_id duplications
        def prefix
          'cd'
        end
    end
  end
end
