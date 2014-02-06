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

    def matrix_children
      @matrix_children ||= collection.select { |item| item.matrix_type == "_child" }
    end

    def matrix_parents
      collection.select { |item| item.matrix_type == "_parent" }
    end

    def standalone_products
      ignore_matrix.map do |item|
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

    # Payload expected by spree_endpoint
    #
    #   product: {
    #     ...
    #     variants: [
    #       {
    #        price: 19.99,
    #        sku: "hey_you",
    #        options: [
    #          { "size" => "small" },
    #          { "color" => "black" }
    #        ]
    #       }
    #     ]
    #   }
    #
    # Need to find the parent for each matrix child
    # Once parent is found need to match child matrix_option_list type and
    # value with those present on parent
    def build_matrix
      matrix_parents.each do |item|
        {
          product: {
            name: item.store_display_name || item.item_id,
            available_on: item.last_modified_date.utc,
            description: item.sales_description,
            sku: item.upc_code,
            price: get_item_base_price(item.pricing_matrix.prices),
            cost_price: item.cost_estimate,
            channel: "NetSuite",
            variants: matrix_children_mapping_for(item)
          }
        }
      end
    end

    def matrix_children_mapping_for(parent)
      children = matrix_children.select { |item| item.parent.internal_id == parent.internal_id }

      children.map do |child|
        price = get_item_base_price(child.pricing_matrix.prices) || get_item_base_price(parent.pricing_matrix.prices)
        options = child.matrix_option_list.options.map do |option|
          { get_option_name(option.option_type_id) => get_option_value(option.value_id, parent) }
        end

        {
          price: price,
          sku: child.upc_code,
          options: options
        }
      end
    end

    def get_option_value(id, parent)
      # TODO fetch product again (fuck) so we can get the option value names 
      # then map the option value id here with the ones found on the product
      id
    end

    private
      def get_option_name(id)
        option_names[id] ||= NetSuite::Records::CustomRecordType.get(id).record_name
      end

      def option_names
        @option_names ||= {}
      end

      def ignore_matrix
        collection.reject { |item| ["_parent", "_child"].include? item.matrix_type }
      end

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
