class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :notifications do |t|
      t.string :title
      t.string :body
      t.string :notification_type
      t.boolean :is_read, default: false
      t.timestamps
    end
  end
end
