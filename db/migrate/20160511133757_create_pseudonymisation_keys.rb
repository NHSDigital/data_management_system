class CreatePseudonymisationKeys < ActiveRecord::Migration[5.0]
  def change
    create_table :pseudonymisation_keys, id: false do |t|
      t.primary_key  :pseudonymisation_keyid
      t.references   :ppatient, index: true

      t.text    :key_name
      t.date    :startdate
      t.date    :enddate
      t.text    :comments
      t.string  :e_type, limit: 255     # like Esourcemapping, foreign key constrained to @ZPROVIDER.ZPROVIDERID
      t.string  :provider, limit: 255   # like Esourcemapping, foreign key constrained to @ZE_TYPE.ZE_TYPEID
    end
  end
end
