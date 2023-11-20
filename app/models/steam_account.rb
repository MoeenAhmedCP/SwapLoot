# frozen_string_literal: true

# == Schema Information
#
# Table name: steam_accounts
#
#  id                  :bigint           not null, primary key
#  unique_name         :string           not null
#  steam_id            :string           not null
#  steam_web_api_key   :string           not null
#  waxpeer_api_key     :string
#  csgoempire_api_key  :string
#  market_csgo_api_key :string
#  active              :boolean          default(FALSE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  user_id             :bigint
#
class SteamAccount < ApplicationRecord
  belongs_to :user
  validates :unique_name, :steam_id, :steam_web_api_key, presence: true
end
