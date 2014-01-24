require 'spec_helper'

module NetsuiteIntegration
  describe Shipment do
    include_examples 'config hash'
    include_examples 'connect to netsuite'

    subject do
      described_class.new({ payload: Factories.shipment_confirm_payload }, config)
    end

    context 'when successful' do
      it 'returns the fulfilled order' do
        VCR.use_cassette("shipment/import") do
          fulfilled_order = subject.import

          fulfilled_order.internal_id.should eq("9593")
          fulfilled_order.external_id.should eq("R375526411")
        end
      end
    end

    context 'when order has already been fulfilled' do
      context 'when invoice is ok' do
        xit 'creates only the invoice' do
          VCR.use_cassette("shipment/import_only_invoice") do
            fulfilled_order = subject.import

            fulfilled_order.internal_id.should eq("9593")
            fulfilled_order.external_id.should eq("R375526411")
          end
        end
      end

      context 'when invoice has errors' do
        it 'generates an error' do
          VCR.use_cassette("shipment/order_fulfilled_but_errors_on_invoice") do
            expect { subject.import }.to raise_error("Transaction is not in balance!  amounts+taxes+shipping: 194.0, total amount: 208.77")
          end
        end
      end
    end
  end
end
