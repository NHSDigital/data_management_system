# This module provides helper methods for the audit pages
module VersionHelper
  # Returns the count of version for a given
  def version_count(object_version)
    PaperTrail::Version.where('item_type = ? and item_id = ?',
                              object_version.item_type, object_version.item_id).count
  end

  # Audit highlighting for adding/removing/updating values
  def audit_highlighting(array)
    return 'success' if array[0].blank? && !array[1].blank?  # value added
    return 'warning' if !array[0].blank? && !array[1].blank? # value updated
    return 'danger' if !array[0].blank? && array[1].blank?   # value removed
  end
end
