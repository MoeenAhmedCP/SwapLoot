class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :steam_accounts
  has_one :active_steam_account, -> { joins(:user).merge(SteamAccount.active_accounts).limit(1) }, class_name: 'SteamAccount'
end
