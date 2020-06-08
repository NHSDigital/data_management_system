class AddDatasetToProject < ActiveRecord::Migration[6.0]
  def change
    add_column :projects, :dataset_id, :integer
  end
end
