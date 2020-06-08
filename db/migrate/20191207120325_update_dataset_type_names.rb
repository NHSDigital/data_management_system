class UpdateDatasetTypeNames < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    table_spec_id = DatasetType.find_by(name: 'Table Specification').id
    change_lookup DatasetType, table_spec_id,
                  { name: 'Table Specification' }, { name: 'table_specification' }
    non_xml_id = DatasetType.find_by(name: 'Non XML Schema').id
    change_lookup DatasetType, non_xml_id,
                  { name: 'Non XML Schema' }, { name: 'non_xml' }              
    xml_id = DatasetType.find_by(name: 'XML Schema').id
    change_lookup DatasetType, xml_id,
                  { name: 'XML Schema' }, { name: 'xml' }              

  end
end
