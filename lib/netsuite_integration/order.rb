module NetsuiteIntegration
  class Order < Base
    attr_reader :config, :collection

    def initialize(config, payload)
      @config = config
      @payload = payload['order'].with_indifferent_access

      @order = NetSuite::Records::SalesOrder.new
    end

    def import
      import_customer!
      import_products!

      @order.order_status = "_pendingFulfillment"

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
        soi = NetSuite::Records::SalesOrderItem.new
        soi.item = NetSuite::Records::RecordRef.new(internal_id: item[:sku].to_i)
        soi.amount = 1
        soi
      end

      soi = NetSuite::Records::SalesOrderItem.new
      soi.item = NetSuite::Records::RecordRef.new(entity_id: "Spree Taxes")
      soi

      item_list.push *custom_products

      @order.item_list = NetSuite::Records::SalesOrderItemList.new(item: item_list)
    end

    # def import_shipping_taxes_and_discount!
    def custom_products
      taxes    = non_inventory_item_service.find_or_create_by_name('Spree Taxes')
      shipping = non_inventory_item_service.find_or_create_by_name('Spree Shipping')
      discount = non_inventory_item_service.find_or_create_by_name('Spree Discount')

      [taxes, shipping, discount].map do |item|
        soi = NetSuite::Records::SalesOrderItem.new
        soi.item = NetSuite::Records::RecordRef.new(internal_id: item.internal_id)
        soi.rate = 10.0
        soi
      end
    end
  end
end
