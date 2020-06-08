class FixDpiaReviewAmendTransition < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name_prefix = 'workflow_'
  end

  class Transition < ApplicationRecord
    self.table_name_prefix = 'workflow_'

    belongs_to :project_type
  end

  AMEND        = 'AMEND'.freeze
  DPIA_REVIEW  = 'DPIA_REVIEW'.freeze
  CONTRACTED   = 'CONTRACT_COMPLETED'.freeze
  PROJECT_TYPE = ProjectType.find_by!(name: 'Application')

  def change
    change_lookup Transition, 47,
                  { from_state_id: CONTRACTED,  next_state_id: AMEND, project_type: PROJECT_TYPE },
                  { from_state_id: DPIA_REVIEW, next_state_id: AMEND, project_type: PROJECT_TYPE }
  end
end
