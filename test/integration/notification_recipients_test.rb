require 'test_helper'

# Tests that accounts are locked after a number of failed login attempts
# Not sure how this got so complicated - but for each email type we do
# minimum needed to fire the email
# then check the right users have a record in user_notifications
# assumed that after_Create send_mail in user_notifications does the rest
class NotificationRecipientsTest < ActionDispatch::IntegrationTest
  def setup
    @admin_users = User.administrators.collect(&:id).sort
    @odr_users = User.odr_users.collect(&:id).sort
  end

  test 'user created and edited notifications' do
    # ONLY ADMIN USERS SHOULD BE NOTIFIED
    assert_difference('Notification.count', 1) do
      @user = create_user(email: 'new_user_notificaion@phe.gov.uk')
    end
    assert_equal Notification.last.title, 'New user added'
    # all the users for the last notification should be admins AND ONLY admins
    assert_equal Notification.last.users.collect(&:id).sort, @admin_users
    # now lets test update
    assert_difference('Notification.count', 1) do
      @user.notes = 'Updated the notes for this user'
      @user.save
    end
    assert_equal Notification.last.title, 'User details have been updated'
    # all the users for the last notification should be admins AND ONLY admins
    assert_equal Notification.last.users.collect(&:id).sort, @admin_users
  end

  test 'team created and edited notifications' do
    # initial creation of team wont sent an email as it is not active
    assert_difference('Notification.count', 0) do
      @team = create_team(name: 'Test notifications for create and edit team', z_team_status_id: 3)
    end

    @team.grants.create!(user: users(:standard_user2), roleable: TeamRole.fetch(:mbis_applicant))
    @team.z_team_status_id = ZTeamStatus.where(name: 'Active').first.id
    assert_difference('Notification.count', 1) do
      @team.save!
    end
    assert_equal Notification.last.title, 'New team created in MBIS : Test notifications for create and edit team'
    users_notified = Notification.last.users.collect(&:id).sort
    # team_memberships include senior and delegates
    users_who_should_be_notified = [@admin_users, @team.users.collect(&:id) ].flatten.uniq.sort
    assert_equal users_notified, users_who_should_be_notified
    # should not go to odr - & is intersect
    assert (users_notified & @odr_users).empty?

    # assert_equal Notification.last.users.collect(&:id).sort, User.administrators.collect(&:id).sort
    # now lets test update
    assert_difference('Notification.count', 1) do
      @team.location = 'A new team location'
      @team.save
    end
    assert_equal Notification.last.title, "Team 'Test notifications for create and edit team' edited : "
    users_notified = Notification.last.users.collect(&:id).sort
    users_who_should_be_notified = [@admin_users, @team.users.collect(&:id) ].flatten.uniq.sort
    assert_equal users_notified, users_who_should_be_notified
    # should not go to odr - & is intersect
    assert (users_notified & @odr_users).empty?
  end

  test 'project created notifications' do
    email_received('admin',0)
    email_received('senior',1)
    email_received('delegate',1)
    email_received('member',1)
    email_received('odr',1)
  end

  test 'project edited notifications' do
    email_received('admin',0)
    email_received('senior',1)
    email_received('delegate',1)
    email_received('member',1)
    email_received('odr',1)
  end

  test 'project submitted to delegate' do
    delegate_setup
    project = @submit_to_delegate_project
    project.project_nodes.find_each do |node|
      project.project_comments.create(user: project.owner, project_node: node, comment: 'Justify!!')
    end

    sign_in project.owner

    visit terms_and_conditions_path
    click_link 'Accept'
    
    visit project_path(project)

    assert_difference('Notification.count', 1) do
      accept_prompt do
        click_button 'Submit'
      end

      assert find('#project_status').has_text? 'Delegate Approval'
    end

    assert_equal 'notification_project_delegate_project - needs approving', Notification.last.title
    users_notified = Notification.last.users.collect(&:id).sort
    users_who_should_be_notified = project.team.delegate_users.collect(&:id).flatten.uniq.sort
    assert_equal users_notified, users_who_should_be_notified
  end

  test 'project submitted to odr' do
    project = projects(:pending_delegate_project)

    sign_in users(:delegate_user1)

    visit terms_and_conditions_path
    click_link 'Accept'

    visit project_path(project)

    assert_difference('Notification.count', 1) do
      accept_prompt do
        click_button 'Submit'
      end

      assert find('#project_status').has_text? 'Pending'
    end

    assert_equal 'pending_delegate_project - has been submitted for approval', Notification.last.title
    users_notified = Notification.last.users.collect(&:id).sort
    users_who_should_be_notified = project.users.map(&:id).uniq
    users_who_should_be_notified += SystemRole.fetch(:odr).users.pluck(:id)
    assert_equal users_notified, users_who_should_be_notified.sort
  end

  test 'project approved by odr' do
    email_received('admin',0)
    email_received('senior',1)
    email_received('delegate',1)
    email_received('member',1)
    email_received('odr',0)
  end

  test 'project about to expire' do
    project = projects(:approved_project).dup
    project.name = 'about to expire'
    project.start_data_date = Time.zone.now
    project.end_data_date = Time.zone.today + 14.days
    project.project_datasets << accepted_dataset(projects(:approved_project).datasets.first)
    project.owner = projects(:approved_project).owner
    project.save
    assert_difference('Notification.count', 1) do
      Project.check_for_expiring_projects
    end
    assert_equal Notification.last.title, "about to expire - Will expire in 14 days"
    # all the users for the last notification should be admins AND ONLY admins
    users_notified = Notification.last.users.collect(&:id).sort

    project.team.delegate_users.map do |delegate|
    end
    users_who_should_be_notified =
      [@odr_users, project.team.delegate_users.collect(&:id),
       project.users.collect(&:id)].flatten.uniq.sort
    assert_equal users_notified, users_who_should_be_notified
    # should not go to admin - & is intersect
    assert (users_notified & @admin_users).empty?
  end

  test 'project set to expired' do
    project = projects(:approved_project).dup
    project.name = 'expires today'
    project.start_data_date = Time.zone.now - 1.month
    project.end_data_date = Time.zone.today
    project.owner = projects(:approved_project).owner
    projects(:approved_project).datasets.each do |dataset|
      project.project_datasets << accepted_dataset(dataset)
    end
    project.save!
    assert_difference('Notification.count', 1) do
      Project.check_and_set_expired_projects
    end
    assert_equal Notification.last.title, "expires today - Expired"
    users_notified = Notification.last.users.collect(&:id).sort
    users_who_should_be_notified =
      [@odr_users, project.team.delegate_users.collect(&:id),
       project.users.collect(&:id)].flatten.uniq.sort
    assert_equal users_notified, users_who_should_be_notified
    # should not go to admin - & is intersect
    assert (users_notified & @admin_users).empty?
  end

  test 'user password reset request' do
    @user = users(:standard_user_one_team)
    visit root_path
    # assert_difference('Notification.count', 1) do
      click_on 'Forgot your password?'
      fill_in 'Email', with: @user.email
      click_on 'Send me reset password instructions'
    # end
    assert_equal Notification.last.title, "User has forgotten password",
    users_notified = Notification.last.users.collect(&:id).sort
    # only admin users should action password reset procedures
    users_who_should_be_notified = [@admin_users].flatten.uniq.sort
    assert_equal users_notified, users_who_should_be_notified
  end

  test 'user forgot password' do
  end

  def email_received(user_type, number_of_emails)
    true
  end
  
  private
  
  def delegate_setup
    @applicant = build_user(username: 'notification_project_delegate_team_applicant',
                            email: 'notification_project_delegate_team_applicant@phe.gov.uk')

    @delegate = build_user(username: 'notification_project_delegate_team_delegate',
                           email: 'notification_project_delegate_team_delegate@phe.gov.uk')

    team_grants = [
      Grant.new(roleable: TeamRole.fetch(:mbis_delegate), user: @delegate, team: @delegate_team),
      Grant.new(roleable: TeamRole.fetch(:mbis_applicant), user: @applicant, team: @delegate_team)
    ]
    team_options = { name: 'notification_project_delegate_team',
                     grants: team_grants }

    @submit_to_delegate_team = create_team(team_options)
        
    any_dataset = accepted_dataset(project_types(:project).datasets.first)
    project_options = { name: 'notification_project_delegate_project',
                        project_type: project_types(:project),
                        start_data_date: DateTime.current + 6.months,
                        end_data_date: DateTime.current + 7.months,
                        team: @submit_to_delegate_team,
                        owner: @applicant,
                        project_datasets: [any_dataset] }

    @submit_to_delegate_project = Project.create!(project_options)
  end
end
