class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :steam_accounts

  scope :active_steam_accounts, -> { joins(:steam_accounts).where(steam_accounts: { active: true }) }
end
