class AddClosureReasonToProjects < ActiveRecord::Migration[5.2]
  def change
    add_reference :projects, :closure_reason, foreign_key: true
  end
end
