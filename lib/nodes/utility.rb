module Nodes
  # Shared methods for buliding schema browser and change log
  module Utility
    def indent
      ' ' * (@depth * 2)
    end

    def multiplicity(node)
      "#{node.min_occurs}..#{node.max_occurrences}"
    end

    def save_schema_pack_file(output, filename, zipfile = nil)
      if zipfile.nil?
        File.open(Rails.root.join('tmp', filename), 'w') do |f|
          f.write output
        end
      else
        zipfile.get_output_stream(filename) { |f| f.write output }
      end
    end

    def xsd_file_name(value)
      "#{dataset_name}-v#{semver_version}_#{value.upcase}.xsd"
    end
  end
end
