module NetsuiteIntegration
  class Order < Base
    attr_reader :config, :collection, :order_payload, :sales_order,
      :existing_sales_order

    def initialize(config, payload = {})
      super(config, payload)

      @config = config
      @order_payload = payload[:order]

      @existing_sales_order = sales_order_service.find_by_external_id(order_payload[:number] || order_payload[:id])

      if existing_sales_order
        @sales_order = NetSuite::Records::SalesOrder.new({
          internal_id: existing_sales_order.internal_id,
          external_id: existing_sales_order.external_id
        })
      else
        @sales_order = NetSuite::Records::SalesOrder.new({
          order_status: '_pendingFulfillment',
          external_id: order_payload[:number] || order_payload[:id]
        })

        # depending on your NS instance a custom form will need to be set to close the sales order
        if (custom_form_id = config['netsuite_sales_order_custom_form_id']).present?
          @sales_order.custom_form = NetSuite::Records::RecordRef.new(internal_id: custom_form_id)
        end
      end
    end

    def imported?
      @existing_sales_order
    end

    def create
      sales_order.entity = set_up_customer
      sales_order.item_list = build_item_list

      sales_order.transaction_bill_address = build_bill_address

      sales_order.shipping_cost = order_payload[:totals][:shipping]
      sales_order.transaction_ship_address = build_ship_address

      sales_order.tran_date = order_payload[:placed_on]

      if (department_id = config['netsuite_department_id']).present?
        sales_order.department = NetSuite::Records::RecordRef.new(internal_id: department_id)
      end

      handle_extra_fields

      if sales_order.add
        fresh_sales_order = sales_order_service.find_by_external_id(order_payload[:number] || order_payload[:id])
        sales_order.tran_id = fresh_sales_order.tran_id
        # need entity on sales_order for CustomerDeposit.customer
        sales_order.entity = fresh_sales_order.entity
        sales_order
      end
    end

    def update
      fields = {
        entity: set_up_customer,
        item_list: build_item_list,
        transaction_bill_address: build_bill_address,
        shipping_cost: order_payload[:totals][:shipping],
        transaction_ship_address: build_ship_address
      }

      sales_order.update fields.merge(handle_extra_fields)
    end

    def paid?
      if order_payload[:payments]
        payment_total = order_payload[:payments].sum { |p| p[:amount] }
        order_payload[:totals][:order] <= payment_total
      else
        false
      end
    end

    def errors
      if sales_order && sales_order.errors.is_a?(Array)
        self.sales_order.errors.map(&:message).join(", ")
      end
    end

    def handle_extra_fields
      if order_payload[:netsuite_order_fields] && order_payload[:netsuite_order_fields].is_a?(Hash)
        extra = {}
        order_payload[:netsuite_order_fields].each do |k, v|

          method = "#{k}=".to_sym
          ref_method = if k =~ /_id$/ || k =~ /_ref$/
                         "#{k[0..-4]}=".to_sym
                       end

          ref_method = ref_method == :class= ? :klass= : ref_method

          if sales_order.respond_to? method
            extra[k.to_sym] = sales_order.send method, v
          elsif ref_method && sales_order.respond_to?(ref_method)
            extra[k[0..-4].to_sym] = sales_order.send ref_method, NetSuite::Records::RecordRef.new(internal_id: v)
          end
        end

        extra
      end || {}
    end

    def set_up_customer
      if customer = customer_service.find_by_external_id(order_payload[:email])
        if !customer_service.address_exists? customer, order_payload[:shipping_address]
          customer_service.set_or_create_default_address customer, order_payload[:shipping_address]
        end
      else
        customer = customer_service.create(order_payload.dup)
      end

      unless customer
        message = if customer_service.customer_instance && customer_service.customer_instance.errors.is_a?(Array)
          customer_service.customer_instance.errors.map(&:message).join(", ")
        end

        raise CreationFailCustomerException, message
      end

      NetSuite::Records::RecordRef.new(external_id: customer.external_id)
    end

    def internal_id_for(type)
      name = @config.fetch("netsuite_item_for_#{type.pluralize}", "Store #{type.capitalize}")
      if item = non_inventory_item_service.find_or_create_by_name(name, order_payload[:netsuite_non_inventory_fields])
        item.internal_id
      else
        raise NonInventoryItemException, "Couldn't create item #{name}: #{non_inventory_item_service.error_messages}"
      end
    end

    private
    def build_item_list
      sales_order_items = order_payload[:line_items].map do |item|

        reference = item[:sku] || item[:product_id]
        unless inventory_item = inventory_item_service.find_by_item_id(reference)
          raise NetSuite::RecordNotFound, "Inventory Item \"#{reference}\" not found in NetSuite"
        end

        NetSuite::Records::SalesOrderItem.new({
          item: { internal_id: inventory_item.internal_id },
          quantity: item[:quantity],
          amount: item[:quantity] * item[:price],
          # Force tax rate to 0. NetSuite might create taxes rates automatically which
          # will cause the sales order total to differ from the order in the Spree store
          tax_rate1: 0
        })
      end

      # Due to NetSuite complexity, taxes and discounts will be treated as line items.
      ["tax", "discount"].map do |type|
        value = order_payload[:adjustments].sum do |hash|
          if hash[:name].to_s.downcase == type.downcase
            hash[:value]
          else
            0
          end
        end

        if value != 0
          sales_order_items.push(NetSuite::Records::SalesOrderItem.new({
            item: { internal_id: internal_id_for(type) },
            rate: value
          }))
        end
      end

      NetSuite::Records::SalesOrderItemList.new(item: sales_order_items)
    end

    def build_bill_address
      if payload = order_payload[:billing_address]
        NetSuite::Records::BillAddress.new({
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

    def build_ship_address
      if payload = order_payload[:shipping_address]
        NetSuite::Records::ShipAddress.new({
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
    end
  end
end
