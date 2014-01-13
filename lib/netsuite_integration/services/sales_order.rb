module NetsuiteIntegration
  module Services
    class SalesOrder < Base
      def initialize(config)
        super(config)
      end

      def order
        NetSuite::Records::SalesOrder.new
      end
    end
  end
end
