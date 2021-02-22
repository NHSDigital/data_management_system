require 'test_helper'

class CasRenewalMidpointNotifierTest < ActiveSupport::TestCase
  test 'CAS application notifier and mailer sent when at renewal for 15 days' do
    project = create_cas_project(owner: users(:standard_user2))

    project.transition_to!(workflow_states(:submitted))
    # Auto-transitions to ACCESS_GRANTED
    project.transition_to!(workflow_states(:access_approver_approved))
    project.transition_to!(workflow_states(:renewal))

    assert_equal 'RENEWAL', project.current_state.id

    travel_to 14.days.from_now

    klass = CasRenewalMidpointNotifier.new
    klass.renewal_notify

    project.reload.current_state
    assert_equal 'RENEWAL', project.current_state.id
    assert_equal 0, Notification.by_title('CAS Access Urgently Requires Renewal').count

    travel_to 1.day.from_now

    klass = CasRenewalMidpointNotifier.new
    klass.renewal_notify

    project.reload.current_state
    assert_equal 'RENEWAL', project.current_state.id
    assert_equal 1, Notification.by_title('CAS Access Urgently Requires Renewal').count
  end
end
