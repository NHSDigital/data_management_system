class AddReferenceToContract < ActiveRecord::Migration[6.0]
  def change
    add_column :contracts, :reference, :string
  end
end
