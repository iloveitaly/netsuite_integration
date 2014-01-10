require 'spec_helper'

module NetsuiteIntegration
  describe Product do
    include_examples "config hash"

    subject do
      VCR.use_cassette("inventory_item/get") do
        described_class.new config
      end
    end

    it "maps parameteres according to current product schema" do
      mapped_product = subject.messages.first[:product]
      item = subject.collection.first

      expect(mapped_product[:name]).to eq item.store_display_name
      expect(mapped_product[:sku]).to eq item.item_id
      expect(mapped_product[:price]).to eq item.cost
    end

    it "gives back last modified in utc" do
      expect(subject.last_modified_date).to be_utc
    end
  end
end
