class AddAmendmentWorkflowStateTransitions < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name_prefix = 'workflow_'
  end

  class Transition < ApplicationRecord
    self.table_name_prefix = 'workflow_'

    belongs_to :project_type
  end

  AMEND        = 'AMEND'.freeze
  DPIA_START   = 'DPIA_START'.freeze
  PROJECT_TYPE = ProjectType.find_by!(name: 'Application')

  def change
    add_lookup State, AMEND, {}

    add_lookup Transition, 41, from_state_id: 'CONTRACT_COMPLETED', next_state_id: AMEND,      project_type: PROJECT_TYPE
    add_lookup Transition, 42, from_state_id: 'CONTRACT_REJECTED',  next_state_id: AMEND,      project_type: PROJECT_TYPE
    add_lookup Transition, 43, from_state_id: 'CONTRACT_DRAFT',     next_state_id: AMEND,      project_type: PROJECT_TYPE
    add_lookup Transition, 44, from_state_id: 'DPIA_REJECTED',      next_state_id: AMEND,      project_type: PROJECT_TYPE
    add_lookup Transition, 45, from_state_id: 'DPIA_MODERATION',    next_state_id: AMEND,      project_type: PROJECT_TYPE
    add_lookup Transition, 46, from_state_id: DPIA_START,           next_state_id: AMEND,      project_type: PROJECT_TYPE
    add_lookup Transition, 47, from_state_id: 'CONTRACT_COMPLETED', next_state_id: AMEND,      project_type: PROJECT_TYPE
    add_lookup Transition, 48, from_state_id: AMEND,                next_state_id: DPIA_START, project_type: PROJECT_TYPE
  end
end
