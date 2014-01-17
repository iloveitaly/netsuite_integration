require 'spec_helper'

module NetsuiteIntegration
  describe Shipment do
    include_examples 'config hash'

    subject do
      described_class.new({ payload: Factories.shipment_confirm_payload }, config)
    end

    context 'when successful' do
      it 'returns true' do
        VCR.use_cassette("shipment/import") do
          subject.import.should eq(true)
        end
      end
    end
  end
end
