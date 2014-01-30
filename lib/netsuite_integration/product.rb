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
            description: item.sales_description,
            sku: item.upc_code,
            price: get_item_base_price(item.pricing_matrix.prices),
            cost_price: item.cost_estimate,
            channel: "NetSuite"
          }
        }
      end
    end

    def last_modified_date
      collection.last.last_modified_date.utc
    end

    private
      # Crazy NetSuite pricing matrix structure
      #   
      #   #<NetSuite::Records::RecordRef:0x007fdb3f1399e0 @internal_id=nil, @external_id=nil, @type=nil,
      #     @attributes={:currency=>{:name=>"USA", :@internal_id=>"1"},
      #         :price_level=>{:name=>"Base Price", :@internal_id=>"1"},
      #         :price_list=>{:price=>{:value=>"9.99", :quantity=>"0.0"}}}>,
      #   #<NetSuite::Records::RecordRef:0x007fdb3f1399b8 @internal_id=nil, @external_id=nil, @type=nil,
      #     @attributes={:currency=>{:name=>"USA", :@internal_id=>"1"},
      #         :price_level=>{:name=>"Online Wholesale Price", :@internal_id=>"6"}, :discount=>"-15.0",
      #         :price_list=>{:price=>{:value=>"8.49", :quantity=>"0.0"}}}>,
      #
      #     ...
      #
      # It can also hold more than one price in the price_list:
      #
      #   #<NetSuite::Records::RecordRef:0x007fdb3f0dbae8 @internal_id=nil, @external_id=nil, @type=nil,
      #     @attributes={:currency=>{:name=>"Euro", :@internal_id=>"4"},
      #       :price_level=>{:name=>"Base Price", :@internal_id=>"1"},
      #       :price_list=>{:price=>[
      #         {:value=>"89.0", :quantity=>"0.0"},
      #         {:value=>"84.0", :quantity=>"10.0"},
      #         {:value=>"79.0", :quantity=>"100.0"}]}}>
      #
      def get_item_base_price(prices)
        if prices.first && prices.first.attributes[:price_list]
          case price = prices.first.attributes[:price_list][:price]
          when Array
            price.first[:value]
          when Hash
            price[:value]
          end
        end
      end
  end
end
