class AddCcgGorWardToPseudoBirthData < ActiveRecord::Migration[5.0]
  def change
    add_column :birth_data, :ccg9pob, :string
    add_column :birth_data, :ccg9rm, :string
    add_column :birth_data, :gor9rm, :string
    add_column :birth_data, :ward9m, :string
  end
end
