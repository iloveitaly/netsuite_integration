require 'spec_helper'

describe NetsuiteEndpoint do
  include_examples "request parameters"

  let(:request) do
    {
      message: 'product:poll',
      message_id: 123,
      payload: {
        parameters: parameters
      }
    }
  end

  it "fetches a collection of netsuite items as products" do
    VCR.use_cassette("inventory_item/search") do
      post '/products', request.to_json, auth
      expect(last_response).to be_ok
    end
  end

  context "Product returns an empty collection" do
    before { NetsuiteIntegration::Product.stub_chain(:new, collection: []) }

    it "returns notification telling it's ok" do
      post '/products', request.to_json, auth
      expect(last_response).to be_ok
    end
  end
end
