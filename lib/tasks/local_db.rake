namespace :local_db do
  task create: %i[create_organisation create_teams create_users add_some_grants]

  task create_organisation: :environment do
    o = Organisation.new(name: 'Unorganised')
    o.organisation_type = Lookups::OrganisationType.second
    o.country = Lookups::Country.find_by(value: 'UNITED KINGDOM')
    o.save!
  end

  task create_teams: :environment do
    %w[A B C D].each do |name|
      Team.create!(name: "#{name} Team", location: 'The Moon',
                   z_team_status_id: ZTeamStatus.second.id,
                   organisation_id: Organisation.first.id)
    end
  end

  task create_users: :environment do
    names = [
      %w[Read Only ro],
      %w[MBIS Senior1 s1],
      %w[MBIS Senior2 s2],
      %w[MBIS Senior3 s3],
      %w[MBIS Delegate d1],
      %w[App Man a1],
      %w[OH DEAR o]
    ]
    names.each do |name|
      u = User.new(first_name: name.first, last_name: name.second, username: name.last)
      u.email = "#{name.last}@phe.gov.uk"
      u.save!
      u.reload
    end
  end
  
  task add_some_grants: :environment do
    # TODO: this team role is not right
    User.where(username: %w[ro s1 s2 s3]).each do |user|
      grant = Grant.new(user_id: user.id, team_id: Team.find_by(name: 'A Team').id, roleable: TeamRole.read_only)
      grant.save!
    end
    [Project.first, Project.last].each do |project|
      Grant.create!(user_id: find_user('s1').id, project_id: project.id, roleable: ProjectRole.owner)
    end
    [Project.second, Project.third].each do |project|
      Grant.create!(user_id: find_user('s2').id, project_id: project.id, roleable: ProjectRole.owner)
    end
  end
  
  def find_user(username)
    User.find_by(username: username)
  end
end