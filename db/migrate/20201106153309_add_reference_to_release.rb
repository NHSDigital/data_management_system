class AddReferenceToRelease < ActiveRecord::Migration[6.0]
  def change
    add_column :releases, :reference, :string
  end
end
