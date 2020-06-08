class AddApplicationWorkflow < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name = 'workflow_states'
  end

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'

    belongs_to :project_type
  end

  def change
    app = ProjectType.find_or_create_by!(name: 'Application')

    add_lookup State, 'DPIA_START',         {}
    add_lookup State, 'DPIA_REVIEW',        {}
    add_lookup State, 'DPIA_MODERATION',    {}
    add_lookup State, 'DPIA_REJECTED',      {}
    add_lookup State, 'CONTRACT_DRAFT',     {}
    add_lookup State, 'CONTRACT_REJECTED',  {}
    add_lookup State, 'CONTRACT_COMPLETED', {}

    add_lookup Transition, 29, project_type: app, from_state_id: 'DRAFT',             next_state_id: 'DPIA_START'
    add_lookup Transition, 30, project_type: app, from_state_id: 'DPIA_REJECTED',     next_state_id: 'DPIA_START'
    add_lookup Transition, 31, project_type: app, from_state_id: 'CONTRACT_REJECTED', next_state_id: 'DPIA_START'
    add_lookup Transition, 32, project_type: app, from_state_id: 'DPIA_START',        next_state_id: 'DPIA_REVIEW'
    add_lookup Transition, 33, project_type: app, from_state_id: 'DPIA_REVIEW',       next_state_id: 'DPIA_MODERATION'
    add_lookup Transition, 34, project_type: app, from_state_id: 'DPIA_MODERATION',   next_state_id: 'DPIA_REJECTED'
    add_lookup Transition, 35, project_type: app, from_state_id: 'DPIA_MODERATION',   next_state_id: 'CONTRACT_DRAFT'
    add_lookup Transition, 36, project_type: app, from_state_id: 'CONTRACT_DRAFT',    next_state_id: 'CONTRACT_REJECTED'
    add_lookup Transition, 37, project_type: app, from_state_id: 'CONTRACT_DRAFT',    next_state_id: 'CONTRACT_COMPLETED'
  end
end
