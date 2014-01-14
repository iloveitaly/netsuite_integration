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

      def create(payload)
        customer             = NetSuite::Records::Customer.new
        customer.email       = payload['email']
        customer.external_id = customer.entity_id = payload['id'].to_i
        customer.first_name  = payload[:firstname] || 'N/A'
        customer.last_name   = payload[:lastname] || 'N/A'

        fill_address(customer, payload)

        # Defaults
        customer.is_person   = true
        customer.is_inactive = true

        if customer.add
          customer
        else
          false
        end
      end

      def update_attributes(customer, attrs)
        attrs.delete :id
        attrs.delete :created_at
        attrs.delete :updated_at

        # Converting string keys to symbol keys
        # Netsuite gem does not like string keys
        attrs = Hash[attrs.map{|(k,v)| [k.to_sym,v]}]

        if customer.update attrs
          customer
        else
          false
        end
      end

      def update_address(customer, payload)
        fill_address(customer, payload)

        customer.update
      end

      private
      def fill_address(customer, payload)
        if payload[:address1].present?
          customer.addressbook_list = {
            addressbook: {
              default_shipping: true,
              addr1: payload[:address1],
              addr2: payload[:address2],
              zip: payload[:zipcode],
              city: payload[:city],
              state: payload[:state],
              country: payload[:country],
              phone: payload[:phone]
            }
          }
        end
      end
    end
  end
end
