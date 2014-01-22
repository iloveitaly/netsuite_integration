config_hash = {
  'netsuite.api_version' => '2013_2',
  'netsuite.wsdl_url' => 'https://webservices.na1.netsuite.com/wsdl/v2013_2_0/netsuite.wsdl',
  'netsuite.sandbox' => true,
  'netsuite.email' => 'washington@spreecommerce.com',
  'netsuite.password' => 'test',
  'netsuite.account' => 'test',
  'netsuite.last_updated_after' => '2012-01-08T18:48:56.001Z',
  'netsuite.role_id' => 3,
  'netsuite.shipping_methods_mapping' => [{
    "UPS Ground (USD)"=>"92",
    "UPS Two Day (USD)"=>"91",
    "UPS One Day (USD)"=>"77",
    "UPS"=>"77"
  }]
}.with_indifferent_access

shared_examples "config hash" do
  let(:config) { config_hash }
end

shared_context "request parameters" do
  let(:parameters) do
    [
      {:name => 'netsuite.api_version', :value => "2013_2" },
      {:name => 'netsuite.wsdl_url', :value => "https://webservices.na1.netsuite.com/wsdl/v2013_2_0/netsuite.wsdl" },
      {:name => 'netsuite.sandbox', :value => "true" },
      {:name => "netsuite.email", :value => "washington@spreecommerce.com" },
      {:name => "netsuite.password", :value => "test" },
      {:name => "netsuite.account", :value => "test" },
      {:name => "netsuite.last_updated_after", :value => "2013-01-08T18:48:56.001Z" },
      {:name => "netsuite.role_id", :value => "3" },
      {:name => "netsuite.shipping_methods_mapping", :value => [{ "UPS" => "77", "UPS Ground (USD)"=>"92", "UPS Two Day (USD)"=>"91", "UPS One Day (USD)"=>"77" }]
      }
    ]
  end
end

shared_context "connect to netsuite" do
  before(:all) do
    NetSuite.configure do
      reset!
      api_version config_hash.fetch('netsuite.api_version')
      wsdl        config_hash.fetch('netsuite.wsdl_url')
      sandbox     config_hash.fetch('netsuite.sandbox')
      email       config_hash.fetch('netsuite.email')
      password    config_hash.fetch('netsuite.password')
      account     config_hash.fetch('netsuite.account')
      role        config_hash.fetch('netsuite.role_id')
      log_level   :debug
    end
  end
end
