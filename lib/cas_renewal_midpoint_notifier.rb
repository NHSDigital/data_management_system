# Class for Auto-transitioning of CAS projects from ACCESS_GRANTED to RENEWAL states.
class CasRenewalMidpointNotifier
  DAYS_BEFORE_NOTIFIED = 15

  def renewal_notify
    renewable_projects = Project.joins(:current_state).
                         where(workflow_current_project_states: { state_id: 'RENEWAL' }).
                         where('date(workflow_current_project_states.created_at) = ?',
                               DAYS_BEFORE_NOTIFIED.days.ago.to_date)

    renewable_projects.each do |project|
      CasNotifier.requires_renewal_midpoint_to_user(project)
      CasMailer.with(project: project).send(:requires_renewal_midpoint_to_user).deliver_now
    end
  end
end
