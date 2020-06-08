class PopulateProjectTypes < ActiveRecord::Migration[5.2]
  include MigrationHelper
  
  class ProjectType < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup ProjectType, 1, value: 'Research'
    add_lookup ProjectType, 2, value: 'Service Evaluation'
    add_lookup ProjectType, 3, value: 'Clinical Audit'
    add_lookup ProjectType, 4, value: 'Surveillance'
    add_lookup ProjectType, 5, value: 'Other'
  end
end
