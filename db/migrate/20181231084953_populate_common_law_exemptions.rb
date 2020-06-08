class PopulateCommonLawExemptions < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class CommonLawExemption < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup CommonLawExemption, 1, value: 'Informed Consent'
    add_lookup CommonLawExemption, 2, value: 'Direct Care Relationship'
    add_lookup CommonLawExemption, 3, value: 'S251 Regulation 2'
    add_lookup CommonLawExemption, 4, value: 'S251 Regulation 3'
    add_lookup CommonLawExemption, 5, value: 'S251 Regulation 5'
    add_lookup CommonLawExemption, 6, value: 'Other'
  end
end
