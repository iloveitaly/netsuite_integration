module Factories
  class << self
    [:user_new, :user_updated, :order_new, :order_updated, :shipment_confirm].each do |message|
      define_method("#{message}_payload") do
        JSON.parse IO.read("#{File.dirname(__FILE__)}/#{message}.json")
      end
    end
  end
end
