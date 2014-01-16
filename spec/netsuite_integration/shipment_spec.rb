require 'spec_helper'

module NetsuiteIntegration
  describe Shipment do
    include_examples 'config hash'

    subject do
      described_class.new({ payload: Factories.shipment_confirm_payload }, config)
    end

    it 'does things' do
      expect(subject.test).to eq([])
    end
  end
end
