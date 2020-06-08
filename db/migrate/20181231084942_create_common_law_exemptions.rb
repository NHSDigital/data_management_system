class CreateCommonLawExemptions < ActiveRecord::Migration[5.2]
  def change
    create_table :common_law_exemptions do |t|
      t.string :value
      t.timestamps
    end
  end
end
