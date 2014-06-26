module NetsuiteIntegration
  class RecordNotFound < StandardError; end

  class InventoryStock
    attr_reader :config, :sku, :item, :items

    def initialize(config, message = {})
      @config = config
      @sku = message[:sku]

      if collection?
        @items = Services::InventoryItem.new(@config, 'netsuite_poll_stock_timestamp').latest
      else
        unless @item = Services::InventoryItem.new(@config).find_by_item_id(sku)
          raise NetSuite::RecordNotFound
        end
      end
    end

    def collection?
      !sku.present?
    end

    # An Inventory Item locations might not always be a hash with quantities
    # available. See for example:
    #
    #   <listAcct:locationsList>
    #     <listAcct:locations>
    #       <listAcct:location>Fifth Gear</listAcct:location>
    #       <listAcct:locationId internalId="1"/>
    #     </listAcct:locations>
    #   </listAcct:locationsList>
    #
    def quantity_available(item = nil)
      (item || self.item).locations_list.locations.inject(0) do |quantity, location|
        unless location.is_a? Array
          quantity += location[:quantity_available].to_i
        else
          quantity
        end
      end
    end

    def inventory_units
      @inventory_units ||= items.map do |item|
        {
          id: item.item_id,
          product_id: item.item_id,
          quantity: quantity_available(item)
        }
      end
    end

    def last_modified_date
      items.last.last_modified_date.utc + 1.second
    end
  end
end
