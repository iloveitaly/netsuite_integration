require 'spec_helper'

module NetsuiteIntegration
  describe Refund do
    include_examples "config hash"
    # TODO Figure out why it doesn't work without the line below
    include_context "connect to netsuite" 

    let(:customer_deposit) {
      VCR.use_cassette("customer_deposit/find_by_external_id") do
        Services::CustomerDeposit.new(config).find_by_external_id('R123456789')
      end
    }

    let(:sales_order) {
      VCR.use_cassette("order/find_by_external_id") do
        Services::CustomerDeposit.new(config).find_by_external_id('R123456789')
      end
    }    

    let(:message) {
      {
        'store_id' => '123229227575e4645c000001',
        'message_id' => '12345',
        'payload' => Factories.order_canceled_payload,
        'message' => 'order:canceled'
      }.with_indifferent_access
    }

    context '#initialize' do
      before(:each) do
        described_class.any_instance.stub_chain(:customer_deposit_service, :find_by_external_id).and_return(customer_deposit)        
        described_class.any_instance.stub_chain(:sales_order_service, :find_by_external_id).and_return(sales_order)
      end

      it 'should initialize correctly' do
        subject = described_class.new(config, message)
        subject.user_id.should eq(message['payload']['original']['user_id'])
        subject.order_payload['number'].should eq(message['payload']['order']['number'])
        subject.customer_deposit.should eq(customer_deposit)
        subject.sales_order.should eq(sales_order)
      end
    end

    context '#process!' do
      it 'should create customer refund and close sales order'
    end
  end
end
