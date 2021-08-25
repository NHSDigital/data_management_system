# Shared logic for `Contract`s, `DPIA`s and `Release`s, who need to be associated with a
# polymorphic parent resource (`Project` or `Amendment`).
# TODO/FIXME: These resources will also still have a belongs_to association with `Project`. That
# association could/should be considered a helper association for finding sub-resources within
# a global scope, irrespective of the true parent resource.
module BelongsToReferent
  extend ActiveSupport::Concern

  included do
    belongs_to :referent, polymorphic: true

    # Copy the associated reference to the local model/table (because some groups want to query the
    # database directly).
    before_save -> { self.referent_reference = referent&.reference }
  end

  def referent_gid
    referent&.to_global_id
  end

  # Using GlobalIDs to set the polymorphic association, since we're not (currently) creating
  # these resources through the parent via a RESTful routing approach.
  def referent_gid=(gid)
    self.referent = GlobalID::Locator.locate(gid)
  end
end
