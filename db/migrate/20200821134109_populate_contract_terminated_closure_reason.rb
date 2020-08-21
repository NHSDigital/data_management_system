class PopulateContractTerminatedClosureReason < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class ClosureReason < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup ClosureReason, 12, value: 'Contract terminated - data destruction form received'
  end
end
