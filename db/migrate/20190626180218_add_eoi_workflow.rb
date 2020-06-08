class AddEoiWorkflow < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name = 'workflow_states'
  end

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'

    belongs_to :project_type
  end

  def change
    eoi = ProjectType.find_by!(name: 'EOI')

    add_lookup State, 'COMPLETED', {}

    add_lookup Transition, 21, project_type: eoi, from_state_id: 'DRAFT',     next_state_id: 'SUBMITTED'
    add_lookup Transition, 22, project_type: eoi, from_state_id: 'DRAFT',     next_state_id: 'DELETED'
    add_lookup Transition, 23, project_type: eoi, from_state_id: 'SUBMITTED', next_state_id: 'DRAFT'
    add_lookup Transition, 24, project_type: eoi, from_state_id: 'SUBMITTED', next_state_id: 'APPROVED'
    add_lookup Transition, 25, project_type: eoi, from_state_id: 'SUBMITTED', next_state_id: 'REJECTED'
    add_lookup Transition, 26, project_type: eoi, from_state_id: 'APPROVED',  next_state_id: 'COMPLETED'
    add_lookup Transition, 27, project_type: eoi, from_state_id: 'APPROVED',  next_state_id: 'DELETED'
    add_lookup Transition, 28, project_type: eoi, from_state_id: 'REJECTED',  next_state_id: 'DELETED'
  end
end
