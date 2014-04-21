require 'spec_helper'

module NetsuiteIntegration
  describe Services::InventoryItem do
    include_examples "config hash"
    include_examples "connect to netsuite"

    subject { described_class.new config }

    let(:items) do
      VCR.use_cassette("inventory_item/new_search") do
        subject.latest
      end
    end

    it "ensures items are ordered by last_modified_date" do
      expect(items.count).to be > 1

      (1..(items.count - 1)).each do |time|
        expect(items[time].last_modified_date).to be >= items[time-1].last_modified_date
      end
    end

    it "ensures all items have a present item_id" do
      items.map(&:item_id).each do |id|
        expect(id).to be_present
      end
    end

    context "user set items type to poll" do
      before do
        config["netsuite_item_types"] = "AssemblyItem; NonInventoryItem; KitItem; InventoryItem"
      end

      it "fetches those items just fine" do
        expect(subject.item_type_to_fetch).to eq ["assemblyItem", "nonInventoryItem", "kitItem", "inventoryItem"]
      end
    end

    describe "#find_by_name" do
      context "item exists" do
        it "returns the item" do
          VCR.use_cassette("inventory_item/find_by_name") do
            expect(subject.find_by_name('Spree Taxes').internal_id).to eq("1124")
          end
        end
      end

      context "item not found" do
        it "returns empty array" do
          VCR.use_cassette("inventory_item/find_by_name_not_found") do
            expect(subject.find_by_name('Cucamonga Oh Yeah!')).to be_false
          end
        end
      end
    end

    it "finds inventory item given upc code" do
      VCR.use_cassette("inventory_item/find_by_sku") do
        item = subject.find_by_item_id "Lot Tracked Medical Supplies 1"
        expect(item.item_id).to eq "Lot Tracked Medical Supplies 1"
      end
    end

    context "multiple types of matrix option lists (array and hash)" do
      it "doesn't error" do
        config['netsuite_last_updated_after'] = "2014-02-13T18:53:26+00:00"

        VCR.use_cassette("inventory_item/multiple_sizes_of_matrix_option_list") do
          subject = described_class.new config

          expect {
            subject.latest
          }.to_not raise_error
        end
      end
    end
  end
end
