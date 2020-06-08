class CreatePpatientRawdata < ActiveRecord::Migration[5.0]
  def change
    create_table :ppatient_rawdata, id: false do |t|
      t.primary_key  :ppatient_rawdataid

      # one-to-many relationship from PPATIENT_RAWDATA to PPATIENT,
      # so that if the raw data is identical, we can optimise storage.
      t.binary  :rawdata     # blob
      t.binary  :decrypt_key
    end
  end
end
