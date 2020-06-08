class PopulateWorkflowTransition < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'

    belongs_to :project_type
  end

  def change
    project = ProjectType.find_by!(name: 'Project')

    add_lookup Transition, 1,  from_state_id: 'DRAFT',     next_state_id: 'REVIEW',    project_type: project
    add_lookup Transition, 2,  from_state_id: 'DRAFT',     next_state_id: 'DELETED',   project_type: project
    add_lookup Transition, 3,  from_state_id: 'DRAFT',     next_state_id: 'EXPIRED',   project_type: project
    add_lookup Transition, 4,  from_state_id: 'REVIEW',    next_state_id: 'DRAFT',     project_type: project
    add_lookup Transition, 5,  from_state_id: 'REVIEW',    next_state_id: 'SUBMITTED', project_type: project
    add_lookup Transition, 6,  from_state_id: 'REVIEW',    next_state_id: 'REJECTED',  project_type: project
    add_lookup Transition, 7,  from_state_id: 'REVIEW',    next_state_id: 'DELETED',   project_type: project
    add_lookup Transition, 8,  from_state_id: 'REVIEW',    next_state_id: 'EXPIRED',   project_type: project
    add_lookup Transition, 9,  from_state_id: 'SUBMITTED', next_state_id: 'DRAFT',     project_type: project
    add_lookup Transition, 10, from_state_id: 'SUBMITTED', next_state_id: 'APPROVED',  project_type: project
    add_lookup Transition, 11, from_state_id: 'SUBMITTED', next_state_id: 'REJECTED',  project_type: project
    add_lookup Transition, 12, from_state_id: 'SUBMITTED', next_state_id: 'DELETED',   project_type: project
    add_lookup Transition, 13, from_state_id: 'SUBMITTED', next_state_id: 'EXPIRED',   project_type: project
    add_lookup Transition, 14, from_state_id: 'APPROVED',  next_state_id: 'SUBMITTED', project_type: project
    add_lookup Transition, 15, from_state_id: 'APPROVED',  next_state_id: 'DELETED',   project_type: project
    add_lookup Transition, 16, from_state_id: 'APPROVED',  next_state_id: 'EXPIRED',   project_type: project
    add_lookup Transition, 17, from_state_id: 'REJECTED',  next_state_id: 'DRAFT',     project_type: project
    add_lookup Transition, 18, from_state_id: 'REJECTED',  next_state_id: 'DELETED',   project_type: project
    add_lookup Transition, 19, from_state_id: 'REJECTED',  next_state_id: 'EXPIRED',   project_type: project
    add_lookup Transition, 20, from_state_id: 'EXPIRED',   next_state_id: 'DELETED',   project_type: project
  end
end
