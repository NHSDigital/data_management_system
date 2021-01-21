# Class for Auto-transitioning of CAS projects from RENEWAL to ACCOUNT_CLOSED states.
class CasAccountClosure
  MONTHS_ALLOWED_FOR_RENEWAL = 1

  def account_closures
    closable_projects = Project.joins(:current_state).
                        where(workflow_current_project_states: { state_id: 'RENEWAL' }).
                        where('workflow_current_project_states.created_at < ?',
                              MONTHS_ALLOWED_FOR_RENEWAL.months.ago)

    closable_projects.each do |project|
      project.transition_to!(Workflow::State.find('ACCOUNT_CLOSED'))
    end
  end
end
