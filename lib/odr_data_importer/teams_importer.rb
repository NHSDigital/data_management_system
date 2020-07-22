module OdrDataImporter
  module TeamsImporter
    def import_teams
      existing_count = Team.count
      active_team_status = ZTeamStatus.find_by(name: 'Active')

      @excel_file.shift # remove headers

      @excel_file.each do |_, org_name, team_name|
        org = Organisation.where('name ILIKE ?', org_name.strip)&.first
        next if org.blank?

        team = org.teams.where('name ILIKE ?', team_name)
        next if team.present?

        org.teams.find_or_create_by!(name: team_name.strip, z_team_status: active_team_status)
      end

      new_count = Team.count
      created = new_count - existing_count

      puts "Created #{created} teams"
    end
  end
end
