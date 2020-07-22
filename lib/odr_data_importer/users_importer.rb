module OdrDataImporter
  module UsersImporter
    def import_users
      # excel file here is going to be the users page
      @excel_file.shift # remove headers
      # application_log | First_name | Last_name | Username | applicant_email
      users = @excel_file # this is now an array of users

      # I need to work out how to load the teams file, I might need to hard code it for now
      teams = read_excel_file(SafePath.new('db_files').join(@fname), 'Teams')
      teams.shift # remove headers
      # teams headers: application_log | Organisation_name | team_name

      teams_hash = {}
      teams.each do |team|
        teams_hash[team[0]] = { org_name: team[1], team_name: team[2]}
      end

      users.each do |application_log, first_name, last_name, _, email|
        user = User.find_or_initialize_by(email: email.downcase)
        user.update(first_name: first_name, last_name: last_name)
        team_name = teams_hash[application_log][:team_name]
        org       = teams_hash[application_log][:org_name]

        organisation = Organisation.where('name ILIKE ?', org)&.first

        if organisation.blank?
          puts "Organisation #{org} doesn't exist"
          next
        end

        team = organisation&.teams&.where('name ILIKE ?', team_name)&.first

        if team.blank?
          # make this blow up if they are not in a team - for now make it output the team
          puts "Team #{team_name} doesn't exist"
          next
        else
          user.grants << Grant.new(team: team, roleable: TeamRole.fetch(:odr_applicant))
        end

        user.save!
      end
    end
  end
end
