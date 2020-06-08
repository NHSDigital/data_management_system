class PopulateGovernance < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class Governance < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup Governance, 1, value: 'DIRECT IDENTIFIER'
    add_lookup Governance, 2, value: 'INDIRECT IDENTIFIER'
    add_lookup Governance, 3, value: 'NON IDENTIFYING DATA'
  end
end
