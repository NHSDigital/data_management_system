require 'json'
require 'possibly'
require 'pry'
# These wrappers contain genotypes, but provide comparisons at the level appropriate
# to the described database table
module Import
  module DatabaseWrappers
    # Wrapper for genotype which compares fields present in the genetictestresult
    # table
    class GeneticTestResult < GenotypeWrapper
      def initialize(genotype)
        @representative_genotype = genotype
        @field_names = Pseudo::GeneticTestResult.column_names - %w[genetictestresultid
                                                                   genetictestid report raw_record]
        @logger = Import::Log.get_logger
      end

      def similar?(genotype)
        @representative_genotype.similar_record(genotype, @field_names, strict: true)
      end

      def produce_record
        super()
        # standard_fields.merge({"geneticsequencevariants" => variantRecords})
      end
    end
  end
end
