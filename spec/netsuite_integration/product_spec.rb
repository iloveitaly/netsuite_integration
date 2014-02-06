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
      VCR.use_cassette("product/building_matrix") do
        expect(subject.matrix_items.count).to eq subject.matrix_parents.count
      end
    end

    it "check" do
      VCR.use_cassette("product/huhuuhuh") do
        s = described_class.new config
        s.messages
        # expect(s.matrix_items.count).to eq s.matrix_parents.count
      end
    end

    context "collection with one child but no parents" do
      before do
        config['netsuite.last_updated_after'] = '2014-02-06T19:58:56.001Z'
      end

      it "finds parent and still build matrix properly" do
        VCR.use_cassette("product/one_child_on_response") do
          subject = described_class.new config
          expect(subject.messages.count).to eq 1
          expect(subject.matrix_parents).to_not be_empty
        end
      end
    end

    it "builds messages with both standalone and matrix items" do
      VCR.use_cassette("product/building_matrix") do
        expect(subject.messages).to eq (subject.standalone_products + subject.matrix_items)
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
