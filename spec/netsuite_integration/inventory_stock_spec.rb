require 'spec_helper'

module NetsuiteIntegration
  describe InventoryStock do
    include_examples "config hash"

    let(:message) {
      { payload: { sku: '1100' } }
    }

    subject do
      VCR.use_cassette("inventory_item/find_by_item_id") do
        described_class.new(config, message)
      end
    end

    it "gives a item available quantity through its locations" do
      expect(subject.quantity_available).to eq 400
    end
  end
end
