class AddRequiresYubikeyToWorkflowTransitions < ActiveRecord::Migration[6.0]
  def change
    add_column :workflow_transitions, :requires_yubikey, :boolean, default: false
  end
end
