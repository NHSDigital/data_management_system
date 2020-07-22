module OdrDataImporter
  module OrganisationImporter
    def import_organisations
      @excel_file.shift # remove headers

      existing_organisations_count = Organisation.count

      @excel_file.each do |org_name, org_type|
        type = org_type.upcase
        mapped_type = org_type_mapping[type]
        type = Lookups::OrganisationType.find_by(value: mapped_type)

        organisation = Organisation.where('name ILIKE ?', org_name.strip)
        next if organisation.present?

        if mapped_type == 'Other'
          Organisation.create(name: org_name,
                              organisation_type: type,
                              organisation_type_other: 'Unknown')
        else
          Organisation.create(name: org_name, organisation_type: type)
        end
      end

      updated_organisations_count = Organisation.count
      new_organisations = updated_organisations_count - existing_organisations_count

      puts "Created #{new_organisations} Organisations"
    end

    private

    def org_type_mapping
      {
        'ACADEMIC INSTITUTION (UK)' => 'Academic Institution (UK)',
        'COMMERCIAL' => 'Commercial',
        'CQC REGISTERED HEALTH AND/OR SOCIAL CARE PROVIDER' => 'CQC Registered Health and/or Social Care Provider',
        'CQC APPROVED NATIONAL CONTRACTOR' => 'CQC Approved National Contractor',
        'LOCAL AUTHORITY' => 'Local Authority',
        'GOVERNMENT AGENCY (HEALTH AND SOCIAL CARE)' => 'Government Agency (Health and Social Care)',
        'GOVERNMENT AGENCY (OUTSIDE OF HEALTH AND ADULT SOCIAL CARE)' => 'Government Agency (outside of Health and Adult Social Care)',
        'INDEPENDENT SECTOR ORGANISATION' => 'Independent Sector Organisation',
        'OTHER' => 'Other',
        'UNKNOWN' => 'Other'
      }
    end
  end
end
