# plan.io 25873 - Add levels column to datasets
class AddLevelsColumnToDatasets < ActiveRecord::Migration[6.0]
  def change
    change_table :datasets, bulk: true do |t|
      t.column :levels, :jsonb, null: false, default: {}
      t.column :cas_type, :integer, limit: 1
    end
  end
end
