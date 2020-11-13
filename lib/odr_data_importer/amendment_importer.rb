module OdrDataImporter
  module AmendmentImporter
    # We need to import in order so we can try and maintain sequential updates to an application
    def import_amendments
      @no_application_ids = []
      @amendments_created_count = 0
      header = @excel_file.shift.map(&:downcase)
      log_to_process_count(@excel_file.count)
      ProjectAmendment.transaction do
        amendments = @excel_file.each_with_object([]) do |amendment, with_attrs|
          with_attrs << header.zip(amendment).to_h
        end
        grouped_by_app = amendments.group_by { |a| a['application_log'] }
        grouped_by_app.transform_values! do |amendments_for_app|
          amendments_for_app.sort_by { |a| a['order']}
        end
        grouped_by_app.each do |application_log, amendments_for_app|
          application = Project.of_type_application.find_by(application_log: application_log)
          application = application_finder_fallback(application_log) if application.nil?
          if application.nil?
            @no_application_ids << application_log
          else
            amendments_for_app.each do |amemdment_attrs|
              create_amendment(application, amemdment_attrs)
            end
          end
        end
      end
      puts "Couldn't create #{@no_application_ids}"
    end

    def application_finder_fallback(application_log)
      @application_logs ||=
        Project.of_type_application.pluck(:id, :application_log).each_with_object({}) do |(id, log), lookup|
          next if log.nil?

          lookup[log.downcase] = id
        end
      id = @application_logs[application_log.downcase]
      return if id.nil?

      Project.find(id)
    end

    def create_amendment(application, amendment_attrs)
      # create a linked ProjectAmendment
      # amendment_type = amendment_attrs['amendment_type: data flows, data items, data sources, ' \
      #                                  'processing purpose, data processor, duration, other']
      amendment_type = amendment_attrs['amendment_type: data flows; data items; data sources; processing purpose; data processor; duration; other']
      amendment_type = amendment_type&.split(';')
      amendment_type&.map!(&:titleize)

      # Give amendments a silly date if missing
      amendment_attrs['amendment_date'] = nil if amendment_attrs['Amendment_date'] == '?'
      amendment_attrs['amendment_date'] ||= '1900-01-01'
      # labels: [], created_at: nil, updated_at: nil, project_state_id: nil>
      # default nil amendment type. this is a validation normally being bypassed
      amendment_type ||= %w[Other]
      reference = amendment_attrs['amendment_ref']
      application.project_amendments.find_or_initialize_by(requested_at: amendment_attrs['amendment_date'],
                                                           labels: amendment_type,
                                                           reference: reference)

      # amendment is not valid without an attachment
      application.project_amendments.each { |pa| pa.save!(validate: false) } unless @test_mode

      # update the application
      update_application(application, amendment_attrs) unless @test_mode
      print "AMENDMENTS CREATED\r#{@amendments_created_count += 1}"
    end

    def update_application(application, attrs)
      attrs.each do |attr|
        next if attr[1].blank?

        ignored_fields = [
          'amendment_ref',
          'application_log',
          'amendment_date',
          'amendment_type: data flows; data items; data sources; processing purpose; data processor; duration; other',
          'assigned_to',
          'project_type',
          'project_title',
          'team_name',
          'order'
        ]
        field = field_mapping[attr[0]] || attr[0]
        next if field.downcase.in? ignored_fields

        field = field.to_sym
        new_data = attr[1]
        if field_requires_lookup?(field) && new_data.present?
          send("amend_#{field}", application, field, attr)
        else
          application[field] = new_data
        end
      end

      print "Updating #{application.application_log}\n" if application.changed?
      application.save! unless @test_mode
    end

    def field_mapping
      {
        'dpaorgname' => 'dpa_org_name'
      }
    end

    def field_requires_lookup?(field)
      %i[security_assurance_id processing_territory_id].include? field
    end

    def amend_security_assurance_id(application, field, attr)
      sa = Lookups::SecurityAssurance.find_by(value: security_assurance_mapping[attr[1]])
      application[field] = sa.id unless sa.nil?
    end


    def amend_processing_territory_id(application, field, attr)
      pt = Lookups::SecurityAssurance.find_by(value: attr[1])
      application[field] = pt.id unless pt.nil?
    end

    def security_assurance_mapping
      {
        'Data Security and Protection (DSP)  Toolkit' => 'Data Security and Protection Toolkit',
        'DSP Toolkit' => 'Data Security and Protection Toolkit',
        'IG Toolkit Level 2' => 'Data Security and Protection Toolkit',
        'ISO 27001' => 'ISO 27001',
        'SLSP' => 'Project specific System Level Security Policy',
        'Not Applicable' => nil,
        'N/A' => nil
      }
    end
  end
end
