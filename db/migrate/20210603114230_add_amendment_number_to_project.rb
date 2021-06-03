class AddAmendmentNumberToProject < ActiveRecord::Migration[6.0]
  def change
    add_column :projects, :amendment_number, :integer, default: 0
  end
end
