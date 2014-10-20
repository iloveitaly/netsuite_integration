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
          user[:email] = "spree@example.com"
          user[:shipping_address] = {}
          user[:shipping_address][:firstname] = "Spree"
          user[:shipping_address][:lastname] = "Commerce"

          subject.create(user).should be_kind_of(NetSuite::Records::Customer)
        end
      end
    end

    context "handle extra fields" do
      let(:customer) { NetSuite::Records::Customer.new }

      let(:extra_fields) do
        {
          category_id: 1,
          subsidiary_id: 1,
          lead_source_id: 99995,
          partner_id: 171,
          price_level_id: 2,
          comments: "huhu!"
        }
      end

      it "handle them just fine" do
        subject.handle_extra_fields customer, extra_fields

        expect(customer.category.internal_id).to eq 1
        expect(customer.subsidiary.internal_id).to eq 1
        expect(customer.lead_source.internal_id).to eq 99995
        expect(customer.partner.internal_id).to eq 171
        expect(customer.price_level.internal_id).to eq 2
        expect(customer.comments).to eq "huhu!"
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

    context "addresses" do
      let(:address) { Factories.add_order_payload[:shipping_address] }

      it "compares them" do
        VCR.use_cassette('customer/compare_addresses') do
          customer = subject.find_by_external_id("spree@example.com")
          expect(subject.address_exists? customer, address).to eq true

          address[:city] = "Teresina"
          expect(subject.address_exists? customer, address).to eq false
        end
      end

      it "adds new address to booklist" do
        address = Factories.add_order_payload[:shipping_address]
        user[:email] = "test@spreecommerce.com"
        address[:city] = "Joao Pessoa"

        VCR.use_cassette('customer/new_default_customer_address') do
          # subject.create(user).should be_kind_of(NetSuite::Records::Customer)
          customer = subject.find_by_external_id(user[:email])
          expect(subject.set_or_create_default_address(customer, address)).to be
          updated_customer = subject.find_by_external_id(user[:email])

          count = customer.addressbook_list.addressbooks.count
          updated_count = updated_customer.addressbook_list.addressbooks.count
          expect(updated_count).to be > count
        end
      end
    end
  end
end
