require 'spec_helper'

module NetsuiteIntegration
  module Services
    describe CustomerDeposit do
      include_examples "config hash"
      include_context "connect to netsuite"

      let(:payload) { Factories.payment_captured_payload }

      subject { described_class.new config, payload }

      let(:order_external_id) { payload[:order][:number] }

      it "creates customer deposit via sales order payments list" do
        VCR.use_cassette("customer_deposit/add") do
          sales_order = Services::SalesOrder.new(config).find_by_external_id order_external_id

          records = subject.create_records sales_order
          expect(records.map(&:errors).compact).to be_empty
        end
      end

      it "finds customer deposit given order id" do
        VCR.use_cassette("customer_deposit/find_by_external_id") do
          item = subject.find_by_external_id('R435245452435')
          expect(item.internal_id).to eq "10498"
        end
      end      
    end
  end
end
