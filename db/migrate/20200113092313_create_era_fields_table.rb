class CreateEraFieldsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :era_fields do |t|
      t.belongs_to :node
      t.string :ebr, array: true
      t.string :ebr_rawtext_name
      t.string :ebr_virtual_name, array: true
      t.string :event, array: true
      t.string :event_field_name, array: true
      t.string :comments, limit: 255

      t.timestamps
    end
  end
end
