# Class for Auto-transitioning of CAS projects from ACCESS_GRANTED to RENEWAL states.
class CasApplicationRenewal
  RENEWAL_WAIT_TIME = 1.year

  def renewals
    Project.cas_access_granted.each do |project|
      next unless (project.current_state.created_at.to_date + RENEWAL_WAIT_TIME) <= Time.zone.today

      project.transition_to!(Workflow::State.find('RENEWAL'))
    end
  end
end
