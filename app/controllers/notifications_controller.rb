class NotificationsController < ApplicationController
	skip_before_action :verify_authenticity_token, only: [:mark_all_as_read]

	def index
		@notifications = current_user.notifications.order(updated_at: :desc).paginate(page: params[:page], per_page: 15)
	end

	def mark_all_as_read
		current_user.notifications.update_all(is_read: true)
	end
end
