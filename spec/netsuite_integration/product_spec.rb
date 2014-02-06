require 'spec_helper'

module NetsuiteIntegration
  describe Product do
    include_examples "config hash"
    include_examples "connect to netsuite"

    subject do
      VCR.use_cassette("inventory_item/search") do
        described_class.new config
      end
    end

    it "builds product variants from matrix items" do
      VCR.use_cassette("product/matrix_mapping") do
        parent = subject.matrix_parents.first
        children = subject.matrix_children_mapping_for parent
      end
    end

    it "maps parameteres according to current product schema" do
      mapped_product = subject.messages.first[:product]
      item = subject.collection.first

      expect(mapped_product[:name]).to eq (item.store_display_name || item.item_id)
      expect(mapped_product[:sku]).to eq item.upc_code
    end

    it "gives back last modified in utc" do
      expect(subject.last_modified_date).to be_utc
    end

    context "pricing matrix doesn't have a price_list" do
      before { config["netsuite.last_updated_after"] = "2014-01-28T20:56:11+00:00" }

      it "doesn't break at all" do
        VCR.use_cassette("inventory_item/missing_price_list") do
          s = described_class.new config
          expect {
            s.messages
          }.not_to raise_error
        end
      end
    end
  end
end
