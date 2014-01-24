module NetsuiteIntegration
  class Shipment < Base
    attr_reader :config, :collection

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
      @order ||= sales_order_service.find_by_external_id(payload[:shipment][:order_number])
    end

    def address
      payload[:shipment][:shipping_address]
    end

    def verify_errors(object)
      if errors = (object.errors || []).select {|e| e.type == "ERROR"}
        text = errors.inject("") {|buf, cur| buf += cur.message}

        raise Exception.new(text) if text.length > 0
      end
    end
  end
end
