class PopulatePropositions < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class Proposition < ApplicationRecord; end

  def change
    add_lookup Proposition, 'Y',  value: 'Yes'
    add_lookup Proposition, 'N',  value: 'No'
    add_lookup Proposition, 'NA', value: 'Not Applicable'
  end
end
