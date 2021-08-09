class PopulateReferentReferenceOnDpias < ActiveRecord::Migration[6.0]
  class DPIA < ApplicationRecord
    self.table_name = 'data_privacy_impact_assessments'

    belongs_to :referent, polymorphic: true, optional: true
  end

  def up
    DPIA.find_each do |dpia|
      next unless referent ||= dpia.referent

      dpia.update!(referent_reference: referent.reference)
    end
  end

  # no-op
  def down; end
end
