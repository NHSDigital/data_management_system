class AddTrackwiseToProjects < ActiveRecord::Migration[5.0]
  def change
    # trackwise_id is just storing a number and doesn't link to a table.
    add_column :projects, :trackwise_id, :string
  end
end
