class CreateNode < ActiveRecord::Migration[5.2]
  def change
    create_table :nodes do |t|
      # common
      t.integer :dataset_version_id
      t.string :type # node type - Entity DataItem Choice Group
      t.integer :parent_id
      t.integer :node_id
      t.string :name # xsd element name
      t.string :reference # dataset item number e.g CR0010
      t.string :annotation # annotation for xsd/documentation
      t.string :description # full description for documentation
      t.string :min_occurs
      t.string :max_occurs
      # DataItem
      t.integer :xml_type_id, null: true
      t.integer :data_dictionary_element_id, null: true;
      # Group
      t.integer :group_id
      # Choice
      t.integer :node_choice_id # a choice can belong to an entity or group node
      t.integer :choice_node_id # points a ChoiceNode to either and Entity or a DataItem
      t.integer :choice_type_id

      t.integer :sort

      t.timestamps
    end
  end
end
