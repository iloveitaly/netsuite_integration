require 'spec_helper'

module NetsuiteIntegration
  describe Order do
    include_examples "config hash"

    subject do
      described_class.new config, Factories.order_new_payload
    end

    it "imports the order" do
      VCR.use_cassette("order/import") do
        expect(NetSuite::Actions::Add.call(subject.import).body).to be
      end
    end
  end
end
