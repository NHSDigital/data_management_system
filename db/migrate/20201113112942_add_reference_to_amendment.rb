class AddReferenceToAmendment < ActiveRecord::Migration[6.0]
  def change
    add_column :project_amendments, :reference, :string
  end
end
