class CreatePropositions < ActiveRecord::Migration[6.0]
  def change
    create_table :propositions, id: false do |t|
      t.string :id,    null: false, limit: 2, primary_key: true
      t.string :value, null: false

      t.timestamps
    end
  end
end
