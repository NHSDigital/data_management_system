module OdrDataImporter
  module AmendmentImporter
    def create_amendment(application, amendment_attrs)
      # create a linked ProjectAmendment
      amendment_type = amendment_attrs['amendment_type: data flows, data items, data sources, ' \
                                       'processing purpose, data processor, duration, other']
      amendment_type = amendment_type&.split(';')
      amendment_type&.map!(&:titleize)

      # labels: [], created_at: nil, updated_at: nil, project_state_id: nil>
      application.project_amendments.new(requested_at: amendment_attrs['amendment_date'],
                                         labels: amendment_type)

      # amendment is not valid without an attachment
      # pa.valid? => false
      # pa.errors.messages => {:attachment=>["can't be blank"]}
      application.save(validate: false) unless @test_mode

      # update the application
      update_application(application, amendment_attrs) unless @test_mode
    end

    def update_application(application, attrs)
      attrs.each do |attr|
        next if attr[1].blank?

        ignored_fields = [
          'amendment_date',
          'amendment_type: data flows, data items, data sources, processing purpose, ' \
            'data processor, duration, other',
          'assigned_to',
          'project_type',
          'project_title',
          'team_name'
        ]
        field = field_mapping[attr[0]] || attr[0]
        next if field.downcase.in? ignored_fields

        field = field.to_sym
        new_data = attr[1]

        application[field] = new_data
      end

      print "Updated #{application.application_log}\n" if application.changed?
      application.save unless @test_mode
    end

    def field_mapping
      {
        'dpaorgname' => 'dpa_org_name'
      }
    end
  end
end
