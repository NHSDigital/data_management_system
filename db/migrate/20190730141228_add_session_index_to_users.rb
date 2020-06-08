class AddSessionIndexToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :session_index, :string
  end
end
