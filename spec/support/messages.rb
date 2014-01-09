module Factories
  class << self
    def user_new_payload
      JSON.parse IO.read("#{File.dirname(__FILE__)}/user_new.json")
    end

    def user_updated_payload
      JSON.parse IO.read("#{File.dirname(__FILE__)}/user_updated.json")
    end
  end
end