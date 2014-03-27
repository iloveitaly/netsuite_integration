require 'spec_helper'

module NetsuiteIntegration
  describe Services::Customer do
    include_examples "config hash"
    include_examples "connect to netsuite"

    let(:user) { Factories.user_new_payload['user'].with_indifferent_access }
    subject { described_class.new config }

    context '#find_by_external_id' do
      it 'should NOT find the record' do
        VCR.use_cassette('customer/customer_not_found_and_created') do
          subject.find_by_external_id('imnotthere@mail.com').should be_nil
        end
      end

      it 'should find the record' do
        VCR.use_cassette('customer/customer_found') do
          subject.find_by_external_id("tuesday@mail.com").should be_kind_of(NetSuite::Records::Customer)
        end
      end
    end

    context '#create' do
      it 'creates the record' do
        VCR.use_cassette('customer/create') do
          subject.create(user).should be_kind_of(NetSuite::Records::Customer)
        end
      end
    end

    context '#update_attributes' do
      it 'updates the email field' do
        VCR.use_cassette('customer/customer_found_and_updated') do
          customer = subject.find_by_external_id(user['email'])
          customer.email.should eq(user['email'])

          res = subject.update_attributes(customer, {email: 'wasss@spreecommerce.com'})
          res.should be_kind_of(NetSuite::Records::Customer)
        end
      end
    end
  end
end
