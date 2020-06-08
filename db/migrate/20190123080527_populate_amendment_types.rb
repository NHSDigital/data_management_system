class PopulateAmendmentTypes < ActiveRecord::Migration[5.2]
  include MigrationHelper
  
  class AmendmentType < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup AmendmentType, 1, value: 'Data Items'
    add_lookup AmendmentType, 2, value: 'Data Sources'
    add_lookup AmendmentType, 3, value: 'Processing Purpose(s)'
    add_lookup AmendmentType, 4, value: 'Data Processor'
    add_lookup AmendmentType, 5, value: 'Extension to Contract Term'
    add_lookup AmendmentType, 6, value: 'Other'
    add_lookup AmendmentType, 7, value: 'Data Flows'
    add_lookup AmendmentType, 8, value: 'N/A'
    add_lookup AmendmentType, 9, value: 'GDPR Compliant Contract'
  end
end
