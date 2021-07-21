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
