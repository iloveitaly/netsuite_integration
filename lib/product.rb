class Product
  attr_reader :config, :collection, :parameters

  def initialize(config)
    @config = config
    @collection = NetsuiteIntegration::InventoryItem.new(@config).latest

    @parameters = {
      parameters: [{
        name: 'netsuite.last_updated_after',
        value: collection.last.last_modified_date
      }]
    }
  end

  def payload
    messages.merge(parameters)
  end

  # item_id -> sku
  # name -> store_display_name
  # cost -> cost
  def messages
    collection.map do |item|
      {
        message: 'product:import',
        payload: {
          product: {
            name: item.store_display_name,
            available_on: Time.now,
            description: item.store_description,
            sku: item.item_id,
            external_ref: "",
            price: item.cost,
            cost_price: item.cost,
            url: ""
          }
        }
      }
    end
  end
end
