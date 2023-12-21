class NotificationsController < ApplicationController

    def index
        @notifications = current_user.notifications.order(updated_at: :desc).paginate(page: params[:page], per_page: 15)
    end
  
    def mark_all_as_read
        current_user.notifications.update_all(is_read: true)
        flash[:notice] = "All notification marked read"
        redirect_to notifications_path
    end
  end
  