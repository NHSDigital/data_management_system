class CreateOutputs < ActiveRecord::Migration[5.0]
  def change
    create_table :outputs do |t|
      t.string :name

      t.timestamps
    end
  end
end
