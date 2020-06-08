class CreateGovernance < ActiveRecord::Migration[5.2]
  def change
    create_table :governances do |t|
      t.string :value
      t.timestamps
    end
  end
end
