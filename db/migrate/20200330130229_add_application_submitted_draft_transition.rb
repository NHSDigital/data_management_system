class AddApplicationSubmittedDraftTransition < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name_prefix = 'workflow_'
  end

  class Transition < ApplicationRecord
    self.table_name_prefix = 'workflow_'

    belongs_to :project_type
  end

  PROJECT_TYPE = ProjectType.find_by!(name: 'Application')

  def change
    add_lookup Transition, 49, from_state_id: 'SUBMITTED', next_state_id: 'DRAFT', project_type: PROJECT_TYPE
  end
end
