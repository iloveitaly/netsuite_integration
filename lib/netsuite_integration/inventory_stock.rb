module NetsuiteIntegration
  class InventoryStock
    attr_reader :config, :sku, :item

    def initialize(config, message)
      @config = config
      @sku = message[:sku]
      @item = Services::InventoryItem.new(@config).find_by_item_id sku
    end

    def quantity_available
      item.locations_list.locations.inject(0) do |quantity, location|
        quantity += location[:quantity_available].to_i
      end
    end
  end
end
