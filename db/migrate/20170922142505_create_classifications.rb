class CreateClassifications < ActiveRecord::Migration[5.0]
  def change
    create_table :classifications do |t|
      # t.string :name, primary_key: true, null: false
      t.string :name
      t.timestamps
    end
  end
end
