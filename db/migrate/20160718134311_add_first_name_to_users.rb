class AddFirstNameToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :telephone, :string
    add_column :users, :mobile, :string
    add_column :users, :location, :string
    add_column :users, :notes, :text
  end
end
