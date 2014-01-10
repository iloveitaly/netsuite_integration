require 'spec_helper'

module NetsuiteIntegration
  describe CustomerImporter do
    include_examples "config hash"

    let(:message) {
      {
        'store_id' => '123229227575e4645c000001',
        'message_id' => '12345',
        'payload' => Factories.user_new_payload,
        'message' => 'user:new'
      }.with_indifferent_access
    }

    it 'should initialize correctly' do
      instance = described_class.new message, config
      instance.user.should eq(message['payload']['user'])
    end

    context '#sync!' do
      subject { described_class.new message, config }

      context 'customer is found' do
        it 'when user:new -- does not create customer' do
          VCR.use_cassette("customer/customer_found") do
            expect {
              subject.sync!
            }.to raise_error(AlreadyPersistedCustomerException)
          end
        end

        it 'when user:updated -- updates the customer' do
          VCR.use_cassette("customer/customer_found_and_updated") do
            subject.stub(:message_name => 'user:updated')
            res = subject.sync!
            res[0].should eq(200)
            res[1]['notifications'][0]['subject'].should include("Successfully updated")
          end
        end
      end

      context 'customer is not found' do
        it 'creates customer' do
          subject.stub(:external_id => '12345')
          VCR.use_cassette("customer/customer_not_found_and_created") do
            res = subject.sync!

            res[0].should eq(200)
            res[1]['notifications'][0]['subject'].should include("Successfully created")
          end
        end
      end
    end
  end
end
