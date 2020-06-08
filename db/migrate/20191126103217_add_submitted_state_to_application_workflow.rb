require 'migration_helper'

class AddSubmittedStateToApplicationWorkflow < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class ProjectType < ApplicationRecord; end

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'

    belongs_to :project_type
  end


  def change
    project_type = ProjectType.find_by!(name: 'Application')

    add_lookup Transition, 39, from_state_id: 'SUBMITTED', next_state_id: 'DPIA_START', project_type: project_type
    change_lookup Transition, 29, { next_state_id: 'DPIA_START' }, { next_state_id: 'SUBMITTED' }
  end
end
