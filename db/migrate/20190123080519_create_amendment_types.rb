class CreateAmendmentTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :amendment_types do |t|
      t.string :value
    end
  end
end
