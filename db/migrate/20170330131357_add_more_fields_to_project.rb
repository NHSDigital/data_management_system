class AddMoreFieldsToProject < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :direct_care, :boolean
    add_column :projects, :section_251_exempt, :boolean
    add_column :projects, :cag_ref, :string
    add_column :projects, :date_of_approval, :date
    add_column :projects, :date_of_renewal, :date
    add_column :projects, :regulation_health_services, :boolean
    add_column :projects, :caldicott_email, :string
  end
end
