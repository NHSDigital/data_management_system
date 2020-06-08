class CreateClosureReasons < ActiveRecord::Migration[5.2]
  def change
    create_table :closure_reasons do |t|
      t.string :value
      t.timestamps
    end
  end
end
