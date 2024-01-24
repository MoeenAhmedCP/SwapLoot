class CreateProxies < ActiveRecord::Migration[7.0]
  def change
    create_table :proxies do |t|
      t.string :ip
      t.integer :port
      t.string :username
      t.string :password
      t.references :steam_account, null: false, foreign_key: true
      t.timestamps
    end
  end
end
