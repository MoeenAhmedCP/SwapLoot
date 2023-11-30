# frozen_string_literal: true

# Module RotateIp provides a utility method to rotate ips for multiple services.
module RotateIp
  def self.rotate_proxy
    proxy_pool = [
      { address: '185.199.229.156', port: '7492', username: 'xnrlvcgr', password: '9sz7ld0visck' },
      { address: '185.199.228.220', port: '7300', username: 'xnrlvcgr', password: '9sz7ld0visck' },
      { address: '185.199.231.45', port: '8382', username: 'xnrlvcgr', password: '9sz7ld0visck' },
      { address: '188.74.210.207', port: '6286', username: 'xnrlvcgr', password: '9sz7ld0visck' },
    ]
    proxy_pool.sample
  end
end
