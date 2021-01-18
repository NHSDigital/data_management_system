class CasAutomaticAccountClosure
  def initialize
  end

  CLOSE_ACCOUNT_AFTER = 30.days

  def account_closures
    potential_closures = Project.cas_renewal
    potential_closures.each do |project|
      next unless (project.current_state.created_at.to_date + CLOSE_ACCOUNT_AFTER) <= Date.today

      project.transition_to!(Workflow::State.find('ACCOUNT_CLOSED'))
    end
  end
end
