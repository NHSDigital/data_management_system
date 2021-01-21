# Class for Auto-transitioning of CAS projects from RENEWAL to ACCOUNT_CLOSED states.
class CasAutomaticAccountClosure
  CLOSE_ACCOUNT_WAIT_TIME = 30.days

  def account_closures
    Project.cas_renewal.each do |project|
      next unless (project.current_state.created_at.to_date +
                   CLOSE_ACCOUNT_WAIT_TIME) <= Time.zone.today

      project.transition_to!(Workflow::State.find('ACCOUNT_CLOSED'))
    end
  end
end
