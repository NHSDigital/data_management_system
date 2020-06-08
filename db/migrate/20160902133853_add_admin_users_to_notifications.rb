class AddAdminUsersToNotifications < ActiveRecord::Migration[5.0]
  def change
    add_column :notifications, :admin_users, :boolean
    add_column :notifications, :odr_user, :boolean
  end
end
