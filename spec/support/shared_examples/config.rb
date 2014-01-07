shared_examples "config hash" do
  let(:config) do
    { 'netsuite.api_version' => '2013_2',
      'netsuite.wsdl_url' => 'https://webservices.na1.netsuite.com/wsdl/v2013_2_0/netsuite.wsdl',
      'netsuite.sandbox' => true,
      'netsuite.email' => 'washington@spreecommerce.com',
      'netsuite.password' => 'test',
      'netsuite.account' => 'test',
      'netsuite.role_id' => 3 }.with_indifferent_access
  end
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
      {:name => "netsuite.role_id", :value => "3" }
    ]
  end
end
