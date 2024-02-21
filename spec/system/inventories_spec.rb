require 'rails_helper'

RSpec.describe 'Inventories', type: :system do
  describe 'the user visits inventories page after login' do

    let(:user) { create :user }
    let(:steam_account) { build(:steam_account, user: user) }

    before do
      WebMock.disable_net_connect!(allow_localhost: true)

      allow_any_instance_of(Users::SessionsController).to receive(:notify_discord).and_return(nil)
      stub_items_bid_history(steam_account.csgoempire_api_key)
      stub_socket_meta_data(steam_account.csgoempire_api_key)
      steam_account.save!
      stub_get_inventory(steam_account.csgoempire_api_key)
    end

    it 'clicks on refresh button to load the inventories' do
      visit root_path

      login_user(user)

      expect(page).to have_content('Master')
      expect(page).to have_link('Inventory')

      click_link 'Inventory'

      find('#refreshTable').click

      sleep 10
    end
  end
end
