module OdrDataImporter
  module TeamsImporter
    def import_teams
      existing_count       = Team.count
      active_team_status   = ZTeamStatus.find_by(name: 'Active')
      team_already_existed = 0
      org_not_found        = 0
      org_not_found_names  = []
      counter              = 0

      header = @excel_file.shift

      org_and_teams = @excel_file.map do |row|
        app_attrs = header.zip(row).to_h
        [app_attrs['Organisation_name'], app_attrs['team_name']]
      end.uniq

      log_to_process_count(org_and_teams.count)

      org_and_teams.each do |org_name, team_name|
        org = Organisation.where('name ILIKE ?', org_name.strip)&.first
        if org.blank?
          org_not_found_names << org_name
          org_not_found += 1
        else
          team = org.teams.where('name ILIKE ?', team_name)
          if team.present?
            team_already_existed += 1
          else
            # puts team_name.strip
            org.teams.find_or_create_by!(name: team_name.strip, z_team_status: active_team_status)
            counter += 1
          end
        end
      end
      puts "#{org_not_found} organisation(s) NOT found when importing teams!"
      puts "#{team_already_existed} team(s) existed "
      # puts "#{counter} teams would have created"
      puts "#{org_and_teams.count - (counter + team_already_existed)} not processed"
      new_count = Team.count
      created = new_count - existing_count

      puts "Created #{created} teams"
      puts "Can't find these org names!"
      org_not_found_names.uniq.sort.each do |name|
        print "#{name}\n"
      end
    end
  end
end
