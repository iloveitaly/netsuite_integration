module NetsuiteIntegration
  class Shipment < Base
    attr_reader :config, :collection

    def import
      create_item_fulfillment! && create_invoice!
    end

    def create_invoice!
      invoice = NetSuite::Records::Invoice.new({
        created_from: {
          internal_id: order_id
        }
      })

      invoice.add
    end

    def create_item_fulfillment!
      fulfillment = NetSuite::Records::ItemFulfillment.new({
        created_from: {
          internal_id: order_id
        },
        transaction_ship_address: {
          ship_addr1:    address[:address1],
          ship_addr2:    address[:address2],
          ship_zip:      address[:zipcode],
          ship_city:     address[:city],
          ship_state:    address[:state],
          ship_country:  Services::CountryService.by_iso_country(address[:country]),
          ship_phone:    address[:phone].gsub(/([^0-9]*)/, "")
        }
      })

      fulfillment.add
    end

    private
    def  order_id
      sales_order_service.find_by_external_id(payload[:shipment][:order_number]).internal_id
    end

    def address
      payload[:shipment][:shipping_address]
    end
  end
end
