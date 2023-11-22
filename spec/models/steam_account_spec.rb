# frozen_string_literal: true

# spec/models/steam_account_spec.rb

require 'rails_helper'

RSpec.describe SteamAccount, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:unique_name) }
    it { should validate_presence_of(:steam_id) }
    it { should validate_presence_of(:steam_web_api_key) }
  end
end
