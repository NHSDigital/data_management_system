require 'test_helper'

class ProjectCoreTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:senior_project_user)
    @approved_user = users(:approved_senior_user)
    @admin = users(:admin_user)
    @odr = users(:odr_user)
    @eoi = create_eoi
    @app_man = users(:application_manager_one)
  end

  test 'sign in and visit project page, standard user' do
    sign_in @user
    visit terms_and_conditions_path
    click_on 'Accept'
    visit projects_path
    assert page.has_content?('Notifications')
    visit terms_and_conditions_path
    assert page.has_content?('Terms and Conditions have been accepted')
  end

  test 'sign in and visit project page, odr user' do
    sign_in @odr
    visit terms_and_conditions_path
    click_on 'Accept'
    visit projects_path
    assert page.has_content?('Notifications')
    visit terms_and_conditions_path
    assert page.has_content?('Terms and Conditions have been accepted')
  end

  test 'sign in and visit project page, admin user' do
    sign_in @admin
    visit terms_and_conditions_path
    click_on 'Accept'
    visit projects_path
    assert page.has_content?('Notifications')
    visit terms_and_conditions_path
    assert page.has_content?('Terms and Conditions have been accepted')
  end

  test 'reset project approvals' do
    project = projects(:pending_project)

    sign_in @odr
    visit terms_and_conditions_path
    click_on 'Accept'
    visit project_path(project)
    click_link('Project Details')

    assert_changes -> { project.reload.details_approved } do
      within('#approve_details_status') do
        click_button 'Approve'

        assert has_no_button? 'Approve'
        assert has_text? 'APPROVED'
      end
    end

    accept_prompt do
      click_link('Reset Approvals')
    end

    assert page.has_content?('Project approval details reset')
    refute Project.find_by(name: 'pending_project').details_approved?
  end

=begin
  test 'soft delete a project' do
    sign_in @admin
    visit terms_and_conditions_path
    click_on 'Accept'
    visit project_path(projects(:new_project))
    click_on 'Delete'
    assert page.has_content?('Project was successfully destroyed.')
  end
