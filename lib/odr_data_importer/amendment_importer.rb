module OdrDataImporter
  module AmendmentImporter
    def import_amendments
      pre_migration_count = ProjectAmendment.count
      amendment_headers = @excel_file.shift.map(&:downcase)
      log_to_process_count(@excel_file.count)

      applications = read_excel_file(SafePath.new('tmp').join('Application data 20200724.xlsx'), 'Applications')
      
      # TODO: applications = read_excel_file(SafePath.new('db_files').join(ENV['application_fname']), 'Applications')

      applications_headers = applications.shift.map(&:downcase)
      required_application_data_hash = {}

      applications.each do |application|
        applications_attrs = applications_headers.zip(application).to_h

        required_application_data_hash[applications_attrs['application_log']] = {
          name: applications_attrs['name']
        }
      end
      binding.pry
      missing_ids = []
      @excel_file.each do |amendment|
        amendment_attrs = amendment_headers.zip(amendment).to_h

        # TODO: Add handling of suffixed ids
        if required_application_data_hash[amendment_attrs['application_log']]
          application_name = required_application_data_hash[amendment_attrs['application_log']][:name]
        else
          missing_ids << amendment_attrs['application_log']
          next
        end

        project = Project.where('name ILIKE ?', application_name).first

        # create a linked ProjectAmendment
        amendment_type = amendment_attrs['amendment_type: data flows, data items, data sources, ' \
                                         'processing purpose, data processor, duration, other']
        amendment_type = amendment_type&.split(';')
        amendment_type&.map!(&:titleize)

        # labels: [], created_at: nil, updated_at: nil, project_state_id: nil>
        pa = project.project_amendments.new(requested_at: amendment_attrs['amendment_date'],
                                            labels: amendment_type)

        # amendment is not valid without an attachment
        # pa.valid? => false
        # pa.errors.messages => {:attachment=>["can't be blank"]}
        pa.save(validate: false)

        # update the application
        update_application(project, amendment_attrs)
      end

      post_migration_count = ProjectAmendment.count

      total_created = post_migration_count - pre_migration_count

      puts "Created #{total_created} amendments" if total_created >= 1
      puts "These IDs were missing: #{missing_ids.join(', ')}" if missing_ids.present?
    end

    def update_application(project, attrs)
      attrs.each do |attr|
        next if attr[1].blank?

        ignored_fields = [
          'amendment_date',
          'amendment_type: data flows, data items, data sources, processing purpose, ' \
            'data processor, duration, other',
          'assigned_to',
          'project_type'
        ]
        next if attr[0].downcase.in? ignored_fields

        field = attr[0].to_sym
        new_data = attr[1]

        project[field] = new_data

        # TODO: Make this better
        project.save
      end
    end
  end
end
