require 'test_helper'

class WorkflowTest < ActionDispatch::IntegrationTest
  test 'should prompt for Yubikey when performing a protected transition' do
    Workflow::Transition.update_all(requires_yubikey: true)

    project = projects(:one)

    project.update(details_approved: true, members_approved: true, legal_ethical_approved: true)
    project.project_nodes.update_all(approved: true)

    sign_in users(:odr_user)

    visit terms_and_conditions_path
    click_on 'Accept'

    visit project_path(project)
    assert_equal project_path(project), current_path

    assert_no_difference -> { project.project_states.count } do
      accept_prompt do
        click_button 'Approve'
      end

      assert has_text? 'Authentication Required'
    end
  end

  test 'should not prompt for Yubikey when performing an unprotected transition' do
    Workflow::Transition.update_all(requires_yubikey: false)

    project = projects(:one)

    project.update(details_approved: true, members_approved: true, legal_ethical_approved: true)
    project.project_nodes.update_all(approved: true)

    sign_in users(:odr_user)

    visit terms_and_conditions_path
    click_on 'Accept'

    visit project_path(project)
    assert_equal project_path(project), current_path

    assert_difference -> { project.project_states.count } do
      accept_prompt do
        click_button 'Approve'
      end

      within('#project_status') do
        assert has_text?('APPROVED')
      end

      assert has_no_text? 'Authentication Required'
    end
  end

  test 'state changes trigger email notifications' do
    project    = create_project
    user       = project.owner
    other_user = users(:standard_user1)

    # The factory user doesn't seem to have an appropriate team applicant role?
    user.grants.create!(roleable: team_roles(:mbis_applicant), team: project.team)

    project.grants.create!(user: other_user, roleable: project_roles(:contributor))

    sign_in user

    visit project_path(project)

    within('#project_header') do
      accept_confirm do
        click_button 'Submit for Delegate Approval'
      end
    end

    assert has_no_button?('Submit for Delegate Approval')

    assert_enqueued_email_with ProjectsMailer, :state_changed, args: {
      project:      project,
      user:         other_user,
      current_user: user
    }

    # Sends to all project users, except user that initiated the transition (and possibly some
    # other edge case exceptions, but shhhh...)
    refute_enqueued_email_with ProjectsMailer, :state_changed, args: {
      project:      project,
      user:         project.owner,
      current_user: user
    }
  end
end
