config_hash = {
  'netsuite_api_version' => '2013_2',
  'netsuite_sandbox' => false,
  'netsuite_wsdl_url' => 'https://webservices.na1.netsuite.com/wsdl/v2013_2_0/netsuite.wsdl',
  'netsuite_email' => ENV['NETSUITE_EMAIL'],
  'netsuite_password' => ENV['NETSUITE_PASSWORD'],
  'netsuite_account' => ENV['NETSUITE_ACCOUNT'],
  'netsuite_last_updated_after' => '2014-04-13T18:48:56.001Z',
  'netsuite_poll_stock_timestamp' => '2014-04-13T18:48:56.001Z',
  'netsuite_account_for_sales_id' => 2,
  'netsuite_shipping_methods_mapping' => [{
    "UPS Ground (USD)"=>"92",
    "UPS Two Day (USD)"=>"91",
    "UPS One Day (USD)"=>"77",
    "UPS"=>"77"
  }],
  'netsuite_payment_methods_mapping' => [{
    "Credit Card" => "5",
    "Cash" => "1"
  }]  
}.with_indifferent_access

shared_examples "config hash" do
  let(:config) { config_hash }
end

shared_context "request parameters" do
  let(:parameters) { config_hash }
end

shared_context "connect to netsuite" do
  before(:all) do
    NetSuite.configure do
      reset!
      api_version config_hash.fetch('netsuite_api_version')

      if config_hash['netsuite_wsdl_url'].present?
        wsdl        config_hash.fetch('netsuite_wsdl_url')
      end

      sandbox     config_hash.fetch('netsuite_sandbox')
      email       config_hash.fetch('netsuite_email')
      password    config_hash.fetch('netsuite_password')
      account     config_hash.fetch('netsuite_account')
      log_level   :info
    end
  end
end
