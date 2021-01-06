class RemoveAwaitingAccountApprovalProjectStateRowsAndState < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name = 'workflow_states'
  end
  def up
    Workflow::ProjectState.where(state_id: 'AWAITING_ACCOUNT_APPROVAL').each(&:destroy)

    remove_lookup State, 'AWAITING_ACCOUNT_APPROVAL', {}
  end
  
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
