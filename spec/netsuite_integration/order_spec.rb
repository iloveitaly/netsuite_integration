require 'spec_helper'

module NetsuiteIntegration
  describe Order do
    include_examples "config hash"

    subject do
      described_class.new config, Factories.order_new_payload
    end

    it "has an order object" do
      # expect(subject.import).to eq([])
      expect(NetSuite::Actions::Add.call(subject.import).body).to eq([])
    end
  end
end
