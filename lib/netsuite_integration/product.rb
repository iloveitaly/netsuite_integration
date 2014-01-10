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
            name: item.store_display_name,
            available_on: Time.now,
            description: item.store_description,
            sku: item.item_id,
            price: item.cost,
            cost_price: item.cost
          }
        }
      end
    end

    def last_modified_date
      collection.last.last_modified_date.utc
    end
  end
end
