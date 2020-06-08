class CreateLawfulBases < ActiveRecord::Migration[5.2]
  def change
    create_table :lawful_bases, id: false do |t|
      t.primary_key :id, :string
      t.string :value
      t.timestamps
    end
  end
end
