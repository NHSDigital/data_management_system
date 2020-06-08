class AddPseudoidIndexesToPpatients < ActiveRecord::Migration[5.0]
  def change
    add_index :ppatients, :pseudo_id1
    add_index :ppatients, :pseudo_id2
  end
end
