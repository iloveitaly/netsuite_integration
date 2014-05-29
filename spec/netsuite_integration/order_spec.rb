require 'spec_helper'

module NetsuiteIntegration
  describe Order do
    include_examples 'config hash'
    include_examples 'connect to netsuite'

    subject do
      described_class.new(config, Factories.order_new_payload)
    end

    context 'order was paid' do
      before do
        described_class.any_instance.stub_chain :sales_order_service, :find_by_external_id
      end

      it "says so" do
        expect(subject.paid?).to be
      end
    end

    context 'when order is new' do
      let(:order_number) { 'RREGR4354EGWREERGRG' }

      before do
        described_class.any_instance.stub_chain(
          :sales_order_service, :find_by_external_id
        ).and_return(nil, double("SalesOrder", tran_id: 1, entity: "Entity"))
      end

      subject do
        payload = Factories.order_new_payload
        payload['order']['number'] = order_number

        described_class.new(config, payload)
      end

      it 'imports the order' do
        VCR.use_cassette('order/import') do
          order = subject.create

          expect(order).to be
          expect(order.external_id).to eq(order_number)
          expect(order.order_status).to eq('_pendingFulfillment')

          # 3 products
          expect(order.item_list.items.count).to eq(3)

          # products
          expect(order.item_list.items[0].amount).to eq(35.0)
          expect(order.item_list.items[1].amount).to eq(30.0)
          expect(order.item_list.items[2].amount).to eq(65.0)

          # shipping costs, address
          expect(order.shipping_cost).to eq(5)
          expect(order.transaction_ship_address.ship_addressee).to eq('Luis Shipping Braga')

          # billing address
          expect(order.transaction_bill_address.bill_addressee).to eq('Luis Billing Braga')
        end
      end

      it "set items decimal values properly" do
        VCR.use_cassette('order/import_check_decimals') do
          payload = Factories.order_new_payload
          payload[:order][:number] = "RGGADSFSFSFSFDS"
          payload[:order][:adjustments].push({ name: 'Tax', value: 3.25 })

          order = described_class.new(config, payload)

          expect(order.create).to be
          # we really only care about item decimals here
          expect(order.sales_order.item_list.items[3].rate).to eq(3.25)
        end
      end
    end

    context "extra attributes" do
      subject do
        payload = Factories.order_new_payload
        payload[:order][:netsuite_order_fields] = { department_id: 1, message: "hey you!", class_id: 1 }

        described_class.any_instance.stub_chain :sales_order_service, find_by_external_id: nil
        described_class.new(config, payload)
      end

      it "handles extra attributes on create" do
        expect(subject).to receive :set_up_customer
        expect(subject).to receive :build_item_list

        expect(subject).to receive :handle_extra_fields

        expect(subject.sales_order).to receive :add
        subject.create
      end

      it "handles extra attributes on update" do
        expect(subject).to receive :set_up_customer
        expect(subject).to receive :build_item_list

        expected = hash_including(department: instance_of(NetSuite::Records::RecordRef), message: "hey you!")
        expect(subject.sales_order).to receive(:update).with expected

        subject.update
      end

      it "calls setter on netsuite sales order record" do
        subject.handle_extra_fields
        expect(subject.sales_order.message).to eq "hey you!"
      end

      it "handles reserved class attribute properly" do
        subject.handle_extra_fields
        expect(subject.sales_order.klass.internal_id).to eq 1
      end

      it "converts them to reference when needed" do
        subject.handle_extra_fields
        expect(subject.sales_order.department.internal_id).to eq 1
      end
    end

    context "tax, discount names" do
      let(:tax) { "Tax 2345" }
      let(:discount) { "Discount 34543" }
      let(:item) { double("Item", internal_id: 1) }

      before do
        config['netsuite_item_for_taxes'] = tax
        config['netsuite_item_for_discounts'] = discount
      end

      subject do
        described_class.any_instance.stub_chain :sales_order_service, :find_by_external_id
        described_class.new(config, order: Factories.order_new_payload)
      end

      it "finds by using proper names" do
        expect(subject.non_inventory_item_service).to receive(:find_or_create_by_name).with(tax, nil).and_return item
        subject.send :internal_id_for, "tax"

        expect(subject.non_inventory_item_service).to receive(:find_or_create_by_name).with(discount, nil).and_return item
        subject.send :internal_id_for, "discount"
      end
    end

    context "account for both taxes and discounts in order[adjustments]" do
      subject do
        described_class.new(config, order: Factories.order_taxes_and_discounts_payload)
      end

      it "builds both tax and discount line" do
        NetsuiteIntegration::Services::Customer.any_instance.stub has_changed_address?: false

        VCR.use_cassette('order/taxes_and_discounts') do
          expect(subject.create).to be

          rates = subject.sales_order.item_list.items.map(&:rate)
          expect(rates).to include(-5)
          expect(rates).to include(25)
        end
      end
    end

    context "existing order" do
      let(:existing_order) do
        double("SalesOrder", internal_id: Time.now, external_id: 1.minute.ago)
      end

      # other objects, e.g. Customer Deposit depend on sales_order.external_id being set
      it "sets both internal_id and external id on new sales order object" do
        described_class.any_instance.stub_chain :sales_order_service, find_by_external_id: existing_order

        expect(subject.sales_order.external_id).to eq existing_order.external_id
        expect(subject.sales_order.internal_id).to eq existing_order.internal_id
      end

      it "updates the order along with customer address" do
        VCR.use_cassette('order/update_order_customer_address') do
          subject = described_class.new(config, order: Factories.update_order_customer_address_payload)
          expect(subject.update).to be
        end
      end
    end

    context 'netsuite instance requires Department' do
      subject do
        config['netsuite_department_id'] = 5
        described_class.new(config, { order: Factories.add_order_department_payload })
      end

      it 'still can create sales order successfully' do
        VCR.use_cassette('order/set_department') do
          expect(subject.create).to be
        end
      end
    end

    context "setting up customer" do
      subject do
        described_class.any_instance.stub_chain :sales_order_service, :find_by_external_id
        described_class.new(config, { order: Factories.add_order_department_payload })
      end

      let(:customer_instance) { double("Customer", errors: [double(message: "hey hey")]) }

      before do
        subject.stub_chain :customer_service, :find_by_external_id
        subject.stub_chain :customer_service, :create
        subject.stub_chain :customer_service, customer_instance: customer_instance
      end

      it "shows detailed error message" do
        expect {
          subject.set_up_customer
        }.to raise_error "hey hey"
      end
    end

    context "non inventory items" do
      subject do
        described_class.any_instance.stub_chain :sales_order_service, :find_by_external_id
        described_class.new(config, { order: Factories.add_order_department_payload })
      end

      before do
        subject.stub_chain :non_inventory_item_service, :find_or_create_by_name
        subject.stub_chain :non_inventory_item_service, :error_messages
      end

      it "raises if item not found or created" do
        expect {
          subject.internal_id_for "AAAAAaaaaaaaaaawwwwwwww"
        }.to raise_error NonInventoryItemException
      end
    end
  end
end
