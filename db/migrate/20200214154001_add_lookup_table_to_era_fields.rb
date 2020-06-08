class AddLookupTableToEraFields < ActiveRecord::Migration[6.0]
  def change
    add_column :era_fields, :lookup_table, :string
  end
end
