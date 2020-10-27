module OdrDataImporter
  module Users
    def build_application_managers!
      initial_user_count = User.count
      header = @excel_file.shift
      @excel_file.each do |appleman|
        user_attrs = header.zip(appleman).to_h
        # if user exists add application manager role
        user = User.find_by(email: user_attrs['Applicant_Email']&.downcase)
        if user.nil?
          u = build_user(user_attrs)
          u.grants << Grant.new(roleable: TeamRole.fetch(:read_only),
                                team: Team.find_by(name: 'Office for Data Release (ODR)'))
          u.grants << Grant.new(roleable: SystemRole.fetch(:application_manager))
          u.save!
        else
          user.grants << Grant.new(roleable: SystemRole.fetch(:application_manager))
          user.save!
        end
      end

      print "Created #{User.count - initial_user_count} Application Managers\n"
    end

    def import_users_for_eois!
      initial_user_count = User.count
      header = @excel_file.shift
      User.transaction do
        @excel_file.each do |user|
          user_attrs = header.zip(user).to_h
          next if user_attrs['Applicant_Email'].nil?
          # User already exists
          next unless User.find_by(email: user_attrs['Applicant_Email']&.downcase).nil?

          u = build_user(user_attrs)
          org = Organisation.find_by(name: user_attrs['Organisation_Name'])
          raise "#{user_attrs['Organisation']} not found for #{user_attrs['Applicant_Email']}" if org.nil?
          team = Team.find_by(name: user_attrs['organisation_department'],
                              organisation_id: org.id)

          raise "#{user_attrs['organisation_department']} not found for #{user_attrs['Applicant_Email']}" if team.nil?
          u.grants << Grant.new(team: org.teams.find_by(name: team.name),
                                roleable: TeamRole.fetch(:odr_applicant))

          # User emails will not always be PHE
          u.save!(validate: false)
        end
      end
      print "Created #{User.count - initial_user_count} Users\n"
    end

    def build_user(attrs)
      user = User.new(email: attrs['Applicant_Email'].downcase)
      name = if (attrs['Applicant_Name'] =~ /@/) || attrs['Applicant_Name'].nil?
        %w[Unknown Unknown]
      else
        attrs['Applicant_Name'].split
      end
      user.username = name.map(&:downcase).join('_')
      user.last_name = name.pop
      user.first_name = name.join(' ')
      user.z_user_status = ZUserStatus.find_by(name: 'Active')

      user
    end

    def import_eois(eois)
      initial_project_count = Project.count
      header = eois.shift
      eois.each do |eoi|
        eoi_attrs = header.zip(eoi).to_h
        new_eoi = build_eoi(eoi_attrs)
        new_eoi.save!
      end
      print "Created #{Project.count - initial_project_count} EOIs\n"
    end

    def build_eoi(attrs)
      eoi = Project.new(attrs.reject { |k, _| eoi_fields.exclude? k })
      eoi.name = attrs['project_title']
      eoi.project_type = eoi_project_type
      eoi.owner = User.find_by(email: attrs['senior_user_email'])
      eoi.states << Workflow::State.find_by(id: state_mapping[attrs['EOI_status']])
      eoi.team = Team.find_by(name: attrs['team'])
      eoi.end_uses << EndUse.find_by(name: attrs['data_end_use'])

      eoi
    end

    # TODO: what are the responses in the file?

    def eoi_fields
      %w[application_log project_purpose level_of_identifiability]
    end

    def eoi_project_fields
      %w[application_manager EOI_status]
    end

    def eoi_project_type
      ProjectType.find_by(name: 'EOI')
    end

    def state_mapping
      { 'Pending' => 'SUBMITTED' }
    end

    private

    # NCRAS field name, Node name
    # 'Data item' => 'description',
    # 'Field name' => 'name',
    # 'Description of field content' => 'description_detail',
    # 'Derived' => 'Derived',
    # "governance" => governance,
    # 'parent_node' => 'parent_node'

    def ignored_fields
      %w[governance parent_node]
    end

    def node_fields
      %w[description name description_detail derived governance parent_node]
    end

    def occurrences
      { min_occurs: 0, max_occurs: 1 }
    end
  end
end
