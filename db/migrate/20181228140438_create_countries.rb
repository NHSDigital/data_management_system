class CreateCountries < ActiveRecord::Migration[5.2]
  def change
    create_table :countries, id: false do |t|
      t.primary_key :id, :string, limit: 3
      t.string :value
      t.timestamps
    end
  end
end
