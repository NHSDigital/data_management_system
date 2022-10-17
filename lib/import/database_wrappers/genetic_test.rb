require 'json'
require 'possibly'
require 'pry'
# These wrappers contain genotypes, but provide comparisons at the level appropriate
# to the described database table
module Import
  module DatabaseWrappers
    # Wrapper for genotype which compares fields present in the
    # genetictest (molecular data) table
    class GeneticTest < GenotypeWrapper
      def initialize(genotype)
        @representative_genotype = genotype
        unwanted_columns = %w[genetictestid patientid raw_record]
        @field_names = Pseudo::MolecularData.column_names - unwanted_columns
      end

      def produce_record
        super.tap do |record_hash|
          record_hash.reject do |key, _value|
            %w[localpatientidentifier organisationname_testresult].include? key
          end
        end
      end

      def similar!(genotype)
        total_similarity = @representative_genotype.similar_record(genotype, @field_names,
                                                                   strict: true)
        partial_similarity = @representative_genotype.
                             similar_record(genotype, @field_names - ['karyotypingmethod'],
                                            strict: true)
        if total_similarity == partial_similarity
          total_similarity
        else
          @representative_genotype.add_method(:multiple_methods) # "multiple testing methods"
          genotype.add_method(:multiple_methods)
          true
        end
      end
    end
  end
end
