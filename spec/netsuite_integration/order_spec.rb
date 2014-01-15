require 'spec_helper'

module NetsuiteIntegration
  describe Order do
    include_examples "config hash"

    subject do
      described_class.new config, Factories.order_new_payload
    end

    it "imports the order" do
      VCR.use_cassette("order/import") do
        order = subject.import

        expect(order).to be
        expect(order.order_status).to eq("_pendingFulfillment")

        # 2 products + taxes + discount
        expect(order.item_list.items.count).to eq(4)

        # products
        expect(order.item_list.items[0].amount).to eq(2)
        expect(order.item_list.items[1].amount).to eq(3)

        # tax + discount
        expect(order.item_list.items[2].rate).to eq(5)
        expect(order.item_list.items[3].rate).to eq(3)

        # shipping should be set
        expect(order.shipping_cost).to eq(10)
      end
    end
  end
end
