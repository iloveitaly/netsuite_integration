require 'spec_helper'

module NetsuiteIntegration
  module Services
    describe ItemFulfillment do
      include_examples "config hash"
      include_context "connect to netsuite"

      subject { described_class.new config }

      before do
        config["netsuite_poll_fulfillment_timestamp"] = '2014-04-13T18:48:56.001Z'
      end

      it "polls for item fullfillments" do
        VCR.use_cassette("item_fulfillment/latest") do
          subject.latest
        end
      end
    end
  end
end
