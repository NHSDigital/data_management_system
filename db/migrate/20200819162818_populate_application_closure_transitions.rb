class PopulateApplicationClosureTransitions < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class State < ApplicationRecord
    self.table_name_prefix = 'workflow_'
  end

  class Transition < ApplicationRecord
    self.table_name_prefix = 'workflow_'

    belongs_to :project_type
  end

  REJECTED         = 'REJECTED'.freeze
  PROJECT_TYPE     = ProjectType.find_by!(name: 'Application')

  def change
    starting_id = 53
    from_states.each_with_index do |state, i|
      add_lookup Transition, starting_id + i, from_state_id: state, next_state_id: REJECTED, project_type: PROJECT_TYPE
    end
  end

  def from_states
    %w[DPIA_START DPIA_REVIEW DPIA_MODERATION DPIA_REJECTED CONTRACT_REJECTED CONTRACT_COMPLETED
       CONTRACT_DRAFT SUBMITTED AMEND DRAFT DATA_RELEASED DATA_DESTROYED]
  end
end



