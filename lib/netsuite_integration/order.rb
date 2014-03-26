module NetsuiteIntegration
  class Order < Base
    attr_reader :config, :collection, :user_id, :order_payload, :sales_order,
      :existing_sales_order

    def initialize(config, message)
      super(message, config)

      @config = config
      @user_id = original[:user_id]
      @order_payload = payload[:order]

      @existing_sales_order = sales_order_service.find_by_external_id(order_payload[:number])

      if existing_sales_order
        @sales_order = NetSuite::Records::SalesOrder.new({
          internal_id: existing_sales_order.internal_id
        })
      else
        @sales_order = NetSuite::Records::SalesOrder.new({
          order_status: '_pendingFulfillment',
          # this is Basic Sales Order Form, allow us to close the order later if needed
          custom_form: NetSuite::Records::RecordRef.new(internal_id: 164),
          external_id: order_payload[:number]
        })
      end
    end

    def imported?
      @existing_sales_order
    end

    def create
      import_customer!
      import_products!
      import_billing!
      import_shipping!

      sales_order.tran_date = order_payload[:placed_on]

      if imported?
        sales_order.update# item_list: @item_list
      else
        if sales_order.add
          if original[:payment_state] == "paid"
            create_customer_deposit
          end

          sales_order.tran_id = sales_order_service.find_by_external_id(order_payload[:number]).tran_id
          sales_order
        end
      end
    end

    def create_customer_deposit
      order = @imported_order || sales_order
      Services::CustomerDeposit.new(config).create order, order_payload[:totals][:order], order_payload[:number]
    end

    def got_paid?
      if payload[:diff]
        payload[:diff][:payment_state] == ["balance_due", "paid"]
      end
    end

    def errors
      self.sales_order.errors.map(&:message).join(", ")
    end

    private
    def import_customer!
      if customer = customer_service.find_by_external_id(order_payload[:email])
        if customer.addressbook_list.addressbooks == []
          # update address if missing
          customer_service.update_address(customer, order_payload[:shipping_address])
        end
      else
        customer = customer_service.create(order_payload.dup)
      end

      sales_order.entity = NetSuite::Records::RecordRef.new(external_id: customer.external_id)
    end

    def import_products!
      # Force tax rate to 0. NetSuite might create taxes rates automatically which
      # will cause the sales order total to differ from the order in the Spree store
      @item_list = order_payload[:line_items].map do |item|

        unless inventory_item = inventory_item_service.find_by_item_id(item[:sku])
          raise NetSuite::RecordNotFound, "Inventory Item \"#{item[:sku]}\" not found in NetSuite"
        end

        NetSuite::Records::SalesOrderItem.new({
          item: { internal_id: inventory_item.internal_id },
          quantity: item[:quantity],
          amount: item[:quantity] * item[:price],
          tax_rate1: 0
        })
      end

      # Due to NetSuite complexity, taxes and discounts will be treated as line items.
      ["tax", "discount"].map do |type|
        value = order_payload[:totals][type] || 0

        if value > 0
          @item_list.push(NetSuite::Records::SalesOrderItem.new({
            item: { internal_id: internal_id_for(type) },
            rate: value
          }))
        end
      end

      sales_order.item_list = NetSuite::Records::SalesOrderItemList.new(item: @item_list)
    end

    def import_billing!
      if payload = @payload[:order][:billing_address]
        sales_order.transaction_bill_address = NetSuite::Records::BillAddress.new({
          bill_addressee: "#{payload[:firstname]} #{payload[:lastname]}",
          bill_addr1: payload[:address1],
          bill_addr2: payload[:address2],
          bill_zip: payload[:zipcode],
          bill_city: payload[:city],
          bill_state: Services::StateService.by_state_name(payload[:state]),
          bill_country: Services::CountryService.by_iso_country(payload[:country]),
          bill_phone: payload[:phone].gsub(/([^0-9]*)/, "")
        })
      end
    end

    def import_shipping!
      sales_order.shipping_cost = order_payload[:totals][:shipping]
      sales_order.ship_method = NetSuite::Records::RecordRef.new(internal_id: shipping_id)

      payload = @payload[:order][:shipping_address]
      sales_order.transaction_ship_address = NetSuite::Records::ShipAddress.new({
        ship_addressee: "#{payload[:firstname]} #{payload[:lastname]}",
        ship_addr1: payload[:address1],
        ship_addr2: payload[:address2],
        ship_zip: payload[:zipcode],
        ship_city: payload[:city],
        ship_state: Services::StateService.by_state_name(payload[:state]),
        ship_country: Services::CountryService.by_iso_country(payload[:country]),
        ship_phone: payload[:phone].gsub(/([^0-9]*)/, "")
      })
    end

    def shipping_id
      method = @payload[:order][:shipments][0][:shipping_method]
      @config['netsuite.shipping_methods_mapping'][0].fetch(method).to_i
    rescue
      raise "Shipping method #{method} not found in #{@config['netsuite.shipping_methods_mapping'].inspect}"
    end

    def internal_id_for(type)
      name = config.fetch('netsuite.item_for_discounts', "Spree #{type.capitalize}")
      non_inventory_item_service.find_or_create_by_name(name).internal_id
    end
  end
end
