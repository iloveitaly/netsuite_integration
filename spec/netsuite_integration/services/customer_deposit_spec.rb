require 'spec_helper'

module NetsuiteIntegration
  module Services
    describe CustomerDeposit do
      include_examples "config hash"

      subject { described_class.new config }

      let(:sales_order) { double("SalesOrder", internal_id: 7279) }
      let(:total) { 20 }

      it "creates customer deposit give sales order id" do
        VCR.use_cassette("customer_deposit/add") do
          expect(subject.create sales_order, total).to be_true
        end
      end
    end
  end
end
