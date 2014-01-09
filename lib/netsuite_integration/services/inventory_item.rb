module NetsuiteIntegration
  module Services
    class InventoryItem < Base
      # Make sure "Sell Downloadble Files" is enabled in your NetSuite account
      # otherwise search won't work
      def latest
        search.sort_by { |c| c.last_modified_date }
      end

      private
        def search
          NetSuite::Records::InventoryItem.search({
            basic: [
              {
                field: 'lastModifiedDate',
                operator: 'after',
                value: last_updated_after
              },
              {
                field: 'isInactive',
                value: false
              }
            ],
            preferences: {
              'page_size' => '30',
              'bodyFieldsOnly' => false
            }
          }).results
        end

        def last_updated_after
          date = DateTime.parse config.fetch('netsuite.last_updated_after')
          date.iso8601
        end
    end
  end
end
