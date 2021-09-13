class PopulateReferentOnDpias < ActiveRecord::Migration[6.0]
  class DPIA < ApplicationRecord
    self.table_name = 'data_privacy_impact_assessments'
  end

  def up
    DPIA.find_each do |dpia|
      dpia.update!(referent_type: 'Project', referent_id: dpia.project_id)
    end
  end

  # no-op
  def down; end
end
