class PopulateReferentReferenceOnReleases < ActiveRecord::Migration[6.0]
  class Release < ApplicationRecord
    belongs_to :referent, polymorphic: true, optional: true
  end

  def up
    Release.find_each do |release|
      next unless referent ||= release.referent

      release.update!(referent_reference: referent.reference)
    end
  end

  # no-op
  def down; end
end
