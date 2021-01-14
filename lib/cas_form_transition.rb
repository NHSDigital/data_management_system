# hopefully remove this once all project_types and transitions are moved to this model and
# use translation fie
class CasFormTransition
  def initialize(transition:)
    @transition = transition
  end

  def text
    lookup[[@transition.from_state_id, @transition.next_state_id]]
  end

  # TODO: define the rest
  def lookup
    {
      %w[REJECTION_REVIEWED DRAFT] => 'Reapply',
      %w[ACCESS_APPROVER_REJECTED SUBMITTED] => 'Return to Access Approval',
      %w[ACCESS_GRANTED DRAFT] => 'Request Access Change',
      %w[ACCOUNT_CLOSED DRAFT] => 'Reapply'
    }
  end
end
