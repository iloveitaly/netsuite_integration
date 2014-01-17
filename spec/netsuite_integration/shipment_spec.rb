require 'spec_helper'

module NetsuiteIntegration
  describe Shipment do
    include_examples 'config hash'

    subject do
      described_class.new({ payload: Factories.shipment_confirm_payload }, config)
    end

    context 'when successful' do
      it 'returns the fullfillment object' do
        VCR.use_cassette("shipment/create_fulfillment") do
          fulfillment = subject.create_item_fulfillment!

          expect(fulfillment.created_from.internal_id).to eq("7281")
          expect(fulfillment.transaction_ship_address.ship_addr1).to eq("7735 Old Georgetown Rd")
        end
      end
    end

    context 'when unsuccessful' do
      it 'returns the fullfillment object' do
        VCR.use_cassette("shipment/create_fulfillment_error") do
          fulfillment = subject.create_item_fulfillment!

          expect(fulfillment).to be_nil
        end
      end
    end
  end
end
