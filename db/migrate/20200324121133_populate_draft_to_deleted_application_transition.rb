class PopulateDraftToDeletedApplicationTransition < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    id = Workflow::Transition.maximum(:id) + 1
    app = ProjectType.find_by!(name: 'Application')

    add_lookup Workflow::Transition, id, from_state_id: 'DRAFT',
                                         next_state_id: 'DELETED',
                                         project_type: app
  end
end
