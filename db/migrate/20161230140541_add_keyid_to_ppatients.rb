class AddKeyidToPpatients < ActiveRecord::Migration[5.0]
  def change
    remove_reference :pseudonymisation_keys, :ppatient
    add_column :ppatients, :pseudonymisation_keyid, :integer
    add_foreign_key(:ppatients, :pseudonymisation_keys,
                    column: :pseudonymisation_keyid, primary_key: :pseudonymisation_keyid)
  end
end
