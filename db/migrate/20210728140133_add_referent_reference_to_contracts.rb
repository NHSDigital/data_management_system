class AddReferentReferenceToContracts < ActiveRecord::Migration[6.0]
  def change
    add_column :contracts, :referent_reference, :string
  end
end
