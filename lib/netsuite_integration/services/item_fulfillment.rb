module NetsuiteIntegration
  module Services
    class ItemFulfillment < Base
      def latest
        NetSuite::Records::ItemFulfillment.search({
          criteria: {
            basic: [
              {
                field: 'type',
                operator: 'anyOf',
                type: 'SearchEnumMultiSelectField',
                value: ["_itemFulfillment"]
              },
              {
                field: 'lastModifiedDate',
                type: 'SearchDateField',
                operator: 'within',
                value: [
                  last_updated_after,
                  time_now.iso8601
                ]
              }
            ]
          },
          preferences: {
            pageSize: 80,
          }
        }).results
      end

      private
        def time_now
          Time.now.utc
        end

        def last_updated_after
          Time.parse(config.fetch("netsuite_poll_fulfillment_timestamp")).iso8601
        end
    end
  end
end
