class AddApplicantFieldsToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :applicant_title_id, :integer, index: true
    add_column :projects, :applicant_first_name, :string
    add_column :projects, :applicant_last_name, :string
    add_column :projects, :applicant_job_title, :string
    add_column :projects, :applicant_email, :string
    add_column :projects, :applicant_telephone, :string
    add_foreign_key :projects, :titles, column: :applicant_title_id
  end
end
