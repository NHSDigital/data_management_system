module OdrDataImporter
  module OrganisationUpdater
    def update_organisation_names
      @excel_file.shift # remove headers

      organisations_updated = 0
      not_found = []
      @excel_file.each do |current_name, new_name|
        org = Organisation.where('name ILIKE ?', current_name.strip)

        if org.nil?
          not_found << current_name
          next
        else
          org.update(name: new_name)
        end

        organisations_updated += 1
      end

      puts "Unable to find these organisations: #{not_found.join(', ')}" if not_found.present?
      puts "Updated #{organisations_updated} Organisation names"
    end
  end
end
