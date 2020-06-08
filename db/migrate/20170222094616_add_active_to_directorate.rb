class AddActiveToDirectorate < ActiveRecord::Migration[5.0]
  def change
    add_column :directorates, :active, :boolean, default: true
  end
end
