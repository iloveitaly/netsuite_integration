module NetsuiteIntegration
  class Base
    def initialize(config)
      NetSuite.configure do
        reset!
        api_version config.fetch('netsuite.api_version')
        wsdl config.fetch('netsuite.wsql_url')
        sandbox config.fetch('netsuite.sandbox')
        email config.fetch('netsuite.email')
        password config.fetch('netsuite.password')
        account config.fetch('netsuite.account')
        role config.fetch('netsuite.role_id')
      end
    end
  end
end
