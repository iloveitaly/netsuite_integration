require 'spec_helper'

module NetsuiteIntegration
  module Services
    describe CustomerDeposit do
      include_examples "config hash"

      subject { described_class.new config }

      it "creates customer deposit give sales order id" do
        VCR.use_cassette("customer_deposit/add") do
          expect(subject.create(7279)).to be_true
        end
      end
    end
  end
end
