require "sinatra"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/netsuite_integration')

class NetsuiteEndpoint < EndpointBase::Sinatra::Base
  post '/products' do
    products = NetsuiteIntegration::Product.new(@config)
    @messages = products.messages

    if @messages.any?
      add_parameter 'netsuite.last_updated_after', products.last_modified_date
      add_notification "info", "NetSuite Items imported as products (#{products.last_modified_date})"
    else
      add_notification "info", "No product updated since #{@config.fetch('netsuite.last_updated_after')}"
    end

    process_result 200
  end

  post '/customer_persist' do
    begin
      customer = NetsuiteIntegration::CustomerImporter.new(@message, @config)
      process_result *(customer.sync!)
    rescue Exception => e
      process_result 500, error_notification(e)
    end
  end

  private
  def error_notification(e)
    {
      'message_id' => @message_id,
      'notifications' => [
        {
          "level" => "error",
          "subject" => e.message,
          "description" => e.message,
          "backtrace" => e.backtrace.to_a.join("\n\t")
        }
      ]
    }
  end
end
