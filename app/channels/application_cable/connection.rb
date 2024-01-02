module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      if request.params.present?
        if request.params['steam_id'].present? && verified_user = SteamAccount.find(request.params['steam_id']).user
          verified_user
        elsif request.session['warden.user.user.key'].present?
          User.find(request.session['warden.user.user.key'].first.first)
        else
          reject_unauthorized_connection
        end
      end
    end
  end
end
