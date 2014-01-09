module NetsuiteIntegration
  module Services
    class CustomerService < Base

      def find_by_external_id(id)
        NetSuite::Records::Customer.get({:external_id => id})
      # Silence the error
      # We don't care that the record was not found
      rescue NetSuite::RecordNotFound
      end

      # entity_id -> Customer name
      def create(user)
        customer                = NetSuite::Records::Customer.new
        customer.email          = user[:email]
        customer.external_id    = user[:id].to_i
        customer.entity_id      = 'N/A'
        customer.company_name   = 'N/A'
        customer.first_name     = 'N/A'
        customer.last_name      = 'N/A'
        # Defaults
        # customer.entity_status  = 'Customer - Closed Won'
        customer.is_person      = true
        customer.is_inactive    = true

        customer.add
      end

      def update_attributes(customer, attrs)
        attrs.delete :id
        attrs.delete :created_at
        attrs.delete :updated_at

        # Converting string keys to symbol keys
        # Netsuite gem does not like string keys
        attrs = Hash[attrs.map{|(k,v)| [k.to_sym,v]}]

        customer.update attrs
      end
    end
  end
end
