class DropCasDatasetLookup < ActiveRecord::Migration[6.0]
  def change
    drop_table :cas_datasets
  end
end
