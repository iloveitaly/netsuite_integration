module NetsuiteIntegration
  module Services
    # Make sure "Sell Downloadble Files" is enabled in your NetSuite account
    # otherwise search won't work
    #
    # In order to retrieve a Matrix Item you also need to enable "Matrix Items"
    # in your Company settings
    #
    # Specify Item type because +search+ maps to NetSuite ItemSearch object
    # which will bring all kinds of items and not only inventory items
    #
    # Records need to be ordered by lastModifiedDate programatically since
    # NetSuite api doesn't allow us to do that on the request. That's the
    # reason the search lets the page size default of 1000 records. We'd better
    # catch all items at once and sort by date properly or we might end up
    # losing data
    class InventoryItem < Base
      def latest
        ignore_future.sort_by { |c| c.last_modified_date.utc }
      end

      def find_by_name(name)
        NetSuite::Records::InventoryItem.search({
          criteria: {
            basic: [{
              field: 'displayName',
              value: name,
              operator: 'contains'
            }]
          }
        }).results.first
      end

      def find_by_item_id(internal_id)
        NetSuite::Records::InventoryItem.get(internal_id)
      end

      private
        # We need to set bodyFieldsOnly false to grab the pricing matrix
        def search
          NetSuite::Records::InventoryItem.search({
            criteria: {
              basic: [
                {
                  field: 'lastModifiedDate',
                  operator: 'after',
                  value: last_updated_after
                },
                {
                  field: 'type',
                  operator: 'anyOf',
                  type: 'SearchEnumMultiSelectField',
                  value: ['_inventoryItem']
                },
                {
                  field: 'isInactive',
                  value: false
                }
              ]
            },
            preferences: {
              pageSize: 100,
              bodyFieldsOnly: false
            }
          }).results
        end

        def ignore_future
          ignore_matrix.select do |item|
            item.last_modified_date.utc <= Time.now.utc
          end
        end

        # While we dont support matrix items. Dont know yet how to bring item options
        # via api and parent products cant be imported as items because we can't create
        # sales orders with those items. See this error for example:
        # https://gist.github.com/huoxito/0a6571c47c9baecf548a#file-error-xml-L5
        #
        # Ignore it after the search because it seems to be less expensive.
        # Searching with bodyFieldsOnly takes too long
        def ignore_matrix
          search.reject { |item| ["_parent", "_child"].include? item.matrix_type }
        end

        def last_updated_after
          Time.parse(config.fetch('netsuite.last_updated_after')).iso8601
        end
    end
  end
end
