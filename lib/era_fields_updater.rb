# Use with a migration to Update era fields table
# TODO: Address special case -  needs updating manually to below for now
# - column: StreetAddressLine
#   rawtext_name: address
#   cosd_xml:
#     id:
#     relative_path: "/Address/UnstructuredAddress"
#     attribute:
#     version: ">= 9.0"
#   mappings:
#   - field: address
# - column: StreetAddressLine
#   rawtext_name: address
#   cosd_xml:
#     id:
#     relative_path: "/Address/StructuredAddress"
#     attribute:
#     version: ">= 9.0"
#   mappings:
#   - field: address
class EraFieldsUpdater
  attr_accessor :dataset_version, :nodes

  def initialize(dataset_version, filepath)
    @nodes = YAML.safe_load(File.open(Rails.root.join(filepath))).first
    @dataset_version = dataset_version
    @counter = 0
  end

  def build
    nodes['children'].each do |node|
      populate_child_node(node)
    end
    print "\n Updated #{@counter} nodes!\n"
  end

  def populate_child_node(node)
    populate_era_fields(node)
    # no more children
    return if node['children'].nil?

    node['children'].each do |child_node|
      populate_child_node(child_node)
    end
  end

  def populate_era_fields(node)
    return unless node.any? { |k, _| mapping.keys.map(&:to_s).include? k }
    return if node['reference'].nil?
    # multiple nodes make exist with same reference and should all be going to the same place
    nodes_to_update = dataset_version.nodes.where(reference: node['reference'])
    nodes_to_update.each do |node_to_update|
      next if node_to_update.era_fields.present?

      update_fields = mapping.each_with_object({}) do |(era_field, dms_field), fields|
        value = node[era_field.to_s]
        next if value.nil?

        value = (db_arrays.include? era_field) ? value.split : value
        fields[dms_field] = value
      end


      node_to_update.create_era_fields(update_fields)
      @counter += 1
    end
  end

  def mapping
    {
      e_base_record: :ebr,
      rawtext_name: :ebr_rawtext_name,
      virtual_field: :ebr_virtual_name,
      encore_event: :event,
      encore_event_field: :event_field_name,
      encore_notes: :comments
    }
  end

  def db_arrays
    %i[e_base_record virtual_field encore_event_field encore_event]
  end

  # TODO: should put this information into the yml doc file so this isn't needed
  # Retrieved information from local era pg system SQL queries
  # usage 
  # e = EraFieldsUpdater.new(DatasetVersion.first, 'doc/COSD/FKs.yml')
  # e.seed_fk_tables
  def seed_fk_tables
    updated = 0
    lookup = nodes.last
    EraFields.all.each do |field|
      next if field.event.blank?
      next if field.event_field_name.blank?

      update_data = lookup.find do |l|
        (field.event.map(&:downcase).include? l['table_name']) &&
        (field.event_field_name.include? l['column_name'])
      end
      next if update_data.nil?

      field.lookup_table = update_data['fk_table']
      field.save!
      updated += 1
    end
    print "Updated #{updated} nodes!\n"
  end
end
