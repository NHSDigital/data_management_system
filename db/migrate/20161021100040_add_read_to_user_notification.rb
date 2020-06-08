class AddReadToUserNotification < ActiveRecord::Migration[5.0]
  def change
    add_column :user_notifications, :status, :string, null: false, default: 'new'
  end
end
