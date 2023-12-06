class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable, and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :steam_accounts
  has_one :active_steam_account, -> { joins(:user).merge(SteamAccount.active_accounts).limit(1) }, class_name: 'SteamAccount'

  def self.ransackable_attributes(auth_object = nil)
    super & ['name', 'email'] # Add any other attributes you want to be searchable
  end

  def self.ransackable_associations(auth_object = nil)
    super # You can customize associations that are searchable here if needed
  end

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :not_active
  end
end
