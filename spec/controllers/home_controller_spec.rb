# frozen_string_literal: true

# spec/controllers/home_controller_spec.rb

require 'rails_helper'
require 'webmock/minitest'
require 'webmock/rspec'
require 'spec_helper'

RSpec.describe HomeController, type: :controller do
  let(:user) { create(:user) }
  let(:active_steam_account) { create(:steam_account, active: true, user: user, csgoempire_api_key: '812bb8bd18af87a449b183c6075117f1') }

  before do
    puts "User: #{user}"
    puts "Active Steam Account: #{active_steam_account}"
    puts '========================='

    sign_in user
  end
  before do
    WebMock.allow_net_connect!
  end

  after do
    WebMock.disable_net_connect!
  end

  describe 'GET #index' do
    it 'assigns the correct instance variables' do
      get :index
      expect(assigns(:active_steam_account)).to eq(active_steam_account)
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #fetch_user_data' do
    it 'responds with success' do
      stub_request(:get, 'https://csgoempire.com/api/v2/metadata/socket')
        .with(headers: { 'Authorization' => 'Bearer 812bb8bd18af87a449b183c6075117f1' })
        .to_return(status: 200, body: '{"user": {"id": 8065093, "steam_name": "swaploot78"}}', headers: {})
      # Your existing test code

      csgo_empire = CsgoempireService.new(user)
      response = JSON.parse(csgo_empire.fetch_user_data)

      expect(response).to be_kind_of(Hash)
      expect(response['user']['id']).to eq(8065093)
      expect(response['user']['steam_name']).to eq('swaploot78')
    end
  end

  # Add more tests for other actions...

  describe 'POST #update_active_account' do
    it 'updates the active account and redirects to root path' do
      other_steam_account = create(:steam_account, user: user)
      post :update_active_account, params: { steam_id: other_steam_account.steam_id }
      expect(response).to redirect_to(root_path)
      expect(other_steam_account.reload.active).to be(true)
      expect(active_steam_account.reload.active).to be(false)
    end
  end

  # Add more tests for private methods...

  describe 'GET #refresh_balance' do
    it 'responds with success' do
      request.headers['X-CSRF-Token'] = controller.send(:form_authenticity_token)
      get :refresh_balance, format: :js
      expect(response).to be_successful
    end
  end
end
