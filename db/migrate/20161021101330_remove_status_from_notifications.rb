class RemoveStatusFromNotifications < ActiveRecord::Migration[5.0]
  def change
    remove_column :notifications, :status
  end
end

