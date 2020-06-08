class PopulateWorkflowState < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name = 'workflow_states'
  end

  def change
    add_lookup State, 'APPROVED', {}
    add_lookup State, 'CLOSED', {}
    add_lookup State, 'DELETED', {}
    add_lookup State, 'DRAFT', {}
    add_lookup State, 'EXPIRED', {}
    add_lookup State, 'LIVE', {}
    add_lookup State, 'REJECTED', {}
    add_lookup State, 'REVIEW', {}
    add_lookup State, 'SUBMITTED', {}
    add_lookup State, 'SUSPENDED', {}
  end
end
