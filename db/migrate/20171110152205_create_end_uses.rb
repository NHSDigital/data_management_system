class CreateEndUses < ActiveRecord::Migration[5.0]
  def change
    create_table :end_uses do |t|
      t.string :name

      t.timestamps
    end
  end
end
