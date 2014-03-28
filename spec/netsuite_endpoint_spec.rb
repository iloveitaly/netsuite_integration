require 'spec_helper'

describe NetsuiteEndpoint do
  include_examples 'request parameters'

  let(:request) do
    {
      message: 'product:poll',
      message_id: 123,
      payload: {
        parameters: parameters
      }
    }
  end

  context "inventory stock service" do
    let(:request) do
      {
        message: 'stock:query',
        message_id: 123,
        payload: {
          sku: "1100",
          parameters: parameters
        }
      }
    end

    it "gets quantity available of an item" do
      VCR.use_cassette("inventory_item/find_by_sku") do
        post '/inventory_stock', request.to_json, auth
        expect(last_response).to be_ok
      end
    end

    context "item not found" do
      before { request[:payload][:sku] = "Im not there" }

      it "still returns 200 but give no stock:actual message" do
        VCR.use_cassette("inventory_item/item_not_found") do
          post '/inventory_stock', request.to_json, auth
          expect(last_response).to be_ok
          expect(json_response["messages"]).to be_blank
        end
      end
    end

    context 'unhandled error' do
      it 'returns 500 and a notification' do
        NetsuiteIntegration::InventoryStock.should_receive(:new).and_raise 'Weird error'

        post '/inventory_stock', request.to_json, auth
        expect(last_response.status).to eq 500

        expect(json_response['notifications'][0]['level']).to eq("error")
        expect(json_response['notifications'][0]['subject']).to eq("Weird error")
      end
    end
  end

  it "fetches a collection of netsuite items as products" do
    NetsuiteIntegration::Services::InventoryItem.any_instance.stub(time_now: Time.parse("2014-02-12 00:48:43 -0000"))

    VCR.use_cassette("inventory_item/search_on_matrix") do
      post '/products', request.to_json, auth
      expect(last_response).to be_ok
    end
  end

  context 'Product returns an empty collection' do
    before { NetsuiteIntegration::Product.stub_chain(:new, collection: []) }

    it 'returns notification telling its ok' do
      post '/products', request.to_json, auth
      expect(last_response).to be_ok
    end
  end

  describe '/orders' do
    context 'when order is new' do
      let(:request) do
        payload = Factories.order_new_payload
        payload['order']['number'] = "RXXXXXC23774"

        {
          message: 'order:new',
          message_id: 123,
          payload: payload.merge(parameters: parameters)
        }
      end

      it 'imports the order and returns an info notification' do
        VCR.use_cassette('order/import_service') do
          post '/orders', request.to_json, auth
          expect(last_response).to be_ok
        end

        expect(json_response['notifications'][0]['subject']).to match('sent to NetSuite')
      end
    end

    context 'when order has already been imported' do
      let(:request) do
        {
          message: 'order:new',
          message_id: 123,
          payload: Factories.order_updated_payload.merge(parameters: parameters)
        }
      end

      it 'creates customer deposit' do
        request[:payload][:order][:number] = "RXXXXXC23774"

        VCR.use_cassette('order/customer_deposit_on_updated_message') do
          post '/orders', request.to_json, auth
        end

        notifications = json_response['notifications']
        expect(notifications.last['subject']).to match('Customer Deposit set up for')
      end

      context "order has invalid items" do
        before do
          request[:payload] = Factories.order_invalid_payload.merge(parameters: parameters)
        end

        it "displays netsuite record error messages" do
          VCR.use_cassette('order/invalid_item') do
            post '/orders', request.to_json, auth
            expect(last_response.status).to eq 500

            notification = json_response['notifications'][0]
            expect(notification['description']).to match('Please choose a child matrix item')
          end
        end

        it "displays friendly messages when item is not found in netsuite" do
          payload = Factories.order_new_payload.with_indifferent_access
          payload[:order][:number] = "R24252RGRERGER"
          payload[:order][:line_items].first[:sku] = "Dude I'm so not there at all"
          request[:payload] = payload.merge(parameters: parameters)

          VCR.use_cassette('order/item_not_found') do
            post '/orders', request.to_json, auth
            expect(last_response.status).to eq 500

            notification = json_response['notifications'][0]
            expect(notification['description']).to match("Dude I'm so not there at all\" not found in NetSuite")
          end
        end
      end

      context "was already paid" do
        let(:request) do
          {
            message: 'order:updated',
            message_id: 123,
            payload: Factories.order_updated_items_payload.merge(parameters: parameters)
          }
        end

        it "updates sales order" do
          VCR.use_cassette('order/update_items') do
            post '/orders', request.to_json, auth
          end

          expect(last_response.status).to eq 200
          notifications = json_response['notifications']

          # Ensure customer deposit notification are not present
          expect(notifications.count).to eq 1
          expect(notifications.first['description']).to match("updated on NetSuite")
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
        payload = Factories.order_canceled_payload

        {
          message: 'order:canceled',
          message_id: 123,
          payload: payload.merge(parameters: parameters)
        }.with_indifferent_access
      end

      context 'when CustomerDeposit record DOES NOT exist' do
        before do
          request[:payload][:order][:number] = "R780015316"
          request[:payload][:order][:payments] = []
        end

        it 'closes the order' do
          VCR.use_cassette("order/close") do
            post '/orders', request.to_json, auth
            expect(last_response).to be_ok
            expect(json_response['notifications'][0]['level']).to match('info')
            expect(json_response['notifications'][0]['subject']).to match('was closed')          
          end
        end
      end

      context 'when CustomerDeposit record exists' do
        before(:each) do
          NetsuiteIntegration::Services::SalesOrder.any_instance.stub(:find_by_external_id => sales_order)
          request['payload']['original']['payment_state'] = 'paid'
          setup_stubs
        end

        it 'issues customer refund and closes the order' do
          VCR.use_cassette('customer_refund/create') do
            post '/orders', request.to_json, auth
          end
          expect(last_response).to be_ok
          expect(json_response['notifications'][0]['level']).to match('info')
          expect(json_response['notifications'][0]['subject']).to match('Customer Refund created and NetSuite Sales Order')
        end

        def setup_stubs
          NetsuiteIntegration::Refund.any_instance.stub_chain(:customer_deposit_service, find_by_sales_order: [customer_deposit])
          NetsuiteIntegration::Refund.any_instance.stub_chain(:customer_service, find_by_external_id: customer)
          NetsuiteIntegration::Refund.any_instance.stub_chain(:sales_order_service, close!: true)
        end

        it "really issues a customer refund and closes order by reaching NetSuite api"
      end
    end
  end
end
