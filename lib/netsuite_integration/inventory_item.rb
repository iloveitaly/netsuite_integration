class InventoryItem < NetsuiteIntegration::Base
  # Make sure "Sell Downloadble Files" is enabled in your NetSuite account
  # otherwise search won't work
  def latest
    NetSuite::Records::InventoryItem.search({
      basic: [
        {
          field: 'lastModifiedDate',
          operator: 'after',
          value: 5.days.ago.iso8601
        }
      ],
      preferences: { 'page_size' => '10' }
    }).results
  end
end
