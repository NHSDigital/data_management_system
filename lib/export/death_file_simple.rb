module Export
  # Specification for a simple death file
  # (CSV data with a header row, no special fields, leading zeros removed from agec)
  # To produce a simple extract, all that needs to be overridden is the #fields method.
  # Use filter='all' to get all records from a batch (including repeats)
  # or filter='new' to get only new records in a batch (excluding records sent before)
  # or filter='all_nhs' for all records with NHS numbers (including repeats)
  # or filter='new_nhs' for only new records with NHS numbers (excluding such records sent before)
  class DeathFileSimple < DeathFile
    include SimpleCsv

    # Field descriptions for the exported CSV file, returns a header triple + list of triples
    # [[csv_column_name1, mbis_field_name1, mbis_field_description], ...
    def field_descriptions
      special_inverse = SPECIAL.flat_map { |k, v| v.call.collect { |v2| [v2, k.to_s] } }.to_h
      field_to_node_map = NODE_TO_FIELD_MAP.invert
      node_descriptions = Export::DeathFile.dataset_version.nodes.
                          collect { |node| [node.name, node.description] }.to_h
      [%w[column_name dataset_node_name column_description]] + fields.collect do |field|
        node_description = extra_field_descriptions[field]
        next [field, nil, node_description] if node_description

        base_field = special_inverse.fetch(field, field)
        node_name = field_to_node_map[base_field]
        node_description = node_descriptions[node_name]
        [field, node_name, node_description]
      end
    end

    private

    # Maps extra custom field names (without corresponding Nodes) to descriptions
    # Override this in subclasses for extra custom fields
    def extra_field_descriptions
      {
        'codt_codfft_1' => 'CODFFT if present (1st row / 75 characters), otherwise CODT_1',
        'codt_codfft_2' => 'CODFFT if present (2nd row / 75 characters), otherwise CODT_2',
        'codt_codfft_3' => 'CODFFT if present (3rd row / 75 characters), otherwise CODT_3',
        'codt_codfft_4' => 'CODFFT if present (4th row / 75 characters), otherwise CODT_4',
        'codt_codfft_5' => 'CODFFT if present (5th row / 75 characters), otherwise CODT_5'
      }
    end

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refactor with CancerMortalityFile, into DeathFile
    def extract_field(ppat, field)
      # Special fields not in the original spec
      val = super(ppat, field)
      case field
      when 'agec' # Remove leading zeros
        val = val.to_i.to_s if val.present?
      end
      val
    end
  end
end
