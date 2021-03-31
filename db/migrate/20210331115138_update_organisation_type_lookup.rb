# Migration to change OrganisationType Lookup with id of 1 for plan.io 23787
class UpdateOrganisationTypeLookup < ActiveRecord::Migration[6.0]
  include MigrationHelper

  def change
    change_lookup Lookups::OrganisationType, 1, { value: 'Academic Institution (UK)' },
                  { value: 'Academic Institutions' }
  end
end
