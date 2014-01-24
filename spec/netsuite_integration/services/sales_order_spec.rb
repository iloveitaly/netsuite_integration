require 'spec_helper'

module NetsuiteIntegration
  module Services
    describe SalesOrder do
      include_examples "config hash"
      include_context "connect to netsuite"

      subject { described_class.new config }

      let(:order_number) { 'R123456789' }

      it "finds sales order given order number" do
        VCR.use_cassette("order/find_by_external_id") do
          sales_order = subject.find_by_external_id(order_number)
          expect(sales_order.internal_id).to eq "7279"
        end
      end
    end
  end
end
