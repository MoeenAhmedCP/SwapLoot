# frozen_string_literal: true

# spec/controllers/steam_accounts_controller_spec.rb

require 'rails_helper'

RSpec.describe SteamAccountsController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:valid_attributes) { FactoryBot.attributes_for(:steam_account, user: user) }
  let(:invalid_attributes) { FactoryBot.attributes_for(:steam_account, steam_id: nil, user: nil) }
  let(:steam_account) { FactoryBot.create(:steam_account, user: user) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    it 'assigns all steam accounts as @steam_accounts' do
      get :index
      expect(assigns(:steam_accounts)).to eq([steam_account])
    end
  end

  describe 'GET #new' do
    it 'assigns a new steam account as @steam_account' do
      get :new
      expect(assigns(:steam_account)).to be_a_new(SteamAccount)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new SteamAccount' do
        expect { post :create, params: { steam_account: valid_attributes } }.to change(SteamAccount, :count).by(1)
      end

      it 'redirects to the steam accounts list' do
        post :create, params: { steam_account: valid_attributes }
        expect(response).to redirect_to(steam_accounts_path)
      end
    end

    context 'with invalid params' do
      it 'does not create a new SteamAccount' do
        expect { post :create, params: { steam_account: invalid_attributes } }.to_not change(SteamAccount, :count)
      end

      it 'renders the new template' do
        post :create, params: { steam_account: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested steam account as @steam_account' do
      get :edit, params: { id: steam_account.to_param }
      expect(assigns(:steam_account)).to eq(steam_account)
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) { FactoryBot.attributes_for(:steam_account) }

      it 'updates the requested steam account' do
        put :update, params: { id: steam_account.to_param, steam_account: new_attributes }
        steam_account.reload
        expect(steam_account.steam_id).to eq(new_attributes[:steam_id].to_s)
      end

      it 'redirects to the steam accounts list' do
        put :update, params: { id: steam_account.to_param, steam_account: valid_attributes }
        expect(response).to redirect_to(steam_accounts_path)
      end
    end

    context 'with invalid params' do
      it 'does not update the requested steam account' do
        put :update, params: { id: steam_account.to_param, steam_account: invalid_attributes }
        steam_account.reload
        expect(steam_account.steam_id).to_not eq(nil)
      end

      it 'renders the edit template' do
        put :update, params: { id: steam_account.to_param, steam_account: invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end
end
