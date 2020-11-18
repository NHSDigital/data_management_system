class AddCasWorkflow < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'

    belongs_to :project_type
  end

  def change
    project_type = ProjectType.find_by!(name: 'CAS')
    add_lookup Transition, 76, from_state_id: 'DRAFT', next_state_id: 'SUBMITTED', project_type: project_type
    add_lookup Transition, 77, from_state_id: 'DRAFT', next_state_id: 'DELETED', project_type: project_type
  end
end
