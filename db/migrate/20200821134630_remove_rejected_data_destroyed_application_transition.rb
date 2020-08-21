class RemoveRejectedDataDestroyedApplicationTransition < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name_prefix = 'workflow_'
  end

  class Transition < ApplicationRecord
    self.table_name_prefix = 'workflow_'

    belongs_to :project_type
  end

  PROJECT_TYPE = ProjectType.find_by!(name: 'Application')

  def change
    remove_lookup Transition, 76, from_state_id: 'REJECTED', next_state_id: 'DATA_DESTROYED', project_type: PROJECT_TYPE
  end
end
