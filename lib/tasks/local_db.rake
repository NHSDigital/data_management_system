# updated 2020-09-17 for ODR workflow only
namespace :local_db do
  task create: %i[create_organisation create_teams create_users]

  task create_organisation: :environment do
    Organisation.find_or_initialize_by(name: 'Local Organisation').tap do |o|
      o.organisation_type = Lookups::OrganisationType.second
      o.country = Lookups::Country.find_by(value: 'UNITED KINGDOM')
      o.save!
    end
  end

  task create_teams: :environment do
    Team.find_or_create_by(name: "ODR Local Team", location: 'The Moon',
                           z_team_status_id: ZTeamStatus.first.id,
                           organisation_id: Organisation.find_by(name: 'Local Organisation').id)
  end

  task create_users: :environment do
    users = [
      { first_name: 'MBIS', last_name: 'ApplicantOne',             username: 'ma1',
        grant: TeamRole.fetch(:mbis_applicant) },
      { first_name: 'MBIS', last_name: 'ApplicantTwo',             username: 'ma2',
        grant: TeamRole.fetch(:mbis_applicant) },
      { first_name: 'MBIS', last_name: 'Delegate',                 username: 'md',
        grant: TeamRole.fetch(:mbis_delegate) },
      { first_name: 'ODR',  last_name: 'ApplicantOne',             username: 'oa1',
        grant: TeamRole.fetch(:odr_applicant) },
      { first_name: 'ODR',  last_name: 'ApplicantTwo',             username: 'oa2',
        grant: TeamRole.fetch(:odr_applicant) },
      { first_name: 'ODR',  last_name: 'ApplicationManagerOne',    username: 'am1',
        grant: SystemRole.fetch(:application_manager) },
      { first_name: 'ODR',  last_name: 'ApplicationManagerTwo',    username: 'am2',
        grant: SystemRole.fetch(:application_manager) },
      { first_name: 'ODR',  last_name: 'SeniorApplicationManager', username: 'sam',
        grant: SystemRole.fetch(:senior_application_manager) },
      { first_name: 'ODR',  last_name: 'ODR',                      username: 'o',
        grant: SystemRole.fetch(:odr) }
    ]
    User.transaction do
      users.each do |user|
        grant = user.delete(:grant)
        new_user = User.new(user).tap do |u|
          u.email = "#{user[:first_name].downcase}.#{user[:last_name].downcase}@phe.gov.uk"
          u.z_user_status = ZUserStatus.first
          u.password = u.password_confirmation = 'let me in'
          u.save(validate: false)
        end
        # build grant
        Grant.new(roleable: grant).tap do |g|
          g.team = local_team if grant.is_a? TeamRole
          g.user = new_user
          g.save!
        end
      end
    end
    print "created #{users.size}.count\n"
  end
  
  def local_team
    Team.find_by(name: 'ODR Local Team')
  end
  
  def find_user(username)
    User.find_by(username: username)
  end
end