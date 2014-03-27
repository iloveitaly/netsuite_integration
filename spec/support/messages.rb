module Factories
  class << self
    # TODO put this in a specific fixture folder and loop through each file on that dir
    [:user_new, :user_updated, :order_new, :order_updated, :order_canceled, :shipment_confirm, :order_invalid, :order_updated_items].each do |message|
      define_method("#{message}_payload") do
        JSON.parse IO.read("#{File.dirname(__FILE__)}/#{message}.json")
      end
    end
  end
end
