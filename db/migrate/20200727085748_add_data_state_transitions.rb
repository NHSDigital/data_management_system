class AddDataStateTransitions < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name_prefix = 'workflow_'
  end

  class Transition < ApplicationRecord
    self.table_name_prefix = 'workflow_'

    belongs_to :project_type
  end

  AMEND            = 'AMEND'.freeze
  DATA_RELEASED    = 'DATA_RELEASED'.freeze
  DATA_DESTROYED   = 'DATA_DESTROYED'.freeze
  PROJECT_TYPE     = ProjectType.find_by!(name: 'Application')

  def change
    add_lookup State, DATA_RELEASED, {}
    add_lookup State, DATA_DESTROYED, {}

    add_lookup Transition, 50, from_state_id: 'CONTRACT_COMPLETED', next_state_id: DATA_RELEASED,      project_type: PROJECT_TYPE
    add_lookup Transition, 51, from_state_id: 'DATA_RELEASED',      next_state_id: DATA_DESTROYED,      project_type: PROJECT_TYPE
    add_lookup Transition, 52, from_state_id: 'DATA_RELEASED',      next_state_id: AMEND,      project_type: PROJECT_TYPE
  end
end
