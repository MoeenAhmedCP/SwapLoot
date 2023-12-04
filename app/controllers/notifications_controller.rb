class NotificationsController < ApplicationController

    def index
        @notifications = Notification.order(updated_at: :desc).paginate(page: params[:page], per_page: 15)
    end
  
    def mark_all_as_read
        Notification.update_all(is_read: true)
        redirect_to notifications_path
    end
  end
  