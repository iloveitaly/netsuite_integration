shared_examples "config hash" do
  let(:config) do
    { api_version: '2013_2',
      wsql_url: 'https://webservices.na1.netsuite.com/wsdl/v2013_2_0/netsuite.wsdl',
      sandbox: true,
      email: 'test@spreecommerce.com',
      password: 'test',
      account: 'test'
      role_id: 3 }.with_indifferent_access
  end
end
