class RemoveOdrCommentFromProjectDataSourceItem < ActiveRecord::Migration[5.0]
  def change
    remove_column :project_data_source_items, :odr_comment, :text
    remove_column :project_data_source_items, :justification, :text
  end
end
