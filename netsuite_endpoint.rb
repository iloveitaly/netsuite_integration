require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/netsuite_integration')

class NetsuiteEndpoint < EndpointBase::Sinatra::Base
  post '/products' do
    payload = Product.new(@config).payload
    payload.merge({ message_id: @message[:message_id] })
  end
end
