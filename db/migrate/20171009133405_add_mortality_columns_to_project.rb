class AddMortalityColumnsToProject < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :informed_patient_consent_mortality, :boolean
    add_column :projects, :s42_of_srsa, :boolean
  end
end
