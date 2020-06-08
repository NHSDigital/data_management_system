# Add new columns to reflect the recent changes in the genetic data dictionary structure
class AddNewMolecularFields < ActiveRecord::Migration[5.0]
  def change
    add_column :molecular_data, :sourcetype, :text
    add_column :molecular_data, :comments, :text
    add_column :molecular_data, :datefirstnotified, :date
    add_column :molecular_data, :raw_record, :text
  end
end
