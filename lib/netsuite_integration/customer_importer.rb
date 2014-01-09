module NetsuiteIntegration 
  class CustomerImporter < Base
    attr_accessor :user

    def initialize(message = {}, config)
      super
      @user = payload['user']
    end

    def sync!
      if customer = customer_service.find_by_external_id(external_id)
        case message_name
        when "user:new"
          raise AlreadyPersistedCustomerException,
            "Got 'user:new' message with user id: #{user[:id]} that already exists in NetSuite with id: #{customer.internal_id}"
        when "user:updated"
          if customer_service.update_attributes(customer, user)
            text = "Successfully updated the user in NetSuite with id: #{customer.internal_id}"
            [200, notification(text)]
          else
            raise UpdateFailCustomerException,
              "Failed to update the user with id: #{customer.internal_id}"
          end
        end
      else
        if customer_service.create(user)
          text = "Successfully created the user in NetSuite"
          [200, notification(text)]
        else
          raise CreationFailCustomerException,
            "Failed to create the user"
        end
      end
    end

    private 
    def notification(text)
      { 'message_id' => message_id,
        'notifications' => [
          {
            'level' => 'info',
            'subject' => text,
            'description' => text
          }
        ]
      }.with_indifferent_access
    end

    def external_id
      user[:id]
    end
  end
end