class AddReferentToContracts < ActiveRecord::Migration[6.0]
  def change
    add_reference :contracts, :referent, polymorphic: true, index: true
  end
end
