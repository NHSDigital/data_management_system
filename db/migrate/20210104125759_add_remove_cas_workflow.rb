class AddRemoveCasWorkflow < ActiveRecord::Migration[6.0]
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

    remove_lookup Transition, 78, from_state_id: 'SUBMITTED', next_state_id: 'AWAITING_ACCOUNT_APPROVAL', project_type: project_type
    remove_lookup Transition, 79, from_state_id: 'AWAITING_ACCOUNT_APPROVAL', next_state_id: 'APPROVED', project_type: project_type
    remove_lookup Transition, 80, from_state_id: 'AWAITING_ACCOUNT_APPROVAL', next_state_id: 'REJECTED', project_type: project_type
    remove_lookup Transition, 81, from_state_id: 'APPROVED', next_state_id: 'ACCESS_GRANTED', project_type: project_type
    remove_lookup Transition, 82, from_state_id: 'REJECTED', next_state_id: 'DRAFT', project_type: project_type
    remove_lookup Transition, 83, from_state_id: 'APPROVED', next_state_id: 'REJECTED', project_type: project_type
    remove_lookup Transition, 84, from_state_id: 'REJECTED', next_state_id: 'APPROVED', project_type: project_type

    add_lookup State, 'ACCESS_APPROVER_APPROVED', {}
    add_lookup State, 'ACCESS_APPROVER_REJECTED', {}
    add_lookup State, 'RENEWAL', {}
    add_lookup State, 'ACCOUNT_CLOSED', {}
    add_lookup State, 'REJECTION_REVIEWED', {}

    add_lookup Transition, 78, from_state_id: 'SUBMITTED', next_state_id: 'DRAFT', project_type: project_type
    add_lookup Transition, 79, from_state_id: 'SUBMITTED', next_state_id: 'ACCESS_APPROVER_APPROVED', project_type: project_type
    add_lookup Transition, 80, from_state_id: 'SUBMITTED', next_state_id: 'ACCESS_APPROVER_REJECTED', project_type: project_type
    add_lookup Transition, 81, from_state_id: 'ACCESS_APPROVER_APPROVED', next_state_id: 'ACCESS_GRANTED', project_type: project_type
    add_lookup Transition, 82, from_state_id: 'ACCESS_GRANTED', next_state_id: 'RENEWAL', project_type: project_type
    add_lookup Transition, 83, from_state_id: 'RENEWAL', next_state_id: 'ACCESS_GRANTED', project_type: project_type
    add_lookup Transition, 84, from_state_id: 'RENEWAL', next_state_id: 'ACCOUNT_CLOSED', project_type: project_type
    add_lookup Transition, 85, from_state_id: 'ACCESS_GRANTED', next_state_id: 'ACCOUNT_CLOSED', project_type: project_type
    add_lookup Transition, 86, from_state_id: 'ACCESS_GRANTED', next_state_id: 'DRAFT', project_type: project_type
    add_lookup Transition, 87, from_state_id: 'ACCESS_APPROVER_REJECTED', next_state_id: 'REJECTION_REVIEWED', project_type: project_type
    add_lookup Transition, 88, from_state_id: 'ACCESS_APPROVER_REJECTED', next_state_id: 'SUBMITTED', project_type: project_type
    add_lookup Transition, 89, from_state_id: 'REJECTION_REVIEWED', next_state_id: 'DRAFT', project_type: project_type
    add_lookup Transition, 90, from_state_id: 'ACCOUNT_CLOSED', next_state_id: 'DRAFT', project_type: project_type
  end
end
