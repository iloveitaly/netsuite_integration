module NetsuiteIntegration
  class Order < Base
    attr_reader :config, :collection

    def initialize(config, message)
      super(message, config)

      @config = config
      @payload = payload['order'].with_indifferent_access

      @order = NetSuite::Records::SalesOrder.new({
        order_status: '_pendingFulfillment',
        external_id: @payload[:number]
      })
    end

    def import
      raise AlreadyImportedException if order_already_imported?

      import_customer!
      import_products!
      import_shipping!

      @order if @order.add
    end

    private
    def import_customer!
      if customer = customer_service.find_by_external_id(payload[:user_id])
        if customer.addressbook_list.addressbooks == []
          # update address if missing
          customer_service.update_address(customer, payload['shipping_address'])
        end
      else
        customer_json = payload['shipping_address'].dup
        customer_json[:id] = payload[:user_id]

        customer = customer_service.create(customer_json)
      end

      @order.entity = NetSuite::Records::RecordRef.new(external_id: customer.external_id)
    end

    def import_products!
      item_list = payload[:line_items].map do |item|
        NetSuite::Records::SalesOrderItem.new({
          item: { internal_id: item[:sku].to_i },
          amount: item[:quantity]
        })
      end

      # Due to NetSuite complexity, taxes and discounts will be treated as line items.
      ["tax", "discount"].map do |type|
        if value = payload[:totals][type]
          item_list.push(NetSuite::Records::SalesOrderItem.new({
            item: { internal_id: internal_id_for(type) },
            rate: value
          }))
        end
      end

      @order.item_list = NetSuite::Records::SalesOrderItemList.new(item: item_list)
    end

    def import_shipping!
      @order.shipping_cost = payload[:totals][:shipping]
      @order.ship_method = NetSuite::Records::RecordRef.new(internal_id: shipping_id)
    end

    def shipping_id
      77 # should be resolved on a shipping mapping
    end

    def internal_id_for(type)
      non_inventory_item_service.find_or_create_by_name("Spree #{type.capitalize}").internal_id
    end

    def order_already_imported?
      NetSuite::Records::SalesOrder.get(external_id: payload[:number])
    rescue NetSuite::RecordNotFound
      false
    end

    class AlreadyImportedException < Exception; end
  end
end
