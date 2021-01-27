class RemoveCasDeleteTransition < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'

    belongs_to :project_type
  end

  def change
    remove_lookup Transition, 77, from_state_id: 'DRAFT', next_state_id: 'DELETED', project_type: ProjectType.find_by!(name: 'CAS')
  end
end
