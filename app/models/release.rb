class Release < ApplicationRecord
  belongs_to :project
  belongs_to :project_state, class_name: 'Workflow::ProjectState'

  belongs_to_lookup :vat_reg, Lookups::Proposition

  with_options scope: -> { Lookups::Proposition.binary } do
    belongs_to_lookup :income_received,       Lookups::Proposition
    belongs_to_lookup :cost_recovery_applied, Lookups::Proposition
  end

  has_paper_trail

  before_validation :associate_with_project_state

  validates :actual_cost, numericality: true, allow_blank: true

  private

  def associate_with_project_state
    self.project_state ||= project&.current_project_state
  end
end
