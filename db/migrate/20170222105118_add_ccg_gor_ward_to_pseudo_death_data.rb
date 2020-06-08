class AddCcgGorWardToPseudoDeathData < ActiveRecord::Migration[5.0]
  def change
    add_column :death_data, :ccg9pod, :string
    add_column :death_data, :ccg9r, :string
    add_column :death_data, :gor9r, :string
    add_column :death_data, :ward9r, :string
  end
end
