class AddApprovedToProjectDataset < ActiveRecord::Migration[6.0]
  def change
    add_column :project_datasets, :approved, :boolean
  end
end
