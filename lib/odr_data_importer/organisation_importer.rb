module OdrDataImporter
  module OrganisationImporter
    def import_organisations
      header = @excel_file.shift # remove headers

      existing_organisations_count = Organisation.count
      existed = []
      log_to_process_count(@excel_file.count)

      @excel_file.each do |row|
        attrs = header.zip(row).to_h
        org_name = attrs['Organisation_name']
        org_type = attrs['Organisation_Type']
        type = Lookups::OrganisationType.find_by(value: org_type)
        raise "#{org_type} - Organisation type not found" if type.nil?

        organisation = Organisation.where('name ILIKE ?', org_name.strip)
        if organisation.present?
          existed << org_name
        else
          org_attrs = { name: org_name, organisation_type: type }
          org_attrs.merge!(organisation_type_other: 'Unknown') if org_type == 'Other'
          Organisation.create!(org_attrs) unless @test_mode
        end
      end

      updated_organisations_count = Organisation.count
      new_organisations = updated_organisations_count - existing_organisations_count

      print "#{existed.count} organisations already existed\n"
      print "#{new_organisations} Organisations created\n"
    end
  end
end
