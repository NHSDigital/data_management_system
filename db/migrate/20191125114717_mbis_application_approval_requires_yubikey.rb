# MBIS Application ODR approval - SUBMITTED -> APPROVED transition requires the 2FA check
class MbisApplicationApprovalRequiresYubikey < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'
  end

  def change
    project_type = ProjectType.find_by!(name: 'Project')
    tid = Transition.find_or_create_by!(from_state_id: 'SUBMITTED', next_state_id: 'APPROVED',
                                        project_type_id: project_type.id).id
    change_lookup Transition, tid, {}, { requires_yubikey: true }
  end
end


