module OdrDataImporter
  module OrganisationUpdater
    def update_organisation_names
      @excel_file.shift # remove headers

      organisations_updated = 0
      not_found = []
      log_to_process_count(@excel_file.count)

      @excel_file.each do |current_name, new_name|
        org = Organisation.where('name ILIKE ?', current_name.strip)

        if org.nil?
          not_found << current_name
        else
          org.update(name: new_name) unless @test_mode
          organisations_updated += 1
        end
      end

      puts "Unable to find these organisations: #{not_found.join(', ')}" if not_found.present?
      puts "Updated #{organisations_updated} Organisation names"
    end
  end
end
