require 'migration_helper'

class RemoveEoiApprovedCompletedTransition < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'
  end

  def change
    project_type = ProjectType.find_or_create_by!(name: 'EOI')
    transition = Transition.find_by(from_state_id: 'APPROVED', next_state_id: 'COMPLETED',
                                    project_type_id: project_type.id)

    remove_lookup Transition, transition.id, project_type: project_type if transition
  end
end
