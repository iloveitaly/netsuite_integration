class InventoryItem < NetsuiteIntegration::Base
  # Make sure "Sell Downloadble Files" is enabled in your NetSuite account
  # otherwise search won't work
  def latest
    NetSuite::Records::InventoryItem.search({
      basic: [
        {
          field: 'lastModifiedDate',
          operator: 'after',
          value: 10.days.ago.iso8601
        }
      ]
    })
  end
end
