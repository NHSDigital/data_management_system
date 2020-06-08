class AddActiveToDivision < ActiveRecord::Migration[5.0]
  def change
    add_column :divisions, :active, :boolean, default: true
  end
end
