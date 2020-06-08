class AddDatasetTypeToDataset < ActiveRecord::Migration[6.0]
  def change
    add_column :datasets, :dataset_type_id, :integer
  end
end
