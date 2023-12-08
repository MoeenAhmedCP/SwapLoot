class AddReferenceNotificationToUser < ActiveRecord::Migration[7.0]
  def change
    add_reference :notifications, :user
  end
end
