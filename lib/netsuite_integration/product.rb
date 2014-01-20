module NetsuiteIntegration
  class Product
    attr_reader :config, :collection

    def initialize(config)
      @config = config
      @collection = Services::InventoryItem.new(@config).latest
    end

    def messages
      collection.map do |item|
        {
          product: {
            name: item.store_display_name || item.item_id,
            available_on: item.last_modified_date.utc,
            description: item.store_description,
            sku: item.internal_id,
            price: item.cost,
            cost_price: item.cost,
            channel: "NetSuite"
          }
        }
      end
    end

    def last_modified_date
      collection.last.last_modified_date.utc
    end
  end
end
