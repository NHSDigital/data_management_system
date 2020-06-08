namespace :grants do
  task migrate: :environment do
    migrate_memberships
  end

  # project_type: 'Project 'senior: true' => mbis_applicant
  # project_type: 'Project 'senior: false' => NEW Member
  # project_type: 'EOI     'senior: true' => odr_applicant
  # project_type: 'EOI     'senior: false' => NEW ROLE
  def migrate_memberships
    Membership.all.each do |m|
      # team role
      applicants = [TeamRole.fetch(:mbis_applicant), TeamRole.fetch(:odr_applicant)]
      roles = m.senior ? applicants : TeamRole.read_only
      roles.each do |role|
        Grant.create!(roleable: role, user: User.find(m.user_id), team_id: m.team_id)
      end
    end
    # add a project.senior_user_id as an owner grant
    # senior => owner
    # other  => read_only

    ProjectMembership.all.each do |pm|
      role = if pm.project.senior_user_id == pm.membership.user_id
               ProjectRole.fetch(:owner)
             else
               ProjectRole.fetch(:read_only)
             end
      Grant.create!(user: User.find(pm.membership.user_id), roleable: role,
                    project_id: pm.project_id)
    end
    Project.update_all(senior_user_id: nil)
  end

  # checkout 4a931763 and run
  desc 'create old structure migration test data'
  task create: :environment do
    raise unless Rails.env.development?

    Organisation.transaction do
      create_users
      create_orgs
      create_teams
      create_team_memberships
      create_projects
    end
  end

  task destroy_dummy: :environment do
    user_ids = User.where(first_name: %w[Random Dele]).map(&:id)
    ProjectMembership.where(membership_id: Membership.where(user_id: user_ids)).delete_all
    Membership.where(user_id: user_ids).delete_all
    Grant.where(user_id: user_ids).delete_all
    Organisation.where(name: ['Organ 1', 'Organ 2']).each do |org|
      org.teams.each do |team|
        team.projects.destroy_all
      end
    end
    Organisation.where(name: ['Organ 1', 'Organ 2']).each(&:destroy)
    User.where(first_name: %w[Random Dele]).each(&:destroy)
  end

  def create_users
    %w[1 2].each do |n|
      User.create!(first_name: 'Dele', last_name: "Gate #{n}",
                   username: "del#{n}", email: "del#{n}@phe.gov.uk",
                   z_user_status: ZUserStatus.find_by(name: 'Active'))

    end
    %w[100 101 102 103 104 105].each do |n|
      User.create!(first_name: 'Random', last_name: "User #{n}",
                   username: "u#{n}", email: "a_user#{n}@phe.gov.uk",
                   z_user_status: ZUserStatus.find_by(name: 'Active'))
    end
    User.last(8).each do |u|
      u.password = 'let me in'
      u.save!(validate: false)
    end
  end

  def create_orgs
    %w[1 2].each do |n|
      o = Organisation.new(name: "Organ #{n}")
      o.country = Lookups::Country.all.sample
      o.organisation_type = Lookups::OrganisationType.where.not(value: 'Other').sample
      o.save!
    end
  end

  def create_teams
    Organisation.where(name: ['Organ 1', 'Organ 2']).each do |org|
      %w[1 2].each do |n|
        team = Team.new(name: "#{org.name} Team #{n}", location: 'TEST')
        team.organisation = org
        team.datasets << mbis_datasets
        team.z_team_status = ZTeamStatus.find_by(name: 'Active')
        team.save!
      end
    end
  end

  def mbis_datasets
    names = ['Birth Transaction', 'Births Gold Standard',
             'Death Transaction', 'Deaths Gold Standard']
    Dataset.where(name: names).sample(2)
  end

  def create_team_memberships
    Organisation.where(name: ['Organ 1', 'Organ 2']).each do |org|
      org.teams.each do |team|
        User.where(first_name: 'Random').sample(3).each_with_index do |user, i|
          senior = i.zero? ? true : false
          Membership.create!(team: team, user_id: user.id, senior: senior)
        end
      end
    end
  end

  def create_projects
    Organisation.where(name: ['Organ 1', 'Organ 2']).each do |org|
      org.teams.each do |team|
        names = %w[santa cafe tesco lidl]
        # MBIS PROJECTS
        names.sample(2).each do |name|
          pj = Project.new(project_type: ProjectType.find_by(name: 'Project'))
          pj.name = "Project #{name}"
          pj.start_data_date = Date.current - 30.days
          pj.end_data_date   = Date.current
          pj.team_dataset = team.team_datasets.sample
          pj.team = team
          pj.project_purpose = 'TEST'
          pj.senior_user = team.senior_members.first
          pj.save!
          pj.reload

          membership = Membership.find_by(
            user_id: (team.members - team.senior_members).sample.id,
            team_id: team.id
          )
          ProjectMembership.create!(
            membership_id: membership.id,
            project: pj
          )
        end
        # EOIs
        names.sample(2).each do |name|
          eoi = Project.new(project_type: ProjectType.find_by(name: 'EOI'))
          eoi.name = "EOI #{name}"
          eoi.team = team
          eoi.project_purpose = 'EOI TEST'
          eoi.senior_user = team.senior_members.first
          eoi.save!

          eoi.reload
          membership = Membership.find_by(
            user_id: (team.members - team.senior_members).sample.id,
            team_id: team.id
          )
          ProjectMembership.create!(
            membership_id: membership.id,
            project: eoi
          )
        end
      end
    end
  end
end
