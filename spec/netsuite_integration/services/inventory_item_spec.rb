require 'spec_helper'

module NetsuiteIntegration
  describe Services::InventoryItem do
    include_examples "config hash"

    subject { Services::InventoryItem.new config }

    let(:items) do
      VCR.use_cassette("inventory_item/get") do
        subject.latest
      end
    end

    it "ensures items are ordered by last_modified_date" do
      (1..items.count).each do |time|
        expect(items[time].last_modified_date).to be >= items[time-1].last_modified_date
      end
    end
  end
end
