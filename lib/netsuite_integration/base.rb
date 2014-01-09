module NetsuiteIntegration
  class Base
    attr_accessor :payload, :message_name, :message_id, :config#, :original

    def initialize(message = {}, config)
      @config = config

      @payload = message[:payload]
      @original = payload[:original]
      @message_name = message[:message]
      @message_id = message[:message_id]
    end

    def customer_service
      @customer_service ||= NetsuiteIntegration::Services::CustomerService.new(@config)
    end
  end

  class AlreadyPersistedCustomerException < Exception; end
  class UpdateFailCustomerException < Exception; end
  class CreationFailCustomerException < Exception; end
end
