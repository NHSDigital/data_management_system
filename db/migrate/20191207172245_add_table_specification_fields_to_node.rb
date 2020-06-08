# Add Datascience fields to Node
class AddTableSpecificationFieldsToNode < ActiveRecord::Migration[6.0]
  def change
    # Table Details
    add_column :nodes, :table_id,               :integer
    add_column :nodes, :table_name,             :string  
    add_column :nodes, :table_schema_name,      :string
    add_column :nodes, :qualified_table_name,   :string
    add_column :nodes, :table_type,             :string
    add_column :nodes, :table_type_description, :text
    add_column :nodes, :number_of_columns,      :integer
    add_column :nodes, :primary_key_name,       :string
    add_column :nodes, :primary_key_columns,    :string
    add_column :nodes, :table_description,      :text
    add_column :nodes, :table_comment,          :string
    add_column :nodes, :published,              :boolean
    add_column :nodes, :removed,                :boolean
    # Table Columns (table_id already added)
    add_column :nodes, :column_id,              :integer
    add_column :nodes, :field_number,           :integer
    add_column :nodes, :field_name,             :string
    add_column :nodes, :field_type,             :string
    add_column :nodes, :allow_nulls,            :boolean
    add_column :nodes, :hes_field_name,         :string
    add_column :nodes, :field_description,      :text
    add_column :nodes, :validation_rules,       :text
  end
end
