class AddDatasetIdToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :team_dataset_id, :integer
  end
end
