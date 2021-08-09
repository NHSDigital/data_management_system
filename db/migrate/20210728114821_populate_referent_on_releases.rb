class PopulateReferentOnReleases < ActiveRecord::Migration[6.0]
  class Release < ApplicationRecord; end

  def up
    Release.find_each do |release|
      release.update!(referent_type: 'Project', referent_id: release.project_id)
    end
  end

  # no-op
  def down; end
end
