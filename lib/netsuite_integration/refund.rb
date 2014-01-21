module NetsuiteIntegration
  class Refund < Base
    attr_reader :config, :collection, :user_id, :original, :order_payload, :sales_order

    def initialize(config, message)
      super(message, config)

      @config           = config
      @user_id          = original[:user_id]
      @order_payload    = payload[:order]
      @original_payload = payload[:original]

      @sales_order = NetsuiteIntegration::Services::SalesOrderService.find_by_external_id(order_payload[:number])
    end

    def process!
      # raise AlreadyRefundedSalesOrderException if order_already_refunded?

      customer_refund = Services::CustomerRefund.new(config)

      if customer_refund.create user_id, order_payload[:totals][:order], payment_method
        NetsuiteIntegration::Services::SalesOrderService.close! sales_order
      else
        # IDK
      end
    end

    private
    def payment_method
      if original_payload[:credit_cards].count > 0
        original_payload[:credit_cards].first['cc_type']
      else
        'check'
      end
    end
    # def import_customer!
    #   order_payload[:shipping_address][:country] = "_unitedStates"

    #   if customer = customer_service.find_by_external_id(user_id)
    #     if customer.addressbook_list.addressbooks == []
    #       # update address if missing
    #       customer_service.update_address(customer, order_payload[:shipping_address])
    #     end
    #   else
    #     customer_json = order_payload[:shipping_address].dup
    #     customer_json[:id] = user_id
    #     customer = customer_service.create(customer_json)
    #   end

    #   sales_order.entity = NetSuite::Records::RecordRef.new(external_id: customer.external_id)
    # end

    # def import_products!
    #   item_list = order_payload[:line_items].map do |item|
    #     NetSuite::Records::SalesOrderItem.new({
    #       item: { internal_id: item[:sku].to_i },
    #       amount: item[:quantity]
    #     })
    #   end

    #   # Due to NetSuite complexity, taxes and discounts will be treated as line items.
    #   ["tax", "discount"].map do |type|
    #     if value = order_payload[:totals][type]
    #       item_list.push(NetSuite::Records::SalesOrderItem.new({
    #         item: { internal_id: internal_id_for(type) },
    #         rate: value
    #       }))
    #     end
    #   end

    #   sales_order.item_list = NetSuite::Records::SalesOrderItemList.new(item: item_list)
    # end

    # def import_shipping!
    #   sales_order.shipping_cost = order_payload[:totals][:shipping]
    #   sales_order.ship_method = NetSuite::Records::RecordRef.new(internal_id: shipping_id)
    # end

    # def shipping_id
    #   77 # TODO: should be resolved on a shipping mapping
    # end

    # def internal_id_for(type)
    #   non_inventory_item_service.find_or_create_by_name("Spree #{type.capitalize}").internal_id
    # end

    # def order_already_imported?
    #   sales_order_service.find_by_external_id order_payload[:number]
    # end

    # class AlreadyRefundedSalesOrderException < Exception; end
  end
end
