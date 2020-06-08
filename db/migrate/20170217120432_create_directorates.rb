class CreateDirectorates < ActiveRecord::Migration[5.0]
  def change
    create_table :directorates do |t|
      t.string :name

      t.timestamps
    end
  end
end
