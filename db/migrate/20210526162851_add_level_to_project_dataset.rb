class AddLevelToProjectDataset < ActiveRecord::Migration[6.0]
  def change
    add_column :project_datasets, :level_one, :boolean
    add_column :project_datasets, :level_two, :boolean
    add_column :project_datasets, :level_three, :boolean
  end
end
