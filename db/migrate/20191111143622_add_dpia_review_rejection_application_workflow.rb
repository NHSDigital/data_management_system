# Allows peer-reviewing of Applications to be send back to the start
# earlier than moderation
class AddDpiaReviewRejectionApplicationWorkflow < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'

    belongs_to :project_type
  end

  def change
    app = ProjectType.find_by!(name: 'Application')

    add_lookup Transition, 38, project_type: app, from_state_id: 'DPIA_REVIEW', next_state_id: 'DPIA_REJECTED'
  end
end
