# This controller RESTfully manages versions
class VersionsController < ApplicationController
  include PolymorphicAuthorizable

  polymorphic_load_and_authorize_resource :version, class: 'PaperTrail::Version'

  respond_to :js, :html

  def index
    @lastet_version = parent_resource.versions.last
    @all_versions   = find_all_versions(parent_resource).
                      order(created_at: :desc).
                      paginate(page: params[:page], per_page: 10)
  end

  def show
    # @version.object_changes.nil? indicates
    # that the object has been destroyed
    return if @version.object_changes.nil?

    @deserialized_object_changes = deserialized_object_changes(@version)

    # @version.index[0] is the first version so does not have @version.object for
    # comparison, the original version is therefore shown to the user
    return if @version.index.zero?
    @updated_object = updated_object(@version).delete_if { |key, _| ignored_columns.include? key }
  end

  private

  # Previous version
  def deserialized_object(version)
    PaperTrail.serializer.load(version.object)
  end

  # Changes between versions
  def deserialized_object_changes(version)
    PaperTrail.serializer.load(version.object_changes)
  end

  # Overrite deserialized_object['data_item'] with @deserialized_object_changes['data_item']
  def updated_object(version)
    deserialized_object(version).deep_merge!(deserialized_object_changes(version))
  end

  # Return all versions for a given object,
  # including association changes
  # FIXME: We should also be authorizing the :read permission on the associations too.
  def find_all_versions(resource)
    item_type = resource.class.name
    item_id   = resource.id
    item_fk   = item_type.foreign_key

    PaperTrail::Version.where(<<~SQL, item_type: item_type, item_id: item_id, item_fk: item_fk)
      (item_type = :item_type and item_id = :item_id)
        or id in
          (select distinct version_id
           from version_associations
           where foreign_key_name = :item_fk and
           foreign_key_id = :item_id)
    SQL
  end

  # Columns that won't be displayed when viewing a version.
  # Some of these columns are not tracked at all by paper_trail.
  # See model class has_paper_trail :ignore [] options
  def ignored_columns
    if @version.item_type == 'User'
      %w(current_sign_in_at current_sign_in_ip encrypted_password
         failed_attempts last_sign_in_at last_sign_in_ip locked_at remember_created_at
         reset_password_sent_at reset_password_token sign_in_count).to_set
    else
      []
    end
  end
end
