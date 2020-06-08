class CreateEnumerationValue < ActiveRecord::Migration[5.2]
  def change
    create_table :enumeration_values do |t|
      t.string :enumeration_value
      t.string :annotation

      t.timestamps
    end
  end
end
