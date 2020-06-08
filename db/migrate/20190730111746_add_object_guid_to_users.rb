class AddObjectGuidToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :object_guid, :string
  end
end
