require "sinatra"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/netsuite_integration')

class NetsuiteEndpoint < EndpointBase::Sinatra::Base
  post '/products' do
    products = Product.new(@config)
    @messages = products.messages
    add_parameter 'netsuite.last_updated_after', products.collection.last.last_modified_date
    add_notification "info", "#{@messages.count} NetSuite Items imported as products"
    process_result 200
  end
end
