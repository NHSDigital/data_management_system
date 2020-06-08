class AddNewProjectApplicationFieldsToProjects < ActiveRecord::Migration[6.0]
  def change
    add_column :projects, :rec_name, :string
    add_column :projects, :processing_territory_outsourced_id, :integer, index: true
    add_column :projects, :form_data, :jsonb, default: {}

    rename_column :projects, :security_assurances_outsourced_id, :security_assurance_outsourced_id

    add_foreign_key :projects, :processing_territories, column: :processing_territory_outsourced_id
  end
end
