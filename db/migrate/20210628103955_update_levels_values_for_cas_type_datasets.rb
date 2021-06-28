# plan.io 25873 - Add sample Levels for all cas_type datasets
class UpdateLevelsValuesForCasTypeDatasets < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def up
    Dataset.where.not(cas_type: nil).pluck(:id).each do |id|
      change_lookup Dataset, id, { levels: {} }, { levels: [1, 2] }
    end
  end

  def down
    Dataset.where.not(cas_type: nil).update_all(levels: {})
  end
end
