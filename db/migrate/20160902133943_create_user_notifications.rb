class CreateUserNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :user_notifications do |t|
      t.references :user, foreign_key: true
      t.references :notification, foreign_key: true

      t.timestamps
    end
  end
end
