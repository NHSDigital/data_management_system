class AddAllUsersToNotification < ActiveRecord::Migration[5.0]
  def change
    add_column :notifications, :all_users, :boolean
  end
end
