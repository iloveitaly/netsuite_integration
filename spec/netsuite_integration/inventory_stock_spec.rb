require 'spec_helper'

module NetsuiteIntegration
  describe InventoryStock do
    include_examples "config hash"

    let(:message) {
      { sku: 'Test-Sameer5' }
    }

    subject do
      VCR.use_cassette("inventory_item/find_by_item_id") do
        described_class.new(config, message)
      end
    end

    it "gives a item available quantity through its locations" do
      # print subject.item.locations_list.inspect
      expect(subject.quantity_available).to eq 105
    end
  end
end
