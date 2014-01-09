module NetsuiteIntegration
  module Services
    class InventoryItem < Base
      # Make sure "Sell Downloadble Files" is enabled in your NetSuite account
      # otherwise search won't work
      def latest
        NetSuite::Records::InventoryItem.search({
          basic: [
            {
              field: 'lastModifiedDate',
              operator: 'after',
              value: last_updated_after
            }
          ],
          preferences: { 'page_size' => '10' }
        }).results
      end

      private
        def last_updated_after
          date = DateTime.parse config.fetch('netsuite.last_updated_after')
          date.iso8601
        end
    end
  end
end
