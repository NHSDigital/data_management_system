class AddSeniorUsersToNotifications < ActiveRecord::Migration[5.0]
  def change
    add_column :notifications, :senior_users, :boolean
  end
end
