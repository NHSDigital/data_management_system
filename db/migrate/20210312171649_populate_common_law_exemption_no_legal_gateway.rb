class PopulateCommonLawExemptionNoLegalGateway < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class CommonLawExemption < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup CommonLawExemption, 7, value: 'No legal gateway required'
  end
end
