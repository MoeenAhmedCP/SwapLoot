class AddUserToErrors < ActiveRecord::Migration[7.0]
  def change
    add_reference :errors, :user, foreign_key: true, index: true, null: true
  end
end
