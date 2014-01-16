module NetsuiteIntegration
  class Shipment < Base
    attr_reader :config, :collection

    def test
      number = payload[:shipment][:order_number]
      @order = sales_order_service.find_by_external_id number
      binding.pry
      # do
    end
  end
end
