include MigrationHelper
class PopulateEndUses < ActiveRecord::Migration[5.0]
  def change
    add_lookup EndUse, '1', name: 'Research'
    add_lookup EndUse, '2', name: 'Service Evaluation'
    add_lookup EndUse, '3', name: 'Clinical Audit'
    add_lookup EndUse, '4', name: 'Surveillance'
  end
end
