class CreateErrors < ActiveRecord::Migration[7.0]
  def change
    create_table :errors do |t|
      t.string :message, default: ''
      t.string :backtrace, array: true, default: []
      t.string :error_type, default: 'StandardError'
      t.boolean :handled, default: false
      t.string :severity, default: 'error'
      t.json :context, default: {}

      t.timestamps
    end
  end
end
