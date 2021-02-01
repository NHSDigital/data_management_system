# Class for Auto-transitioning of CAS projects from ACCESS_GRANTED to RENEWAL states.
class CasApplicationRenewal
  MONTHS_BEFORE_RENEWAL = 11

  def renewals
    renewable_projects = Project.joins(:current_state).
                         where(workflow_current_project_states: { state_id: 'ACCESS_GRANTED' }).
                         where('workflow_current_project_states.created_at < ?',
                               MONTHS_BEFORE_RENEWAL.months.ago)

    renewable_projects.each { |project| project.transition_to!(Workflow::State.find('RENEWAL')) }
  end
end
