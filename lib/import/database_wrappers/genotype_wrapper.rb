require 'json'
require 'possibly'
require 'pry'
# These wrappers contain genotypes, but provide comparisons at the level appropriate
# to the described database table
module Import
  module DatabaseWrappers
    # Convert the genotype representation to a hash containing the fields appropriate
    # for the type of db record corresponding to the subclass. Field mappings allow
    # for last-minute column renaming, and adds in raw representation so that
    # essentially all the original information should end up in a db entry at some level
    class GenotypeWrapper
      FIELD_MAPPING = { 'consultantcode' => 'practitionercode' } .freeze

      attr_reader :representative_genotype

      def produce_record
        (@field_names.map do |field|
          [Maybe(FIELD_MAPPING[field]).or_else(field),
          @representative_genotype.attribute_map[field]]
        end).
        to_h.
        reject { |_, v| v.nil? }.
        merge('raw_record' => JSON.generate(@representative_genotype.raw_record.raw_all))
        # This intentionally forwards nils
      end

      def similar!(genotype)
        @representative_genotype.similar_record(genotype, @field_names)
      end
    end
  end
end
