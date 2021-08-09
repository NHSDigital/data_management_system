class AddReferentToReleases < ActiveRecord::Migration[6.0]
  def change
    add_reference :releases, :referent, polymorphic: true, index: true
  end
end
