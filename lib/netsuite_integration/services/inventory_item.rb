module NetsuiteIntegration
  module Services
    # Make sure "Sell Downloadble Files" is enabled in your NetSuite account
    # otherwise search won't work
    #
    # In order to retrieve a Matrix Item you also need to enable "Matrix Items"
    # in your Company settings
    #
    # Fetch record between two dates to avoid crazy future modified dates in
    # NetSuite records returned by api. e.g. Say today is Jan 8. We might see
    # products updated in Jan 31 (WTF).
    #
    # Records need to be ordered by lastModifiedDate programatically since
    # NetSuite api doesn't allow us to do that on the request. That's the
    # reason the search lets the page size default of 1000 records. We'd better
    # catch all items at once and sort by date properly or we might end up
    # losing data
    class InventoryItem < Base
      # TODO Select only items which date is after today
      # TODO Run script to update all created or modified after current Date
      def latest
        search.sort_by { |c| c.last_modified_date.utc }
      end

      private
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
                  field: 'isInactive',
                  value: false
                }
              ]
            }
            # TODO we will probably still need this to fetch matrix options
            # preferences: {
            #   'bodyFieldsOnly' => false
            # }
          }).results
        end

        def last_updated_after
          date = Time.parse config.fetch('netsuite.last_updated_after')
          date.iso8601
        end
    end
  end
end
