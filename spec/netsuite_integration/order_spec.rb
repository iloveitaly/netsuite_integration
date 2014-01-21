require 'spec_helper'

module NetsuiteIntegration
  describe Order do
    include_examples 'config hash'

    subject do
      described_class.new(config, {
        payload: Factories.order_new_payload
      })
    end

    context 'order was already imported' do
      context "and paid" do
        it "does nothing" do
          expect(subject.got_paid?).to be_false
        end
      end

      context "and then got paid" do
        subject do
          described_class.new(config, { payload: Factories.order_updated_payload })
        end

        specify { expect(subject.got_paid?).to be }
      end
    end

    context 'when order is new' do
      let(:order_number) { '432536546543656546456546' }

      subject do
        payload = Factories.order_new_payload
        payload['order']['number'] = order_number

        described_class.new(config, { payload: payload })
      end

      it 'imports the order' do
        VCR.use_cassette('order/import') do
          order = subject.import

          expect(order).to be
          expect(order.external_id).to eq(order_number)
          expect(order.order_status).to eq('_pendingFulfillment')

          # 2 products + shipping
          expect(order.item_list.items.count).to eq(3)

          # products
          expect(order.item_list.items[0].amount).to eq(288.0)
          expect(order.item_list.items[1].amount).to eq(116.94)

          # shipping should be set
          expect(order.shipping_cost).to eq(5)
        end
      end
    end
  end
end
