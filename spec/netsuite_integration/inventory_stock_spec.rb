require 'spec_helper'

module NetsuiteIntegration
  describe InventoryStock do
    include_examples "config hash"
    include_examples "connect to netsuite"

    let(:message) {
      { payload: { sku: '1100' } }
    }

    subject do
      VCR.use_cassette("inventory_item/find_by_sku") do
        described_class.new(config, message)
      end
    end

    it "gives a item available quantity through its locations" do
      expect(subject.quantity_available).to be > 0
    end
  end
end
