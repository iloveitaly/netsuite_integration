require 'spec_helper'

describe NetsuiteEndpoint do
  include_examples 'request parameters'

  let(:request) do
    { parameters: parameters }
  end

  context "inventory stock service" do
    let(:request) do
      {
        sku: "1100",
        parameters: parameters
      }
    end

    it "gets quantity available of an item" do
      VCR.use_cassette("inventory_item/find_by_sku") do
        post '/get_inventory', request.to_json, auth
        expect(last_response).to be_ok
      end
    end

    it "gets a collection of inventory_units" do
      VCR.use_cassette("inventory_item/new_search") do
        post '/get_inventory', { parameters: parameters }.to_json, auth
        expect(last_response).to be_ok
        expect(json_response[:inventories]).to be_present
        expect(json_response[:parameters]).to have_key 'netsuite_poll_stock_timestamp'
      end
    end

    it "returns 200 on empty collection" do
      NetsuiteIntegration::InventoryStock.any_instance.stub inventory_units: []

      VCR.use_cassette("inventory_item/new_search") do
        post '/get_inventory', { parameters: parameters }.to_json, auth
        expect(last_response).to be_ok
      end
    end

    context "item not found" do
      before { request[:sku] = "Im not there" }

      it "still returns 200 but give no stock:actual message" do
        VCR.use_cassette("inventory_item/item_not_found") do
          post '/get_inventory', request.to_json, auth
          expect(last_response).to be_ok
          expect(json_response["messages"]).to be_blank
        end
      end
    end

    context 'unhandled error' do
      it 'returns 500 and a notification' do
        NetsuiteIntegration::InventoryStock.should_receive(:new).and_raise 'Weird error'

        post '/get_inventory', request.to_json, auth
        expect(last_response.status).to eq 500
        expect(json_response[:summary]).to match "Weird error"
      end
    end
  end

  it "fetches a collection of netsuite items as products" do
    NetsuiteIntegration::Services::InventoryItem.any_instance.stub(time_now: Time.parse("2014-02-12 00:48:43 -0000"))

    VCR.use_cassette("inventory_item/search_on_matrix") do
      post '/get_products', request.to_json, auth
      expect(last_response).to be_ok
    end
  end

  context 'Product returns an empty collection' do
    before { NetsuiteIntegration::Product.stub_chain(:new, collection: []) }

    it 'returns notification telling its ok' do
      post '/get_products', request.to_json, auth
      expect(last_response).to be_ok
    end
  end

  describe 'orders' do
    context 'when order is new' do
      let(:request) do
        payload = Factories.order_new_payload.merge(parameters: parameters)
        payload['order']['number'] = "RXXXXXC23774"
        payload
      end

      it 'imports the order and returns an info notification' do
        VCR.use_cassette('order/import_service') do
          post '/add_order', request.to_json, auth
          expect(last_response).to be_ok
        end

        expect(json_response[:summary]).to match('sent to NetSuite')
      end

      # Usually NetSuite returns an "confirm step" which translates as an error
      # for us when you the sales order and customer deposit totals don't match
      #
      # It should cover all keys under order[:totals]
      it "double check for payment and order totals" do
        request = { parameters: parameters }
        request.merge!(order: Factories.add_order_payload)

        NetsuiteIntegration::Services::Customer.any_instance.stub has_changed_address?: false

        VCR.use_cassette('order/totals_check') do
          post '/add_order', request.to_json, auth
          expect(last_response).to be_ok
          expect(json_response[:summary]).to match('sent to NetSuite')
        end
      end

      it "rescues customer creation failure" do
        expect(NetsuiteIntegration::Order).to receive(:new).and_raise NetsuiteIntegration::CreationFailCustomerException, "error message"

        post '/add_order', request.to_json, auth
        expect(last_response.status).to eq 500
        expect(json_response[:summary]).to match "Could not save customer"
        expect(json_response[:summary]).to match "error message"
      end
    end

    context 'when order has already been imported' do
      let(:request) do
        Factories.order_updated_payload.merge(parameters: parameters)
      end

      it 'creates customer deposit' do
        request[:order][:number] = "RXXXXXC23774"
        NetsuiteIntegration::Order.any_instance.stub set_up_customer: nil

        VCR.use_cassette('order/customer_deposit_on_updated_message') do
          post '/update_order', request.to_json, auth
        end

        expect(json_response[:summary]).to match('Customer Deposit set up for')
      end

      context "order has invalid items" do
        let(:request) do
          Factories.order_invalid_payload.merge(parameters: parameters)
        end

        it "displays netsuite record error messages" do
          pending "replay using another order with parent matrix item, no idea why it's failing"
          VCR.use_cassette('order/invalid_item') do
            post '/add_order', request.to_json, auth
            expect(last_response.status).to eq 500

            expect(json_response[:summary]).to match('Please choose a child matrix item')
          end
        end

        it "displays friendly messages when item is not found in netsuite" do
          payload = Factories.order_new_payload.with_indifferent_access
          payload[:order][:number] = "R24252RGRERGER"
          payload[:order][:line_items].first[:sku] = "Dude I'm so not there at all"
          request = payload.merge(parameters: parameters)

          VCR.use_cassette('order/item_not_found') do
            post '/add_order', request.to_json, auth
            expect(last_response.status).to eq 500

            expect(json_response[:summary]).to match("Dude I'm so not there at all\" not found in NetSuite")
          end
        end
      end

      context "was already paid" do
        let(:request) do
          Factories.order_updated_items_payload.merge(parameters: parameters)
        end

        before { NetsuiteIntegration::Order.any_instance.stub set_up_customer: nil }

        it "updates sales order" do
          VCR.use_cassette('order/update_items') do
            post '/update_order', request.to_json, auth
          end

          expect(last_response.status).to eq 200

          # Ensure customer deposit notification are not present
          expect(json_response[:summary]).to_not match /Customer Deposit/i
          expect(json_response[:summary]).to match("updated on NetSuite")
        end

        it "ignore 0 amount payments to avoid netsuite error" do
          request[:payload] = Factories.payments_amount_0_payload.merge(parameters: parameters)

          VCR.use_cassette('order/payments_amount_0') do
            post '/update_order', request.to_json, auth
            expect(last_response.status).to eq 200
          end
        end
      end
    end

    context 'when order is canceled' do
      include_examples "config hash"
      include_context "connect to netsuite"

      let(:customer_deposit) {
        VCR.use_cassette("customer_deposit/find_by_external_id") do
          NetsuiteIntegration::Services::CustomerDeposit.new(config).find_by_external_id('R123456789')
        end
      }

      let(:sales_order) {
        VCR.use_cassette("order/find_by_external_id") do
          NetsuiteIntegration::Services::SalesOrder.new(config).find_by_external_id('R123456789')
        end
      }

      let(:customer) {
        VCR.use_cassette("customer/customer_found") do
          NetsuiteIntegration::Services::CustomerDeposit.new(config).find_by_external_id('2117')
        end
      }

      let(:request) do
        Factories.order_canceled_payload.merge(parameters: parameters).with_indifferent_access
      end

      context 'when CustomerDeposit record DOES NOT exist' do
        before do
          request[:order][:number] = "R780015316"
          request[:order][:payments] = []
        end

        it 'closes the order' do
          VCR.use_cassette("order/close") do
            post '/cancel_order', request.to_json, auth
            expect(last_response).to be_ok
            expect(json_response[:summary]).to match('was closed')
          end
        end
      end

      context 'when CustomerDeposit record exists' do
        before(:each) do
          NetsuiteIntegration::Services::SalesOrder.any_instance.stub(:find_by_external_id => sales_order)
          setup_stubs
        end

        it 'issues customer refund and closes the order' do
          VCR.use_cassette('customer_refund/create') do
            post '/cancel_order', request.to_json, auth
          end
          expect(last_response).to be_ok
          expect(json_response[:summary]).to match('Customer Refund created and NetSuite Sales Order')
        end

        def setup_stubs
          NetsuiteIntegration::Refund.any_instance.stub_chain(:customer_deposit_service, find_by_sales_order: [customer_deposit])
          NetsuiteIntegration::Refund.any_instance.stub_chain(:customer_service, find_by_external_id: customer)
          NetsuiteIntegration::Refund.any_instance.stub_chain(:sales_order_service, close!: true)
        end

        it "really issues a customer refund and closes order by reaching NetSuite api"
      end
    end

    context "order updated contains payments completed and void" do
      let(:request) do
        Factories.payments_completed_and_void_payload.merge(parameters: parameters)
      end

      before { NetsuiteIntegration::Order.any_instance.stub set_up_customer: nil }

      it "issues deposit and refund for both payments respectively" do
        VCR.use_cassette('refund/payments_completed_and_void') do
          post '/update_order', request.to_json, auth
          expect(last_response).to be_ok

          expect(json_response[:summary]).to match('updated on NetSuite')
          expect(json_response[:summary]).to match('Customer Deposit set up for Sales Order')
          expect(json_response[:summary]).to match('Customer Refund created')
        end
      end
    end
  end

  context "shipments" do
    let(:request) do
      Factories.shipment_confirm_payload.merge(parameters: parameters)
    end

    context 'when successful' do
      it 'returns the fulfilled order' do
        VCR.use_cassette("shipment/import") do
          post '/add_shipment', request.to_json, auth
          expect(last_response).to be_ok
        end
      end
    end

    context 'get shipments' do
      context "shipments found" do
        include_examples 'connect to netsuite'

        let(:items) do
          VCR.use_cassette("item_fulfillment/latest") do
            NetsuiteIntegration::Services::ItemFulfillment.new(parameters).latest
          end
        end

        before do
          parameters["netsuite_poll_fulfillment_timestamp"] = '2014-04-27T18:48:56.001Z'
          NetsuiteIntegration::Services::ItemFulfillment.any_instance.stub latest: items
          NetSuite::Records::SalesOrder.stub get: double("Sales Order", external_id: 123)
        end

        it 'gives back summary with number of shipments' do
          post '/get_shipments', { parameters: parameters} .to_json, auth
          expect(last_response).to be_ok
          expect(json_response[:summary]).to match("#{items.count} shipments found in NetSuite")
        end
      end

      context "no shipment found" do
        before do
          NetsuiteIntegration::Services::ItemFulfillment.any_instance.stub latest: []
        end

        it 'just 200' do
          post '/get_shipments', { parameters: parameters} .to_json, auth
          expect(last_response).to be_ok
        end
      end
    end
  end
end
