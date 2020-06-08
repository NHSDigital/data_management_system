class AddOdrFieldsToProject < ActiveRecord::Migration[5.2]
  class Project < ApplicationRecord; end

  def change
    # Section 1
    add_column :projects, :organisation_id, :integer, index: true
    add_foreign_key :projects, :organisations
    add_column :projects, :main_contact_name, :string
    add_column :projects, :main_contact_email, :string

    # Section 2
    add_column :projects, :sponsor_name, :string
    add_column :projects, :sponsor_department, :string
    add_column :projects, :sponsor_add1, :string
    add_column :projects, :sponsor_add2, :string
    add_column :projects, :sponsor_city, :string
    add_column :projects, :sponsor_postcode, :string
    add_column :projects, :sponsor_country_id, :string, index: true
    add_foreign_key :projects, :countries, column: :sponsor_country_id

    # Section 3
    add_column :projects, :funder_name, :string
    add_column :projects, :funder_department, :string
    add_column :projects, :funder_add1, :string
    add_column :projects, :funder_add2, :string
    add_column :projects, :funder_city, :string
    add_column :projects, :funder_postcode, :string
    add_column :projects, :funder_country_id, :string, index: true
    add_foreign_key :projects, :countries, column: :funder_country_id
    add_column :projects, :awarding_body_ref, :string

    # Section 4
    add_column :projects, :application_log, :string
    add_column :projects, :application_data_sharing_reference, :string
    add_column :projects, :crpd_reference, :string
    add_column :projects, :project_purpose, :text
    add_column :projects, :test_drr_project_summary, :text
    add_column :projects, :test_drr_why_data_required, :text
    add_column :projects, :test_drr_public_benefit, :text
    add_column :projects, :data_end_use_other, :text
    add_column :projects, :duration, :integer

    # Section 5
    add_column :projects, :data_asset_required, :text
    add_column :projects, :onwardly_share, :boolean, default: false
    add_column :projects, :onwardly_share_detail, :text
    add_column :projects, :data_already_held_detail, :text

    # Section 6
    add_column :projects, :programme_support, :boolean, default: false
    add_column :projects, :programme_support_detail, :text
    add_column :projects, :scrn_id, :string
    add_column :projects, :programme_approval_date, :datetime
    add_column :projects, :phe_contacts, :text

    # Section 7
    add_column :projects, :s251_exemption_id, :integer, index: true
    add_foreign_key :projects, :common_law_exemptions, column: :s251_exemption_id

    # Section 8
    add_column :projects, :legal_gateway_id, :integer, index: true
    add_foreign_key :projects, :legal_gateways

    # Section 9
    add_column :projects, :rec_committee_id, :integer, index: true
    add_foreign_key :projects, :rec_committees
    add_column :projects, :rec_reference, :string

    # Section 10
    add_column :projects, :applicant_certification, :boolean
    add_column :projects, :processing_territory_id, :integer, index: true
    add_foreign_key :projects, :processing_territories
    add_column :projects, :processing_territory_other, :string
    add_column :projects, :dpa_org_code, :string
    add_column :projects, :dpa_org_name, :string
    add_column :projects, :dpa_registration_end_date, :datetime
    add_column :projects, :security_assurance_id, :integer, index: true
    add_foreign_key :projects, :security_assurances
    add_column :projects, :ig_code, :string
    add_column :projects, :ig_score, :integer
    add_column :projects, :ig_tooklit_version, :string

    # Section 11
    add_column :projects, :data_processor_name, :string
    add_column :projects, :data_processor_department, :string
    add_column :projects, :data_processor_add1, :string
    add_column :projects, :data_processor_add2, :string
    add_column :projects, :data_processor_city, :string
    add_column :projects, :data_processor_postcode, :string
    add_column :projects, :data_processor_country_id, :string, index: true
    add_foreign_key :projects, :countries, column: :data_processor_country_id
    add_column :projects, :outsourced_certification, :boolean
    add_column :projects, :processing_territory_outsourced_id, :integer, index: true
    add_foreign_key :projects, :processing_territories, column: :processing_territory_outsourced_id
    add_column :projects, :processing_territory_outsourced_other, :string
    add_column :projects, :dpa_org_code_outsourced, :string
    add_column :projects, :dpa_org_name_outsourced, :string
    add_column :projects, :dpa_registration_end_date_outsourced, :datetime
    add_column :projects, :security_assurances_outsourced_id, :integer, index: true
    add_foreign_key :projects, :security_assurances, column: :security_assurances_outsourced_id
    add_column :projects, :ig_code_outsourced, :string
    add_column :projects, :ig_score_outsourced, :integer
    add_column :projects, :ig_tooklit_version_outsourced, :string

    # Section 12
    add_column :projects, :additional_info, :text

    # Section 13
    add_column :projects, :application_date, :datetime

    ##### Other #####
    add_column :projects, :first_contact_date, :datetime
    add_column :projects, :first_reply_date, :datetime
    add_column :projects, :release_date, :datetime
    add_column :projects, :ndg_opt_out_applied, :boolean, default: false
    add_column :projects, :ndg_opt_out_processed_date, :datetime
    add_column :projects, :destruction_form_received_date, :datetime

    add_column :projects, :assigned_user_id, :integer, index: true
    add_foreign_key :projects, :users, column: :assigned_user_id
  end
end
