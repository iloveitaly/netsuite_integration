module NetsuiteIntegration
  class Base
    def initialize(config)
      NetSuite.configure do
        reset!
        api_version config.fetch('api_version')
        wsdl config.fetch('wsql_url')
        sandbox config.fetch('sandbox')
        email config.fetch('email')
        password config.fetch('password')
        account config.fetch('account')
        role config.fetch('role_id')
      end
    end
  end
end
