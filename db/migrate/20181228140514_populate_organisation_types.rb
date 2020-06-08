class PopulateOrganisationTypes < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class OrganisationType < ApplicationRecord
    attribute :description, :string
  end

  def change
    add_lookup OrganisationType, 1, value: 'Academic Institution (UK)'
    add_lookup OrganisationType, 2, value: 'Commercial'
    add_lookup OrganisationType, 3, value: 'CQC Registered Health and/or Social Care Provider'
    add_lookup OrganisationType, 4, value: 'CQC Approved National Contractor'
    add_lookup OrganisationType, 5, value: 'Local Authority'
    add_lookup OrganisationType, 6, value: 'Government Agency (Health and Social Care)'
    add_lookup OrganisationType, 7, value: 'Government Agency (outside of Health and Adult Social Care)'
    add_lookup OrganisationType, 8, value: 'Independent Sector Organisation'
    add_lookup OrganisationType, 9, value: 'Other'
  end
end
