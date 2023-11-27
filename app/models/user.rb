class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :steam_accounts

  def self.active_steam_account(current_user)
    current_user.steam_accounts.active_account.first
  end
end
