module Spree
  describe Api::LegacyReturnAuthorizationsController, type: :controller do
    render_views

    let!(:order) { create(:shipped_order) }
    let(:product) { create(:product) }
    let(:attributes) { [:id, :reason, :amount, :state] }
    let(:resource_scoping) { { order_id: order.to_param } }

    before do
      stub_api_controller_authentication!
    end

    context "as the order owner" do
      before do
        allow_any_instance_of(Order).to receive(:user).and_return(current_api_user)
      end

      it "cannot see any legacy return authorizations" do
        spree_get :index, order_id: order.to_param, format: :json
        assert_unauthorized!
      end

      it "cannot see a single legacy return authorization" do
        spree_get :show, order_id: order.to_param, id: 1, format: :json
        assert_unauthorized!
      end

      it "cannot update a legacy return authorization" do
        spree_put :update, order_id: order.to_param, format: :json
        assert_not_found!
      end

      it "cannot delete a legacy return authorization" do
        spree_delete :destroy, order_id: order.to_param, format: :json
        assert_not_found!
      end
    end

    context "as an admin" do
      before do
        stub_api_controller_authentication!(admin: true)
      end

      it "can show legacy return authorization" do
        create(:legacy_return_authorization, order: order)
        legacy_return_authorization = order.legacy_return_authorizations.first
        spree_get :show, order_id: order.number, id: legacy_return_authorization.id, format: :json
        expect(response.status).to be(200)
        expect(json_response).to have_attributes(attributes)
        expect(json_response["state"]).not_to be_blank
      end

      it "can get a list of legacy return authorizations" do
        create(:legacy_return_authorization, order: order)
        create(:legacy_return_authorization, order: order)
        spree_get :index, order_id: order.number, format: :json
        expect(response.status).to be(200)
        legacy_return_authorizations = json_response["legacy_return_authorizations"]
        expect(legacy_return_authorizations.first).to have_attributes(attributes)
        expect(legacy_return_authorizations.first).not_to eq(legacy_return_authorizations.last)
      end

      it 'can control the page size through a parameter' do
        create(:legacy_return_authorization, order: order)
        create(:legacy_return_authorization, order: order)
        spree_get :index, order_id: order.number, per_page: 1, format: :json
        expect(json_response['count']).to be(1)
        expect(json_response['current_page']).to be(1)
        expect(json_response['pages']).to be(2)
      end

      it 'can query the results through a parameter' do
        create(:legacy_return_authorization, order: order)
        expected_result = create(:legacy_return_authorization, reason: 'damaged')
        order.legacy_return_authorizations << expected_result
        spree_get :index, q: { reason_cont: 'damage' }, order_id: order.to_param, format: :json
        expect(json_response['count']).to be(1)
        expect(json_response['legacy_return_authorizations'].first['reason']).to eq expected_result.reason
      end

      it "can update a legacy return authorization on the order" do
        create(:legacy_return_authorization, order: order)
        legacy_return_authorization = order.legacy_return_authorizations.first
        spree_put :update, id: legacy_return_authorization.id, legacy_return_authorization: { amount: 19.99 }, format: :json, order_id: order.to_param
        expect(response.status).to be(200)
        expect(json_response).to have_attributes(attributes)
      end

      it "can add an inventory unit to a legacy return authorization on the order" do
        create(:legacy_return_authorization, order: order)
        legacy_return_authorization = order.legacy_return_authorizations.first
        inventory_unit = legacy_return_authorization.returnable_inventory.first
        expect(legacy_return_authorization.inventory_units).to be_empty
        spree_put :add, id: legacy_return_authorization.id, variant_id: inventory_unit.variant.id, quantity: 1, format: :json, order_id: order.to_param
        expect(response.status).to be(200)
        expect(json_response).to have_attributes(attributes)
        expect(legacy_return_authorization.reload.inventory_units).not_to be_empty
      end

      it "can mark a legacy return authorization as received on the order with an inventory unit" do
        create(:new_legacy_return_authorization, order: order, stock_location_id: order.shipments.first.stock_location.id)
        legacy_return_authorization = order.legacy_return_authorizations.first
        expect(legacy_return_authorization.state).to eq("authorized")

        # prep (use a rspec context or a factory instead?)
        inventory_unit = legacy_return_authorization.returnable_inventory.first
        expect(legacy_return_authorization.inventory_units).to be_empty
        spree_put :add, id: legacy_return_authorization.id, variant_id: inventory_unit.variant.id, quantity: 1, format: :json, order_id: order.to_param
        # end prep

        spree_delete :receive, id: legacy_return_authorization.id, format: :json, order_id: order.to_param
        expect(response.status).to be(200)
        expect(legacy_return_authorization.reload.state).to eq("received")
      end

      it "cannot mark a legacy return authorization as received on the order with no inventory units" do
        create(:new_legacy_return_authorization, order: order)
        legacy_return_authorization = order.legacy_return_authorizations.first
        expect(legacy_return_authorization.state).to eq("authorized")
        spree_delete :receive, id: legacy_return_authorization.id, format: :json, order_id: order.to_param
        expect(response.status).to be(422)
        expect(legacy_return_authorization.reload.state).to eq("authorized")
      end

      it "can cancel a legacy return authorization on the order" do
        create(:new_legacy_return_authorization, order: order)
        legacy_return_authorization = order.legacy_return_authorizations.first
        expect(legacy_return_authorization.state).to eq("authorized")
        spree_delete :cancel, id: legacy_return_authorization.id, format: :json, order_id: order.to_param
        expect(response.status).to be(200)
        expect(legacy_return_authorization.reload.state).to eq("canceled")
      end

      it "can delete a legacy return authorization on the order" do
        create(:legacy_return_authorization, order: order)
        legacy_return_authorization = order.legacy_return_authorizations.first
        spree_delete :destroy, id: legacy_return_authorization.id, format: :json, order_id: order.to_param
        expect(response.status).to be(204)
        expect { legacy_return_authorization.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "as just another user" do
      it "cannot update a legacy return authorization on the order" do
        create(:legacy_return_authorization, order: order)
        legacy_return_authorization = order.legacy_return_authorizations.first
        spree_put :update, id: legacy_return_authorization.id, legacy_return_authorization: { amount: 19.99 }, format: :json, order_id: order.to_param
        assert_unauthorized!
        expect(legacy_return_authorization.reload.amount).not_to eq(19.99)
      end

      it "cannot delete a legacy return authorization on the order" do
        create(:legacy_return_authorization, order: order)
        legacy_return_authorization = order.legacy_return_authorizations.first
        spree_delete :destroy, id: legacy_return_authorization.id, format: :json, order_id: order.to_param
        assert_unauthorized!
        expect { legacy_return_authorization.reload }.not_to raise_error
      end
    end
  end
end
