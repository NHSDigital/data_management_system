namespace :organisation do
  # Create PHE. Haven't used migration for now as destroying a Organisation destroys all teams
  task migrate: :environment do
    org_type = 'Government Agency (Health and Social Care)'
    phe_org_type = Lookups::OrganisationType.find_by(value: org_type)
    phe_country = Lookups::Country.find_by(value: 'UNITED KINGDOM')
    org = Organisation.create!(name: 'Public Health England', organisation_type_id: phe_org_type.id,
                               country_id: phe_country.id)
    org.reload
    print "Updated PHE Organisation\n"

    # Update existing Teams
    Team.update_all(organisation_id: org.id)
    print "Updated #{Team.count} teams\n"
  end
end
