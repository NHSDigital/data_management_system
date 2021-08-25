class AddReferentReferenceToReleases < ActiveRecord::Migration[6.0]
  def change
    add_column :releases, :referent_reference, :string
  end
end
