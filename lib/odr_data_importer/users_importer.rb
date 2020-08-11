module OdrDataImporter
  module UsersImporter
    def import_users
      # excel file here is going to be the users page
      @excel_file.shift # remove headers
      # application_log | First_name | Last_name | Username | applicant_email
      users = @excel_file # this is now an array of users

      log_to_process_count(@excel_file.count)

      # I need to work out how to load the teams file, I might need to hard code it for now
      teams = read_excel_file(SafePath.new('tmp').join(@fname), 'Applications')
      header = teams.shift # remove headers

      # teams headers: application_log | Organisation_name | team_name
      teams_hash = teams.each_with_object({}) do |row, hash|
        app_attrs = header.zip(row).to_h
        hash[app_attrs['application_log']] = { org_name: app_attrs['Organisation_name'],
                                               team_name: app_attrs['team_name'] }
      end

      missing_org  = []
      missing_team = []
      user_count   = 0
      updated      = 0
      created      = 0
      grant_before = Grant.count
      users.each do |application_log, first_name, last_name, _, email|
        user = User.find_or_initialize_by(email: email.downcase)
        # don't update if exactly the same
        next if user.id && (user.first_name == first_name) && (user.last_name == last_name)

        updated += 1 unless user.id.nil?
        user.first_name = first_name
        user.last_name  = last_name
        team_name = teams_hash[application_log][:team_name]
        org       = teams_hash[application_log][:org_name]

        organisation = Organisation.where('name ILIKE ?', org)&.first

        if organisation.blank?
          missing_org << org
        else
          team = organisation&.teams&.where('name ILIKE ?', team_name)&.first
          if team.blank?
            missing_team << team_name
          else
            user.grants.find_or_initialize_by(team: team, roleable: TeamRole.fetch(:odr_applicant))
            created += 1 if user.id.nil?
          end
          user.save! unless @test_mode
        end
      end
      print "#{missing_org.count} missing organisations!\n"
      print "#{missing_team.count} missing teams!\n"
      print "#{created} created!\n"
      print "#{updated} updated!\n"
      print "#{Grant.count - grant_before} grants created!\n"
    end
  end
end