=end

  test 'should error if no permission to show project' do
    sign_in users(:standard_user_multiple_teams)
    visit terms_and_conditions_path
    click_on 'Accept'
    @project = projects(:approved_project)
    visit project_path(@project)
  end

  test 'successful project allocation' do
    assigned_user = users(:application_manager_two)

    sign_in @odr

    visit terms_and_conditions_path
    click_on 'Accept'

    visit project_path(@eoi)

    assert_changes -> { @eoi.reload.assigned_user } do
      assert_difference 'Notification.count' do
        assert_emails 1 do
          within('#new_project_assignment') do
            select 'Application Manager Two', from: 'Application Manager'
            click_button 'Apply'
          end
        end
      end
    end

    assert_equal project_path(@eoi), current_path
    assert page.has_text? 'EOI was successfully assigned'
    assert_equal assigned_user, @eoi.reload.assigned_user

    open_email assigned_user.email
    assert_not_nil current_email
    assert_equal 'Project Assignment', current_email.subject
  end

  test 'unsuccessful project allocation' do
    Project.any_instance.stubs(save: false)

    sign_in @odr

    visit terms_and_conditions_path
    click_on 'Accept'

    visit project_path(@eoi)

    assert_no_changes -> { @eoi.reload.assigned_user } do
      assert_no_difference 'Notification.count' do
        assert_emails 0 do
          within('#new_project_assignment') do
            select 'Application Manager Two', from: 'Application Manager'
            click_button 'Apply'
          end
        end
      end
    end

    assert page.has_text? 'EOI could not be assigned!'
  end

  test 'should trigger allocation on submission to ODR' do
    Projects::ApplicationManagerAllocatorService.expects(:call)

    project = projects(:pending_delegate_project)

    sign_in users(:delegate_user1)

    visit terms_and_conditions_path
    click_link 'Accept'
    visit project_path(project)

    accept_prompt do
      click_button 'Submit'
    end

    assert find('#project_status').has_text? 'Pending'
  end

  test 'should get dashboard page' do
    sign_in @odr

    visit terms_and_conditions_path
    click_on 'Accept'

    within '.navbar' do
      assert_nothing_raised do
        click_link 'Projects'
      end
    end

    assert_equal dashboard_projects_path, current_path
  end

  test 'should not be able to import application PDF forms without an :application_manager role' do
    sign_in @user

    visit terms_and_conditions_path
    click_on 'Accept'

    visit team_path(teams(:team_two))

    assert_equal team_path(teams(:team_two)), current_path
    assert has_no_button? 'Import'
    assert has_no_field? 'file'
  end

  test 'should be able to import application PDF forms as an :application_manager role' do
    @odr.grants.create!(roleable: SystemRole.fetch(:application_manager))

    sign_in @odr

    visit terms_and_conditions_path
    click_on 'Accept'

    team = teams(:team_two)

    visit team_path(team)
    assert_equal team_path(team), current_path

    click_button 'Import'

    assert_difference -> { team.projects.count } do
      assert_difference -> { ProjectAttachment.count } do
        file = Pathname.new(fixture_path).join('files', 'odr_data_request_form_v5-alpha.6.pdf')

        attach_file(file) do
          find('.glyphicon-inbox').click
        end

        within '#project_header' do
          assert has_text? 'My Test Import Project'
        end
      end
    end
  end

  test 'should provide at least some modicum of feedback when import fails' do
    sign_in @odr

    visit terms_and_conditions_path
    click_on 'Accept'

    team = teams(:team_two)

    visit team_path(team)
    assert_equal team_path(team), current_path

    click_button 'Import'

    # Invalid record(s)...
    assert_no_difference -> { team.projects.count } do
      @odr.grants.where(roleable: SystemRole.fetch(:application_manager)).destroy_all

      file = Pathname.new(fixture_path).join('files', 'odr_data_request_form_v5-alpha.6.pdf')

      attach_file(file) do
        find('.glyphicon-inbox').click
      end

      within_modal do
        assert has_text? 'Could not import file!'
        assert has_text? 'Assigned user is invalid'

        click_button 'OK'
      end
    end

    # Wrong file type...
    assert_no_difference -> { team.projects.count } do
      file = Pathname.new(fixture_path).join('files', 'empty.test')

      attach_file(file) do
        find('.glyphicon-inbox').click
      end

      within_modal do
        assert has_text? 'Could not import file!'
        assert has_text? 'Unpermitted file type'

        click_button 'OK'
      end
    end

    # Bad PDF...
    assert_no_difference -> { team.projects.count } do
      PDF::Reader.any_instance.stubs(:acroform_data).raises(RuntimeError, 'Bang!')
      file = Pathname.new(fixture_path).join('files', 'odr_data_request_form_v5-alpha.6.pdf')

      attach_file(file) do
        find('.glyphicon-inbox').click
      end

      within_modal do
        assert has_text? 'Could not import file!'
        # assert has_text?(/fingerprint.*[0-9a-f]{32}\z/)

        click_button 'OK'
      end
    end
  end

  test 'project dashboard search' do
    sign_in @app_man
    visit dashboard_projects_path

    within('#search-form') do
      fill_in 'search[name]', with: 'oh eye'
      click_button :submit
    end

    assert_equal dashboard_projects_path, current_path
    assert has_no_content? 'My Projects'
    assert has_no_content? 'Assigned Projects'
    assert has_content? 'Unassigned Projects'
    assert has_content? 'All Projects'

    within('#unassigned-projects') do
      assert has_text?('Beside The Seaside')
      assert has_no_text?('MyString')
    end

    within('#all-projects') do
      assert has_text?('Beside The Seaside')
      assert has_no_text?('MyString')
    end
  end

  test 'project dashboard search assigned' do
    eoi = Project.find_by(name: 'E Oh Eye Do Like To Be Beside The Seaside')
    eoi.update_attribute(:assigned_user_id, @app_man.id)

    sign_in @app_man
    visit dashboard_projects_path
    assert has_no_content? 'My Projects'
    assert has_content? 'Assigned Projects'
    assert has_content? 'Unassigned Projects'
    assert has_content? 'All Projects'

    within('#search-form') do
      fill_in 'search[name]', with: 'oh eye'
      click_button :submit
    end

    assert_equal dashboard_projects_path, current_path
    assert has_no_content? 'My Projects'
    assert has_content? 'Assigned Projects'
    assert has_no_content? 'Unassigned Projects'
    assert has_content? 'All Projects'
  end

  test 'project search' do
    sign_in @user
    visit projects_path

    assert has_content? 'Listing Projects'
    assert has_content? 'new_project'

    within('#search-form') do
      fill_in 'search[name]', with: 'string'
      click_button :submit
    end

    assert has_no_content? 'new_project'
    assert has_content? 'MyString'
  end

  test 'should be able to see linked projects' do
    project = projects(:one)
    parent  = projects(:test_application)
    child   = projects(:dummy_project)

    parent.update!(parent: nil, owner: @user)
    project.update!(parent: parent, owner: @user)
    child.update!(parent: project, owner: @user)

    sign_in @user

    visit project_path(project)

    click_link('Related')

    within('h4', text: parent.name) do
      assert has_text?('parent')
      assert has_link?(href: project_path(parent))
    end

    within('h4', text: project.name) do
      assert has_text?('self')
      assert has_link?(href: project_path(project))
    end

    within('h4', text: child.name) do
      assert has_text?('child')
      assert has_link?(href: project_path(child))
    end
  end

  def create_eoi
    eoi = Project.new(project_type: project_types(:eoi),
                      name: 'E Oh Eye Do Like To Be Beside The Seaside',
                      project_purpose: 'Ice Cream',
                      first_contact_date: Date.current - 1.month)
    dataset = Dataset.find_by(name: 'Death Transaction')
    eoi.project_datasets << ProjectDataset.new(dataset: dataset,
                                               terms_accepted: true)
    eoi.team = teams(:team_two)
    eoi.owner = users(:senior_project_user)
    eoi.save!

    eoi.reload
  end
end
