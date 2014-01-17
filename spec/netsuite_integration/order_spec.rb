require 'spec_helper'

module NetsuiteIntegration
  describe Order do
    include_examples 'config hash'

    subject do
      described_class.new(config, {
        payload: Factories.order_new_payload
      })
    end

    context 'when order was already imported' do
      it 'raises an exception' do
        VCR.use_cassette('order/already_imported') do
          expect { subject.import }.to raise_error(Order::AlreadyImportedException)
        end
      end
    end

    context 'when order is new' do
      let(:order_number) { 'R123321' }

      subject do
        payload = Factories.order_new_payload
        payload['order']['number'] = order_number

        described_class.new(config, {
          payload: payload
        })
      end

      it 'imports the order' do
        VCR.use_cassette('order/import') do
          order = subject.import

          expect(order).to be
          expect(order.external_id).to eq(order_number)
          expect(order.order_status).to eq('_pendingFulfillment')

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
end
