module NetsuiteIntegration
  module Services
    class Customer < Base

      def find_by_external_id(email)
        NetSuite::Records::Customer.get({:external_id => email})
      # Silence the error
      # We don't care that the record was not found
      rescue NetSuite::RecordNotFound
      end

      # entity_id -> Customer name
      def create(payload)
        customer             = NetSuite::Records::Customer.new
        customer.email       = payload[:email]
        customer.external_id = payload[:email]

        if payload[:shipping_address]
          customer.first_name  = payload[:shipping_address][:firstname] || 'N/A'
          customer.last_name   = payload[:shipping_address][:lastname] || 'N/A'
          fill_address(customer, payload[:shipping_address])
        else
          customer.first_name  = 'N/A'
          customer.last_name   = 'N/A'
        end

        # Defaults
        customer.is_person   = true
        # I don't think we need to make the customer inactive
        # customer.is_inactive = true

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

      def create_new_default_address(customer, payload)
        attrs = [{
          default_shipping: true,
          addr1: payload[:address1],
          addr2: payload[:address2],
          zip: payload[:zipcode],
          city: payload[:city],
          state: StateService.by_state_name(payload[:state]),
          country: CountryService.by_iso_country(payload[:country]),
          phone: payload[:phone].gsub(/([^0-9]*)/, "")
        }]

        addresses = attrs.push existing_addresses(customer)
        customer.update addressbook_list: { addressbook: addresses.flatten }
      end

      private
        def existing_addresses(customer)
          customer.addressbook_list.addressbooks.map do |addr|
            {
              default_shipping: false,
              addr1: addr.addr1,
              addr2: addr.addr2,
              zip: addr.zip,
              city: addr.city,
              state: addr.state,
              country: addr.country,
              phone: addr.phone
            }
          end
        end

        def fill_address(customer, payload)
          if payload[:address1].present?
            customer.addressbook_list = {
              addressbook: {
                default_shipping: true,
                addr1: payload[:address1],
                addr2: payload[:address2],
                zip: payload[:zipcode],
                city: payload[:city],
                state: StateService.by_state_name(payload[:state]),
                country: CountryService.by_iso_country(payload[:country]),
                phone: payload[:phone].gsub(/([^0-9]*)/, "")
              }
            }
          end
        end
    end
  end
end
