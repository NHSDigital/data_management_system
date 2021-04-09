require 'json'
require 'possibly'
require 'pry'
# These wrappers contain genotypes, but provide comparisons at the level appropriate
# to the described database table
module Import
  module DatabaseWrappers
    # Wrapper for genotype which compares fields present in the
    # geneticsequencevariant table
    class GeneticSequenceVariant < GenotypeWrapper
      def initialize(genotype)
        @representative_genotype = genotype
        @field_names = Pseudo::GeneticSequenceVariant.column_names -
         # %w[geneticsequencevariantid genetictestresultid raw_record]
        %w[geneticsequencevariantid
          genetic_test_result_id
          humangenomebuild
          referencetranscriptid
          genomicchange
          clinvarid
          cosmicid
          variantlocation
          variantgenotype
          variantallelefrequency
          variantreport
          raw_record
          age]
      end

      # Should not produce a variant record unless there actually is a variant
      def produce_record
        # if (@field_names -  ['variantpathclass']).all?
        # {|x| @representative_genotype.attribute_map[x].nil?}
        if @field_names.all? { |x| @representative_genotype.attribute_map[x].nil? }
          nil
        else
          super()
        end
      end

      def similar!(genotype)
        @representative_genotype.similar_record(genotype, @field_names - ['age'])
      end
    end
  end
end
