module OdrDataImporter
  module ApplicationImporter
    STATUS_MAPPING = {
      'NEW'              => 'DRAFT',
      'PENDING'          => 'SUBMITTED',
      'CLOSED'           => 'REJECTED',
      'DPIA_PEER_REVIEW' => 'DPIA_REVIEW'
    }

    def import_application_managers(header)
      app_mans = []
      @excel_file.each do |application|
        attrs = header.zip(application).to_h
        app_mans << attrs['assigned_to']
      end.uniq

      # should all be PHE staff
      counter = 0
      app_mans.each do |email|
        user = User.find_or_initialize_by(email: email.downcase)
        next if user.persisted?

        user.first_name = email.gsub('@phe.gov.uk','').split('.').first
        user.last_name  = email.gsub('@phe.gov.uk','').split('.').last
        # !!! ODR have application managers who aren't actually part of ODR or application managers.
        # try taking off the role
        unless email.in?(ENV['not_real_managers'].split.map { |name| "#{name}@phe.gov.uk" })
          user.grants.build(roleable: SystemRole.fetch(:application_manager))
        end
        user.save! unless @test_mode
        counter += 1
      end
      print "#{counter} application managers created\n"
    end

    def import_applications
      missing_org      = []
      missing_team     = []
      counter          = 0
      would_be_valid   = 0
      would_be_invalid = 0
      missing_owners   = []
      missing_dataset  = []
      @missing_dataset_names = []
      header = @excel_file.shift.map(&:downcase)
      log_to_process_count(@excel_file.count)
      # let's build these now as some as missing.
      import_application_managers(header)
      @org_created_counter = 0
      @team_created_counter = 0
      @user_created_counter = 0
      Project.transaction do
        @excel_file.each do |application|
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
          if attrs['assigned_to'].present?
            user_assigned_to = attrs['assigned_to']
            app_man = User.find_by(email: user_assigned_to.downcase)
            raise "no application manager found for #{attrs['assigned_to']}" if app_man.nil?

            application.assigned_to = app_man
          end

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
              application.valid? ? would_be_valid += 1 : would_be_invalid +=1
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
        print "#{would_be_valid} valid\n"
        print "#{would_be_invalid} invalid\n"
        print "#{missing_dataset.count} missing a dataset\n"
        print "#{@org_created_counter}  Organisations created\n"
        print "#{@team_created_counter} Teams created\n"
        print "#{@user_created_counter} Users created\n"
        
        errors_to_file(missing_owners, 'missing_owners')
        errors_to_file(missing_dataset, 'applications_missing_dataset')
        errors_to_file(@missing_dataset_names, 'missing_dataset_names')
      end
    end

    def build_organisation_for_application(attrs)
      org_name = attrs['organisation_name']
      org = Organisation.find_by(name: org_name)
      return unless org.nil?
      puts "ORGANISATION creating #{org_name}" 
      Organisation.new(name: org_name.strip).tap do |o|
        o.organisation_type = Lookups::OrganisationType.find_by(value: attrs['organisation_type'])
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

      lawful_bases.each do |lawful_basis|
        lawful_base = Lookups::LawfulBasis.where('value ILIKE ?', lawful_basis)

        application.lawful_bases << lawful_base
      end

      # data_to_contact_others
      if attrs['data_to_contact_others'].present?
        contact_others = attrs['data_to_contact_others'].downcase

        application.data_to_contact_others = contact_others == 'no' ? false : true
      end

      # App_status
      state = attrs['app_status'].upcase
      state = STATUS_MAPPING[state] || state
      project_state = Workflow::State.find(state)
      state_missing_msg = "missing status #{attrs['app_status']} for #{attrs['application_log']}"

      raise state_missing_msg if project_state.nil?

      application.states << project_state

      application.description = attrs['description']

      # level_of_identifiability
      if attrs['level_of_identifiability'].present?
        application.level_of_identifiability = Lookups::IdentifiabilityLevel.where(
          'value ILIKE ?', attrs['level_of_identifiability']).first
      end

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
            application.project_datasets << ProjectDataset.new(dataset: dataset,
                                                               terms_accepted: true)
          end
        end
      end

      # section_251_exempt
# TODO: ID's dont make sense.
      # Lookups::CommonLawExemption.pluck(:id, :value)
      # => [[1, "Informed Consent"], [2, "Direct Care Relationship"], [3, "S251 Regulation 2"], [4, "S251 Regulation 3"], [5, "S251 Regulation 5"], [6, "Other"]]

      # data_linkage
      application.data_linkage = attrs['data_linkage']

      # data_already_held_for_project
      application.data_already_held_detail = attrs['data_already_held_for_project']

      # processing_territory_id
      if attrs['processing_territory_id'].present?
        application.processing_territory = Lookups::ProcessingTerritory.where(
          'value ILIKE ?', attrs['processing_territory_id']).first
      end

# TODO: security_assurance_id
      application.security_assurance_id =
        Lookups::SecurityAssurance.where('value ILIKE ?', attrs['security_assurance_id']).first
      # security_assurance_id doesn’t match values I have in Lookups::SecurityAssurance 
      # or the mappings in fetch_security_assurance is that correct? 
      # I cannot find IG Toolkit Level 2 anywhere actually…

      # We can't have the same application name per team
      application.name = application.name + " #{attrs['application_log']}"

      # closure reason
      if attrs['closure_reason'].present?
        closure = Lookups::ClosureReason.find_by(value: attrs['closure_reason'])
        binding.pry if closure.nil?
        application.closure_reason = closure
      end
      application
    end

    def application_project_type
      ProjectType.find_by(name: 'Application')
    end
  end
end
