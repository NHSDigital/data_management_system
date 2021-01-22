require 'test_helper'

class CasAccountClosureTest < ActiveSupport::TestCase
  test 'CAS application moves to account closed after 1 month' do
    project = Project.create(project_type: project_types(:cas), owner: users(:standard_user2))

    project.transition_to!(workflow_states(:submitted))
    # Auto-transitions to ACCESS_GRANTED
    project.transition_to!(workflow_states(:access_approver_approved))
    project.transition_to!(workflow_states(:renewal))

    assert_equal 'RENEWAL', project.current_state.id

    travel_to 10.days.from_now

    klass = CasAccountClosure.new
    klass.account_closures

    project.reload.current_state
    assert_equal 'RENEWAL', project.current_state.id

    travel_to 1.month.from_now

    klass = CasAccountClosure.new
    klass.account_closures

    project.reload.current_state
    assert_equal 'ACCOUNT_CLOSED', project.current_state.id
  end
end
