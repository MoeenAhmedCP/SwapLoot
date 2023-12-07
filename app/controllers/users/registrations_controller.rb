class Users::RegistrationsController < Devise::RegistrationsController
    def create
      super do |resource|
        flash[:notice] = "Custom registration message" if resource.persisted?
      end
    end
end
  