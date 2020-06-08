class CreateContracts < ActiveRecord::Migration[5.2]
  def change
    create_table :contracts do |t|
      t.references :project
      # t.references :contract_type # TODO: need lookup table
      # t.references :contract_version # TODO: need lookup table
      t.string :data_sharing_contract_ref # datatype? also exists on Project (is this a PK/FK?)
      # t.references :contract_status # TODO: need lookup table
      t.datetime :dra_start
      t.datetime :dra_end

      t.timestamps
    end
  end
end
