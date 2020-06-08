class AddApprovalToProjectDataSourceItems < ActiveRecord::Migration[5.0]
  def change
    add_column :project_data_source_items, :justification, :text
    add_column :project_data_source_items, :approved, :boolean
    add_column :project_data_source_items, :odr_comment, :text
  end
end
