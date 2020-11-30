class AddMoreCasWorkflowTransitions < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'

    belongs_to :project_type
  end

  def change
    project_type = ProjectType.find_by!(name: 'CAS')
    add_lookup Transition, 82, from_state_id: 'REJECTED', next_state_id: 'DRAFT', project_type: project_type
    add_lookup Transition, 83, from_state_id: 'APPROVED', next_state_id: 'REJECTED', project_type: project_type
    add_lookup Transition, 84, from_state_id: 'REJECTED', next_state_id: 'APPROVED', project_type: project_type
  end
end
