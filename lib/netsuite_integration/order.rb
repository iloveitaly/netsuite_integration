module NetsuiteIntegration
  class Order < Base
    attr_reader :config, :collection

    def initialize(config, payload)
      @config = config
      @payload = payload['order'].with_indifferent_access

      @order = Services::SalesOrder.new(@config).order
    end

    def import
      import_customer!
      import_products!

      @order.order_status = "_pendingFulfillment"

      @order
    end

    private
    def import_customer!
      if customer = customer_service.find_by_external_id(payload[:user_id])
        # update address if missing
      else
        customer_json = payload['shipping_address'].dup
        customer_json[:id] = payload[:user_id]

        customer = customer_service.create(customer_json)
      end

      @order.entity = NetSuite::Records::RecordRef.new(external_id: customer.external_id)
    end

    def import_products!
      item_list = payload[:line_items].map do |item|
        soi = NetSuite::Records::SalesOrderItem.new
        soi.item = NetSuite::Records::RecordRef.new(internal_id: item[:sku].to_i)
        soi.amount = 1
        soi
      end

      @order.item_list = NetSuite::Records::SalesOrderItemList.new(item: item_list)
    end
  end
end
