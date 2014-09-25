require 'spec_helper'

module NetsuiteIntegration
  describe Shipment do
    include_examples 'config hash'
    include_examples 'connect to netsuite'

    let(:shipment) { Factories.shipment_confirm_payload }

    subject do
      described_class.new(config, Factories.shipment_confirm_payload)
    end

    context 'when successful' do
      it 'returns the fulfilled order' do
        shipment = Factories.shipment_fulfillment_payload
        subject = described_class.new(config, Factories.shipment_fulfillment_payload)

        VCR.use_cassette("shipment/#{shipment[:shipment][:id]}") do
          fulfilled_order = subject.import
          fulfilled_order.external_id.should eq shipment[:shipment][:order_id]
        end
      end
    end

    context 'when order has already been fulfilled' do
      context 'when invoice is ok' do
        xit 'creates only the invoice' do
          VCR.use_cassette("shipment/import_only_invoice") do
            fulfilled_order = subject.create_invoice

            fulfilled_order.internal_id.should eq("9593")
            fulfilled_order.external_id.should eq("R375526411")
          end
        end
      end

      context 'when invoice has errors' do
        it 'generates an error' do
          VCR.use_cassette("shipment/order_fulfilled_but_errors_on_invoice") do
            expect { subject.create_invoice }.to raise_error("Transaction is not in balance!  amounts+taxes+shipping: 194.0, total amount: 208.77")
          end
        end
      end
    end

    context "shipments polling" do
      let(:items) do
        VCR.use_cassette("item_fulfillment/latest") do
          Services::ItemFulfillment.new(config).latest
        end
      end

      before do
        config["netsuite_poll_fulfillment_timestamp"] = '2014-04-27T18:48:56.001Z'
        Services::ItemFulfillment.any_instance.stub latest: items
        NetSuite::Records::SalesOrder.stub get: double("Sales Order", external_id: 123)
      end

      it "builds out a collection of shipments from item fulfillments" do
        messages = subject.messages
        expect(messages.last[:tracking]).to_not be_empty
      end
    end

    context "extra fields" do
      subject do
        payload = Factories.shipment_confirm_payload
        payload[:shipment][:netsuite_shipment_fields] = {
          ship_method_id: 3,
          memo: "Extra memo"
        }

        payload[:shipment][:netsuite_invoice_fields] = {
          department_id: 3,
          message: "Extra message"
        }

        described_class.new(config, payload)
      end

      context "fulfillment" do
        let(:fulfillment) do
          NetSuite::Records::ItemFulfillment.new
        end

        it "handles extra attributes when creating fulfillment" do
          subject.stub order_pending_fulfillment?: true, order_id: 1

          expect(NetSuite::Records::ItemFulfillment).to receive(:new).and_return double.as_null_object
          expect(subject).to receive(:handle_extra_fields)
          subject.create_item_fulfillment
          end

          it "sets extra attributes properly" do
            subject.handle_extra_fields fulfillment, :netsuite_shipment_fields
            expect(fulfillment.memo).to eq "Extra memo"
          end

        it "sets extra attributes properly as reference" do
          subject.handle_extra_fields fulfillment, :netsuite_shipment_fields
          expect(fulfillment.ship_method.internal_id).to eq 3
        end
      end

      context "invoice" do
        let(:invoice) do
          NetSuite::Records::Invoice.new
        end

        it "handles extra attributes when creating invoice" do
          subject.stub order_pending_billing?: true, order_id: 1

          expect(NetSuite::Records::Invoice).to receive(:new).and_return double.as_null_object
          expect(subject).to receive(:handle_extra_fields)
          subject.create_invoice
        end

        it "sets extra attributes properly" do
          subject.handle_extra_fields invoice, :netsuite_invoice_fields
          expect(invoice.message).to eq "Extra message"
        end

        it "sets extra attributes properly as reference" do
          subject.handle_extra_fields invoice, :netsuite_invoice_fields
          expect(invoice.department.internal_id).to eq 3
        end
      end
    end
  end
end
