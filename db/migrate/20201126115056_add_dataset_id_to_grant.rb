class AddDatasetIdToGrant < ActiveRecord::Migration[6.0]
  def change
    add_column :grants, :dataset_id, :integer
  end
end
