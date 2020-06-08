class AddAgeToMolecularData < ActiveRecord::Migration[5.0]
  def change
    add_column :molecular_data, :age, :integer
    add_column :genetic_test_results, :age, :integer
    add_column :genetic_sequence_variants, :age, :integer
  end
end
