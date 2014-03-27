require 'spec_helper'

module NetsuiteIntegration
  describe Order do
    include_examples 'config hash'
    include_examples 'connect to netsuite'

    subject do
      described_class.new(config, {
        payload: Factories.order_new_payload
      })
    end

    context 'order was paid' do
      before do
        described_class.any_instance.stub_chain :sales_order_service, :find_by_external_id
      end

      it "says so" do
        expect(subject.paid?).to be
      end
    end

    context 'when order is new' do
      let(:order_number) { 'RREGR4354EGWREERGRG' }

      before do
        described_class.any_instance.stub_chain(
          :sales_order_service, :find_by_external_id
        ).and_return(nil, double("SalesOrder", tran_id: 1))
      end

      subject do
        payload = Factories.order_new_payload
        payload['order']['number'] = order_number

        described_class.new(config, { payload: payload })
      end

      it 'imports the order' do
        VCR.use_cassette('order/import') do
          order = subject.create

          expect(order).to be
          expect(order.external_id).to eq(order_number)
          expect(order.order_status).to eq('_pendingFulfillment')

          # 3 products
          expect(order.item_list.items.count).to eq(3)

          # products
          expect(order.item_list.items[0].amount).to eq(35.0)
          expect(order.item_list.items[1].amount).to eq(30.0)
          expect(order.item_list.items[2].amount).to eq(65.0)

          # shipping costs, address
          expect(order.shipping_cost).to eq(5)
          expect(order.transaction_ship_address.ship_addressee).to eq('Luis Shipping Braga')

          # billing address
          expect(order.transaction_bill_address.bill_addressee).to eq('Luis Billing Braga')
        end
      end

      it "set items decimal values properly" do
        VCR.use_cassette('order/import_check_decimals') do
          payload = Factories.order_new_payload
          payload['order']['number'] = "RGGADSFSFSFSFDS"
          payload['order']['totals']['tax'] = 3.25
          order = described_class.new(config, { payload: payload })

          expect(order.create).to be
          # we really only care about item decimals here
          expect(order.sales_order.item_list.items[3].rate).to eq(3.25)
        end
      end
    end

    context 'when missing shipping methods' do
      subject do
        payload = Factories.order_new_payload
        payload['order']['number'] = '1234GGG'
        payload['order']['shipments'][0]['shipping_method'] = "Santa Claus"

        described_class.new(config, { payload: payload })
      end

      it 'raises an error' do
        VCR.use_cassette('order/import_no_shipping') do
          expect{subject.import}.to raise_error
        end
      end
    end
  end
end
