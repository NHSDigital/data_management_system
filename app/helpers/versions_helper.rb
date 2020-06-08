# Adds some helper functions for rendering Version resources.
module VersionsHelper
  # Provides a single, consistent interface over papertrail_version_path route helpers.
  def version_path(version)
    resource_type = version.item_type.demodulize.tableize
    papertrail_version_path(
      resource_type: resource_type,
      resource_id:   version.item_id,
      id:            version
    )
  end

  # Provides a single, consistent interface over the papertrail_versions_path route helpers.
  def versions_path(resource)
    papertrail_versions_path(
      resource_type: resource.model_name.element.pluralize,
      resource_id:   resource.id
    )
  end

  # Generates links to previosu/next versions.
  def version_siblings_tag(version)
    button_group do
      %i[previous next].collect do |sym|
        sibling = version.send(sym)
        target = version_path(sibling || version)
        concat link_to(sym, target, class: 'btn btn-default', disabled: sibling.nil?)
      end
    end
  end

  def versions_link(resource)
    link_to bootstrap_icon_tag('time') + ' Audit', versions_path(resource), class: 'btn btn-default'
  end
end
