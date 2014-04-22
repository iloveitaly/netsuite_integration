module NetsuiteIntegration
  class Shipment < Base
    attr_reader :config

    def import
      create_item_fulfillment
      create_invoice

      order
    end

    def create_invoice
      return unless order_pending_billing?

      invoice = NetSuite::Records::Invoice.new({
        tax_rate: 0,
        is_taxable: false,
        created_from: {
          internal_id: order_id
        }
      })

      invoice.add
      verify_errors(invoice)
    end

    def create_item_fulfillment
      return unless order_pending_fulfillment?

      fulfillment = NetSuite::Records::ItemFulfillment.new({
        created_from: {
          internal_id: order_id
        },
        transaction_ship_address: {
          ship_addressee: "#{address[:firstname]} #{address[:lastname]}",
          ship_addr1:     address[:address1],
          ship_addr2:     address[:address2],
          ship_zip:       address[:zipcode],
          ship_city:      address[:city],
          ship_state:     Services::StateService.by_state_name(address[:state]),
          ship_country:   Services::CountryService.by_iso_country(address[:country]),
          ship_phone:     address[:phone].gsub(/([^0-9]*)/, "")
        }
      })

      @fulfilled = fulfillment.add
      verify_errors(fulfillment)
    end

    def messages
      shipments = Services::ItemFulfillment.new(config).latest

      shipments.map do |shipment|
        {
          id: shipment.internal_id,
          order_id: shipment.created_from.external_id,
          cost: shipment.shipping_cost,
          status: shipment.ship_status[1..-1],
          shipping_method: try_shipping_method(shipment),
          tracking: shipment.package_list.packages.map(&:package_tracking_number).join(", "),
          shipped_at: shipment.tran_date,
          shipping_address: build_shipping_address(shipment.transaction_ship_address),
          items: []
        }
      end
    end

    private
    def order_pending_fulfillment?
      order.status == 'Pending Fulfillment'
    end

    def order_pending_billing?
      @fulfilled || order.status == 'Pending Billing'
    end

    def order_id
      order.internal_id
    end

    def order
      @order ||= sales_order_service.find_by_external_id(payload[:shipment][:order_number] || payload[:shipment][:order_id])
    end

    def address
      payload[:shipment][:shipping_address]
    end

    def verify_errors(object)
      unless (errors = (object.errors || []).select {|e| e.type == "ERROR"}).blank?
        text = errors.inject("") {|buf, cur| buf += cur.message}

        raise StandardError.new(text) if text.length > 0
      else
        object
      end
    end

      def build_shipping_address(address)
        if address && address.ship_attention
          firstname, lastname = address.ship_attention.split(" ")

          {
            firstname: firstname,
            lastname: lastname,
            address1: address.ship_addr1,
            address2: address.ship_addressee,
            zipcode: address.ship_zip,
            city: address.ship_city,
            state: Services::StateService.by_state_name(address.ship_state),
            country: Services::CountryService.by_iso_country(address.ship_country),
            phone: address.ship_phone
          }
        end
      end

      def try_shipping_method(shipment)
        if shipment.ship_method
          shipment.ship_method.name
        end
      rescue NoMethodError => e
        nil
      end
  end
end
