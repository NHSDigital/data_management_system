class ChangeOdrUserOnNotifications < ActiveRecord::Migration[5.0]
  def change
    rename_column :notifications, :odr_user, :odr_users
  end
end
