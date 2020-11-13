class CreateCasDatasetsLookup < ActiveRecord::Migration[6.0]
  def change
    create_table :cas_datasets do |t|
      t.string 'value'
      t.integer 'sort'
    end
  end
end
