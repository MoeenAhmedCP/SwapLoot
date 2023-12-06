# app/admin/dashboard.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu false # This will hide the dashboard from the menu

  controller do
    before_action :redirect_to_admin_users

    def redirect_to_admin_users
      redirect_to admin_admin_users_path
    end
  end

  content title: proc { I18n.t("active_admin.dashboard") } do
    # Your content here, or leave it empty if you don't want anything on the dashboard
  end
end
