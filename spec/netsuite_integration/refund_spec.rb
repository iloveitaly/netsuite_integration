require 'spec_helper'

module NetsuiteIntegration
  describe Refund do
    include_examples "config hash"
    include_context "connect to netsuite" 

    let(:deposits) do
      [
        double("CustomerDeposit", internal_id: "18695"),
        double("CustomerDeposit", internal_id: "18787")
      ]
    end

    let(:sales_order) { double("SalesOrder", external_id: "R283752334") }
    let(:customer) { double("Customer", internal_id: "4113") }

    let(:payload) do
      {
        order: {
          email: "spree@example.com",
          payments: [
            { number: 21, payment_method: "Credit Card" },
            { number: 22, payment_method: "Credit Card" }
          ]
        },
        original: { }
      }
    end

    let(:message) do
      { payload: payload }
    end

    before(:each) do
      described_class.any_instance.stub_chain(:customer_deposit_service, find_by_sales_order: deposits)
      described_class.any_instance.stub_chain(:customer_service, find_by_external_id: customer)
      described_class.any_instance.stub_chain(:sales_order_service, close!: true)
    end

    subject { described_class.new(config, message, sales_order) }

    it 'initializes correctly' do
      expect(subject.deposits).to eq deposits
      expect(subject.sales_order).to eq sales_order
      expect(subject.customer).to eq customer
    end

    it 'issues a customer refund and close sales order' do
      subject = described_class.new(config, message, sales_order)
     
      VCR.use_cassette("customer_refund/create") do
        expect(subject.process!).to be_true
      end
    end
  end
end
