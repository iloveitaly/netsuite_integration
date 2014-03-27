require 'spec_helper'

module NetsuiteIntegration
  module Services
    describe CustomerDeposit do
      include_examples "config hash"
      include_context "connect to netsuite"

      subject { described_class.new config }

      let(:sales_order) do
        double("SalesOrder", internal_id: 11203, external_id: 'R435245452435', entity: stub(internal_id: 2507))
      end

      let(:payments) do
        [{ amount: 94.99 }]
      end

      it "creates customer deposit give sales order id" do
        VCR.use_cassette("customer_deposit/add") do
          expect(subject.create sales_order, payments).to be_true
        end
      end

      it "finds customer deposit given order id" do
        VCR.use_cassette("customer_deposit/find_by_external_id") do
          item = subject.find_by_external_id(sales_order.external_id)
          expect(item.internal_id).to eq "10498"
        end
      end      
    end
  end
end
