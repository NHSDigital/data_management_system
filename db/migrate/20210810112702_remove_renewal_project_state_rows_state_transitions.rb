class RemoveRenewalProjectStateRowsStateTransitions < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name = 'workflow_states'
  end

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'

    belongs_to :project_type
  end

  def up
    project_type = ProjectType.find_by!(name: 'CAS')

    remove_lookup Transition, 82, from_state_id: 'ACCESS_GRANTED', next_state_id: 'RENEWAL', project_type: project_type
    remove_lookup Transition, 83, from_state_id: 'RENEWAL', next_state_id: 'ACCESS_GRANTED', project_type: project_type
    remove_lookup Transition, 84, from_state_id: 'RENEWAL', next_state_id: 'ACCOUNT_CLOSED', project_type: project_type

    Workflow::ProjectState.where(state_id: 'RENEWAL').each(&:destroy)

    remove_lookup State, 'RENEWAL', {}
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
