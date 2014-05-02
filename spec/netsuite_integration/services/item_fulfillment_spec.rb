require 'spec_helper'

module NetsuiteIntegration
  module Services
    describe ItemFulfillment do
      include_examples "config hash"
      include_context "connect to netsuite"

      subject { described_class.new config }

      before do
        config["netsuite_poll_fulfillment_timestamp"] = '2014-04-27T18:48:56.001Z'
      end

      it "returns ordered by last modified date" do
        VCR.use_cassette("item_fulfillment/latest") do
          shipments = subject.latest

          (1..(shipments.count - 1)).each do |time|
            expect(shipments[time].last_modified_date).to be >= shipments[time-1].last_modified_date
          end
        end
      end
    end
  end
end
