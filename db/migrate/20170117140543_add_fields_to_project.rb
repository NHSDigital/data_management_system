class AddFieldsToProject < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :end_use, :string
    add_column :projects, :end_use_other, :string
    add_column :projects, :data_to_contact_others, :boolean
    add_column :projects, :data_to_contact_others_desc, :text
    add_column :projects, :data_already_held_for_project, :boolean
    add_column :projects, :data_linkage, :text
    add_column :projects, :frequency, :string
    add_column :projects, :frequency_other, :string
    add_column :projects, :acg_support, :boolean
    add_column :projects, :acg_who, :string
    add_column :projects, :acg_date, :date
    add_column :projects, :outputs, :string
    add_column :projects, :outputs_other, :string
    add_column :projects, :additional_information, :text
    add_column :projects, :informed_patient_consent, :boolean
    add_column :projects, :s42_of_srsa, :boolean
    add_column :projects, :approved_research_accreditation, :string
    add_column :projects, :ethics_approval_obtained, :boolean
    add_column :projects, :ethics_approval_nrec_name, :string
    add_column :projects, :ethics_approval_nrec_ref, :string
    add_column :projects, :legal_ethical_approved, :boolean
    add_column :projects, :legal_ethical_approval_comments, :text
  end
end
