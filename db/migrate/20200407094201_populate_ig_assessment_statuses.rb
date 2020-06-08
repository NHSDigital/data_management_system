class PopulateIgAssessmentStatuses < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class IgAssessmentStatus < ApplicationRecord; end

  def change
    add_lookup IgAssessmentStatus, 1, value: 'Standards met'
    add_lookup IgAssessmentStatus, 2, value: 'Standards not met'
    add_lookup IgAssessmentStatus, 3, value: 'Standards not met - improvement plan agreed'
    add_lookup IgAssessmentStatus, 4, value: 'Baseline'
  end
end
