# plan.io 25873 - Make all cas scoped datasets into cas_type of 'cas_extras'
class UpdateCasTypeCasDatasets < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    Dataset.cas.pluck(:id).each do |id|
      change_lookup Dataset, id, { cas_type: nil }, { cas_type: 2 }
    end
  end
end
