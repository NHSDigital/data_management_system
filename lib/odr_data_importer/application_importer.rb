module OdrDataImporter
  module ApplicationImporter
    STATUS_MAPPING = {
      'NEW'              => 'DRAFT',
      'PENDING'          => 'SUBMITTED',
      'CLOSED'           => 'REJECTED',
      'DPIA_PEER_REVIEW' => 'DPIA_REVIEW'
    }

    def import_application_managers
      header = @excel_file.shift
      app_mans = []
      @excel_file.each do |application|
        attrs = header.zip(application).to_h
        app_mans << attrs['assigned_to']
      end

      # should all be PHE staff
      counter = 0
      app_mans.uniq.each do |email|
        user = User.find_or_initialize_by(email: email.downcase)
        next if user.persisted?

        user.first_name = email.gsub('@phe.gov.uk','').split('.').first
        user.last_name  = email.gsub('@phe.gov.uk','').split('.').last
        user.grants << Grant.new(roleable: SystemRole.fetch(:application_manager))
        user.save! unless @test_mode
        counter += 1
      rescue StandardError => e
        binding.pry
      end
      print "#{counter} application managers created\n"
    end

    def import_applications
      missing_org      = []
      missing_team     = []
      counter          = 0
      missing_owners   = []
      missing_dataset  = []
      @missing_dataset_names = []
      header = @excel_file.shift.map(&:downcase)
      log_to_process_count(@excel_file.count)
      @org_created_counter = 0
      @team_created_counter = 0
      @user_created_counter = 0

      Project.transaction do
        @excel_file.each_with_index do |application, i|
          # next if i > 4
          attrs = header.zip(application).to_h
          build_organisation_for_application(attrs)
          build_team_for_application(attrs)
          build_user_for_application(attrs)
          unused_columns = header - Project.new.attributes.keys

          # Make a new project
          application = Project.new(attrs.reject { |k, _| unused_columns.include? k })

          # project_type
          application.project_type = application_project_type

          # Set the correct attributes like a user being an instance of User
          # assigned_to - I've changed this to an email in the spreadsheet
          add_assigned_user(application, attrs)

          application.receiptsentby = attrs['receiptsentby'] if attrs['receiptsentby'].present?

          # Organisation & team
          org_name = attrs['organisation_name']
          org = Organisation.where('name ILIKE ?', org_name.strip)&.first
          team_name = attrs['team_name']

          if org.blank?
            missing_org << org_name
          else
            team = org.teams.where('name ILIKE ?', team_name.strip).first
            if team.blank?
              missing_team << team_name
            else
              application.team = team

              application.owner = User.find_by(email: attrs['applicant_email']&.downcase)

              missing_owners.push attrs['applicant_email'] if application.owner.nil?

              build_rest_of_application(application, attrs)

              missing_dataset << application.application_log if 
                application.project_datasets.empty? && attrs['data_asset_required'].present?
              app_valid = application.valid?
              if app_valid
                application.save! unless @test_mode
              elsif application.errors.size == 1 && application.errors.messages[:owner_grant].present?
                application.save(validate: false)
              else
                binding.pry
                raise "#{attrs['application_log']} is invalid"
              end
              print "#{counter += 1}\r"
            end
          end
        end
        print "#{missing_org.count} missing organisations\n"
        print "#{missing_team.count} missing teams\n"
        print "#{counter} applications created\n"
        print "#{missing_dataset.count} missing a dataset\n"
        print "#{@org_created_counter}  Organisations created\n"
        print "#{@team_created_counter} Teams created\n"
        print "#{@user_created_counter} Users created\n"
        
        errors_to_file(missing_owners, 'missing_owners')
        errors_to_file(missing_dataset, 'applications_missing_dataset')
        errors_to_file(@missing_dataset_names, 'missing_dataset_names')
      end
    end

    def add_assigned_user(application, attrs)
      return unless attrs['assigned_to'].present?

      user_assigned_to = attrs['assigned_to']
      app_man = User.find_by(email: user_assigned_to.downcase)
      raise "no application manager found for #{attrs['assigned_to']}" if app_man.nil?

      application.assigned_user_id = app_man.id
      attrs.delete('assigned_to')
    end

    def build_organisation_for_application(attrs)
      org_name = attrs['organisation_name']
      org = Organisation.find_by(name: org_name)
      return unless org.nil?
      puts "ORGANISATION creating #{org_name}" 
      Organisation.new(name: org_name.strip).tap do |o|
        org_type = attrs['organisation_type']
        o.organisation_type = Lookups::OrganisationType.find_by(value: org_type)
        o.organisation_type_other = 'Unknown' if org_type == 'Other'
        o.save!
      end
      @org_created_counter += 1
    rescue StandardError => e
      require 'pry' ; binding.pry
      raise
    end

    def build_team_for_application(attrs)
      team_name = attrs['team_name']
      team = Team.find_by(name: team_name)
      return if team

      Team.new(name: team_name.strip).tap do |t|
        t.organisation = Organisation.find_by(name: attrs['organisation_name'])
        t.z_team_status = ZTeamStatus.find_by(name: 'Active')
        t.save!
      end
      @team_created_counter += 1
    rescue StandardError => e
      require 'pry' ; binding.pry
      raise
    end

    def build_user_for_application(attrs)
      email = attrs['applicant_email']&.downcase
      return if email.nil? # there's an application with no user

      user = User.find_by(email: email)
      if user.nil?
        org = Organisation.find_by(name: attrs['organisation_name'])
        team = org.teams.find_by(name: attrs['team_name'])
        user = User.new(email: email, first_name: attrs['first_name'],
                 last_name: attrs['last_name'], username: attrs['username']).tap do |u|
          u.grants.build(team: team, roleable: TeamRole.fetch(:odr_applicant))
        end
        user_valid = user.valid?
        if user_valid
          user.save!
        elsif user.errors.size == 1 && user.errors.messages[:username].present?
          user.save(validate: false)
        else
          require 'pry' ; binding.pry
          raise
        end
        @user_created_counter += 1
      else # potentially add another team grant
        user.grants.find_or_initialize_by(team: team, roleable: TeamRole.fetch(:odr_applicant))
        user_valid = user.valid?
        if user_valid
          user.save!
        elsif user.errors.size == 1 && user.errors.messages[:username].present?
          user.save(validate: false)
        else
          require 'pry' ; binding.pry
          raise
        end
      end
    rescue StandardError => e
      require 'pry' ; binding.pry
      raise
    end

    
    def build_rest_of_application(application, attrs)
      # article 6 & article 9 - Legal Basis
      lawful_bases = []

      lawful_bases << attrs['article6'] if attrs['article6'].present?

      if attrs['article9'].present?
        article9s = attrs['article9'].split(/(?=Art\.)/)
        article9s = article9s.map { |article| article.gsub(/Art.\d.2./, 'Art. 9.2')}

        lawful_bases << article9s
      end

      if lawful_bases.present?
        application.lawful_bases.delete_all # so we can reuse for amendments

        lawful_bases.each do |lawful_basis|
          lawful_base = Lookups::LawfulBasis.where('value ILIKE ?', lawful_basis)

          application.lawful_bases << lawful_base
        end
      end

      # data_to_contact_others
      if attrs['data_to_contact_others'].present?
        contact_others = attrs['data_to_contact_others'].downcase

        application.data_to_contact_others = contact_others == 'no' ? false : true
      end

      # App_status
      if attrs['app_status'].present?
        state = attrs['app_status'].upcase
        state = STATUS_MAPPING[state] || state
        project_state = Workflow::State.find(state)
        state_missing_msg = "missing status #{attrs['app_status']} for #{attrs['application_log']}"

        raise state_missing_msg if project_state.nil?

        application.states << project_state
      end

      application.description = attrs['description'] if attrs['description']

      # level_of_identifiability
      add_lookup_field(application, attrs['level_of_identifiability'],
                       Lookups::IdentifiabilityLevel, :level_of_identifiability, true)

      # data_end_use
      if attrs['data_end_use'].present?
        attrs['data_end_use'].split(';').each do |end_use|
          application.end_uses << EndUse.where('name ILIKE ?', end_use.strip)
        end
      end

      # data_asset_required
      if attrs['data_asset_required'].present?
        attrs['data_asset_required'].split(';').each do |dataset_name|
          dataset = Dataset.find_by(name: dataset_name)
          if dataset.nil?
            @missing_dataset_names << dataset_name
          else
            application.project_datasets.delete_all
            application.project_datasets << ProjectDataset.new(dataset: dataset,
                                                               terms_accepted: true)
          end
        end
      end

      # section_251_exempt
      # Lookups::CommonLawExemption.pluck(:id, :value)
      # => [[1, "Informed Consent"], [2, "Direct Care Relationship"], [3, "S251 Regulation 2"], [4, "S251 Regulation 3"], [5, "S251 Regulation 5"], [6, "Other"]]
      if attrs['section_251_exempt'].present?
        s251_value = s251_mapping[attrs['section_251_exempt']] || attrs['section_251_exempt']
        s251_value = 'Other' if s251_value == 'No legal gateway required'
        application.s251_exemption_id = Lookups::CommonLawExemption.find_by(value: s251_value).id
      end

      # data_linkage
      application.data_linkage = attrs['data_linkage'] if attrs['data_linkage']

      # data_already_held_for_project
      application.data_already_held_detail = attrs['data_already_held_for_project'] if attrs['data_already_held_for_project']

      # processing_territory_id
      add_lookup_field(application, attrs['processing_territory_id'],
                       Lookups::ProcessingTerritory, :processing_territory)
      add_lookup_field(application, attrs['security_assurance_id'],
                       Lookups::SecurityAssurance, :security_assurance)

      # We can't have the same application name per team
      if attrs['application_log'].present?
        application.name = application.name + " #{attrs['application_log']}" if
          Project.of_type_application.where(name: application.name).count.positive?
      end

      # closure reason
      if attrs['closure_reason'].present?
        closure = Lookups::ClosureReason.find_by(value: attrs['closure_reason'])
        binding.pry if closure.nil?
        application.closure_reason = closure
      end
      remove_processed_attrs(attrs)
      application
    rescue StandardError => e
      binding.pry
    end

    def remove_processed_attrs(attrs)
      processed = %w[article6 article9 data_to_contact_others app_status description
                     level_of_identifiability data_end_use data_asset_required section_251_exempt
                     data_linkage data_already_held_for_project processing_territory_id
                     security_assurance_id closure_reason]
      attrs.delete_if { |k, v| k.in? processed }
    end

    def application_project_type
      ProjectType.find_by(name: 'Application')
    end

    def s251_mapping
      {
        'Consent' => "Informed Consent",
        'Direct Care' => "Direct Care Relationship"
      }
    end

    def add_lookup_field(application, val, lookup_class, field, use_value = false)
      return if val.blank?

      lookup = lookup_class.where('value ILIKE ?', val).first
      raise "#{val} not found in #{lookup_class}" if lookup.nil?

      application.send("#{field}=", use_value ? lookup.value : lookup)
    end
  end
end
