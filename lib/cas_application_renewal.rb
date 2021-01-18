class CasApplicationRenewal
  def initialize
  end

  RENEWAL_AFTER = 1.year

  def renewals
    potential_renewals = Project.cas_access_granted
    potential_renewals.each do |project|
      next unless (project.current_state.created_at.to_date + RENEWAL_AFTER) <= Date.today

      project.transition_to!(Workflow::State.find('RENEWAL'))
    end
  end
end

