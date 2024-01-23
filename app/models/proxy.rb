class Proxy < ApplicationRecord
  validates :ip, presence: true
  validates :port, presence: true
  belongs_to :steam_account

  validate :validate_pingable_ip

  private

  def validate_pingable_ip
    pingable = Net::Ping::TCP.new(ip, port).ping?
    errors.add(:ip, 'is not pingable') unless pingable
  end
end
