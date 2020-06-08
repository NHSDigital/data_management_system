class CreateNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :notifications do |t|
      t.string :title
      t.string :body
      t.string :status
      t.string :created_by
      t.references :notification_template, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
