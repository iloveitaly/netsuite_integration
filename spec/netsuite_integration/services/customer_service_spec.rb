require 'spec_helper'

module NetsuiteIntegration
  describe Services::CustomerService do
    include_examples "config hash"

    let(:user) { Factories.user_new_payload['user'] }
    subject { described_class.new config }

    context '#find_by_external_id' do
      it 'should NOT find the record' do
        VCR.use_cassette('customer/customer_not_found_and_created') do
          subject.find_by_external_id('12345').should be_nil
        end
      end

      it 'should find the record' do
        VCR.use_cassette('customer/customer_found') do
          subject.find_by_external_id(user['id']).should be_kind_of(NetSuite::Records::Customer)
        end
      end
    end

    context '#create' do
      it 'creates the record' do
        VCR.use_cassette('customer/customer_found_and_created') do
          subject.create(user).should be_kind_of(NetSuite::Records::Customer)
        end
      end
    end

    context '#update_attributes' do
      it 'updates the email field' do
        VCR.use_cassette('customer/customer_found_and_updated') do
          customer = subject.find_by_external_id(user['id'])
          customer.should_not be_nil
          customer.email.should eq(user['email'])

          res = subject.update_attributes(customer, {email: 'andrei12345@spreecommerce.com'})
          res.should be_kind_of(NetSuite::Records::Customer)
        end
      end
    end
  end
end
