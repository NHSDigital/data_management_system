class AddCasWorkflowExtra < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name = 'workflow_states'
  end

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'

    belongs_to :project_type
  end

  def change
    project_type = ProjectType.find_by!(name: 'CAS')

    add_lookup State, 'AWAITING_ACCOUNT_APPROVAL', {}
    add_lookup State, 'ACCESS_GRANTED', {}

    add_lookup Transition, 78, from_state_id: 'SUBMITTED', next_state_id: 'AWAITING_ACCOUNT_APPROVAL', project_type: project_type
    add_lookup Transition, 79, from_state_id: 'AWAITING_ACCOUNT_APPROVAL', next_state_id: 'APPROVED', project_type: project_type
    add_lookup Transition, 80, from_state_id: 'AWAITING_ACCOUNT_APPROVAL', next_state_id: 'REJECTED', project_type: project_type
    add_lookup Transition, 81, from_state_id: 'APPROVED', next_state_id: 'ACCESS_GRANTED', project_type: project_type
  end
end
