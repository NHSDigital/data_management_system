class AddFieldsToDataSourceItems < ActiveRecord::Migration[5.0]
  def change
    add_column :data_source_items, :occurrences, :integer
    add_column :data_source_items, :category, :string
  end
end
