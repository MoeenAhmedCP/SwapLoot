# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoriesController, type: :controller do
  describe 'GET #index' do
    let(:user) { create(:user) }
    let(:steam_account) { create(:steam_account, user: user, active: true) }
    let(:inventory) { create(:inventory, steam_id: steam_account.steam_id) }

    before do
      puts "Stream Account: #{steam_account}"
      puts "Inventory: #{inventory}"
      puts '========================='

      sign_in user
      get :index
    end

    it 'assigns the active Steam account' do
      expect(assigns(:active_steam_account)).to eq(steam_account)
    end

    it 'assigns the inventories for the active Steam account' do
      expect(assigns(:inventories)).to eq([inventory])
    end

    it 'renders the index template for HTML OR JS format' do
      expect(response).to be_successful
      expect(response).to render_template(:index)
    end
  end
end
