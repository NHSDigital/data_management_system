class AddMattabToPseudoBirthData < ActiveRecord::Migration[5.0]
  def change
    add_column :birth_data, :mattab, :integer
  end
end
