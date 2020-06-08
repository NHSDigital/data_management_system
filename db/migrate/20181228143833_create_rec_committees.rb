class CreateRecCommittees < ActiveRecord::Migration[5.2]
  def change
    create_table :rec_committees do |t|
      t.string :value
      t.timestamps
    end
  end
end
