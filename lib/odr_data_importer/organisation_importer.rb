module OdrDataImporter
  module OrganisationImporter
    def import_organisations
      @excel_file.shift # remove headers

      existing_organisations_count = Organisation.count
      existed = []
      log_to_process_count(@excel_file.count)

      @excel_file.each do |org_name, org_type|
        type = org_type.upcase
        mapped_type = org_type_mapping[type]
        type = Lookups::OrganisationType.find_by(value: mapped_type)

        organisation = Organisation.where('name ILIKE ?', org_name.strip)
        if organisation.present?
          existed << org_name
        else
          org_attrs = { name: org_name, organisation_type: type }
          org_attrs.merge!(organisation_type_other: 'Unknown') if mapped_type == 'Other'
          Organisation.create!(org_attrs) unless @test_mode
        end
      end

      updated_organisations_count = Organisation.count
      new_organisations = updated_organisations_count - existing_organisations_count

      # print "already existed\n"
      # existed.each do |name|
      #   print "#{name}\n"
      # end
      print "#{existed.count} organisations already existed\n"
      print "#{new_organisations} Organisations created\n"
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
