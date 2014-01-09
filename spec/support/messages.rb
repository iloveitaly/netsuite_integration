module Factories
  class << self
    def user_new_payload
      JSON.parse IO.read("#{File.dirname(__FILE__)}/user_new.json")
    end
  end
end