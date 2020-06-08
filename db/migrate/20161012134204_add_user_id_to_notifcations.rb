class AddUserIdToNotifcations < ActiveRecord::Migration[5.0]
  def change
    add_reference :notifications, :user, foreign_key: true
    add_reference :notifications, :project, foreign_key: true
    add_reference :notifications, :team, foreign_key: true
  end
end
