class AddZUserStatusRefToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :z_user_status_id, :integer
  end
end
