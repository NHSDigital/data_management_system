class CreatePpatients < ActiveRecord::Migration[5.0]
  def change
    create_table :ppatients do |t|
      t.references :e_batch, index: true # i.e. belongs_to (alias)

      t.references :ppatient_rawdata, index: true

      t.string  :type
      t.text    :pseudo_id1
      t.text    :pseudo_id2   # NULL for prescriptions
    end
  end
end
