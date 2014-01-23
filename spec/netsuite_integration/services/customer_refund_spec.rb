require 'spec_helper'

module NetsuiteIntegration
  module Services
    describe CustomerRefund do
      include_examples "config hash"
      include_context "connect to netsuite"

      subject { described_class.new config }

      let(:customer_id)         { '75' }
      let(:payment_method_id)   { '1' }
      let(:customer_deposit_id) { '8079' }
      let(:order_number)        { 'R123456789' }

      it "creates customer deposit give sales order id" do
        VCR.use_cassette("customer_refund/create") do
          expect(subject.create customer_id, payment_method_id, customer_deposit_id, order_number).to be_true
        end
      end
    end
  end
end
