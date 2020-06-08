class AddXmlTypeIdToDataDictionaryElement < ActiveRecord::Migration[5.2]
  def change
    add_column :data_dictionary_elements, :xml_type_id, :integer
  end
end
