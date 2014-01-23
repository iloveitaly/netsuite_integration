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
  end
end
