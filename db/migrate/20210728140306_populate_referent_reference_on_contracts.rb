class PopulateReferentReferenceOnContracts < ActiveRecord::Migration[6.0]
  class Contract < ApplicationRecord
    belongs_to :referent, polymorphic: true, optional: true
  end

  def up
    Contract.find_each do |contract|
      next unless referent ||= contract.referent

      contract.update!(referent_reference: referent.reference)
    end
  end

  # no-op
  def down; end
end
