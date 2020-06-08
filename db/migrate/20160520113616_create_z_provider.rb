# ZProvider
class CreateZProvider < ActiveRecord::Migration[5.0]
  def rebuild
    drop
    change
  end

  def drop
    drop_table :zprovider
  end

  def change
    create_table :zprovider, id: false do |t|
      t.string    :zproviderid, limit: 255, primary_key: true, default: 1, null: false
      t.string    :shortdesc, limit: 128
      t.string    :description, limit: 2000
      t.string    :exportid, limit: 64
      t.datetime  :startdate
      t.datetime  :enddate
      t.integer   :sort, limit: 8 # bigint
      t.string    :role, limit: 1
      t.integer   :local_hospital, limit: 2, default: 0, null: false    # smallint
      t.integer   :breast_screening_unit, limit: 2, default: 0, null: false
      t.integer   :historical, limit: 2, default: 0, null: false
      t.string    :lpi_providercode, limit: 255
      t.string    :zpostcodeid, limit: 255
      # Provider has a linear particle accelerator
      t.integer   :linac, limit: 2, default: 0, null: false
      t.string    :analysisid, limit: 255
      t.integer   :nacscode, limit: 2
      t.string    :nacs5id, limit: 5
      t.string    :successorid, limit: 255
      t.string    :local_registryid, limit: 5
      t.string    :source, limit: 255
    end
  end
end
