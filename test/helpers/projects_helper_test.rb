require 'test_helper'

# Tests functionality of ProjectsHelper.
class ProjectsHelperTest < ActionView::TestCase
  def setup
    @project = create_project(parent: projects(:one))
    @project.reload_current_state
  end

  test 'project_status_label' do
    expected = '<span class="label label-warning" id="project_status">New</span>'
    assert_dom_equal expected, project_status_label(@project, id: :project_status)
  end

  test 'transition_button' do
    state = @project.transitionable_states.find('DELETED')

    expected = '<button name="button" type="submit" class="btn btn-danger">' \
               '<span class="glyphicon glyphicon-trash"></span> Delete</button>'

    assert_dom_equal expected, transition_button(@project, state)

    # Check non-cas transition buttons still working as expected
    @project.transition_to!(workflow_states(:review))

    state = @project.transitionable_states.find('DRAFT')

    expected = '<button name="button" type="submit" class="btn btn-default">' \
               'Return to draft</button>'

    assert_dom_equal expected, transition_button(@project, state)
  end

  test 'cas transition buttons' do
    project = create_project(project_type: project_types(:cas), project_purpose: 'test')

    project.transition_to!(workflow_states(:submitted))
    project.transition_to!(workflow_states(:access_approver_rejected))

    # Check cas transition buttons normally get text from translation file.
    state = project.transitionable_states.find('REJECTION_REVIEWED')

    expected = '<button name="button" type="submit" class="btn btn-danger">' \
               '<span class="glyphicon glyphicon-thumbs-down"></span> Rejection Confirmed</button>'

    assert_dom_equal expected, transition_button(project, state)

    # Check some cas transition buttons get text from cas_form_transition.rb
    state = project.transitionable_states.find('SUBMITTED')

    expected = '<button name="button" type="submit" class="btn btn-success">' \
               'Return to Access Approval</button>'

    assert_dom_equal expected, transition_button(project, state)
  end

  test 'requires_modal_comments_for_transition_to?' do
    assert requires_modal_comments_for_transition_to?(workflow_states(:rejected))
    assert requires_modal_comments_for_transition_to?(workflow_states(:dpia_rejected))
    assert requires_modal_comments_for_transition_to?(workflow_states(:contract_rejected))
    assert requires_modal_comments_for_transition_to?(workflow_states(:access_approver_approved))
    assert requires_modal_comments_for_transition_to?(workflow_states(:access_approver_rejected))
    refute requires_modal_comments_for_transition_to?(workflow_states(:submitted))
  end

  test 'friendly project type label' do
    assert_equal 'ODR EOI', friendly_type_name('EOI')
    assert_equal 'ODR Application', friendly_type_name('Application')
    assert_equal 'MBIS Application', friendly_type_name('Project')
    assert_equal 'Something not in en.yml', friendly_type_name('Something not in en.yml')
  end

  test 'odr_reference' do
    assert_nil odr_reference(@project)

    @project.project_type.stubs(name: 'Application')
    assert_equal "<small>ODR Reference: #{@project.id}</small>", odr_reference(@project)
  end
end
