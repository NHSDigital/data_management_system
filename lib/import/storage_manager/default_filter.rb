require 'possibly'
require 'pry'
require 'import/database_wrappers/genetic_sequence_variant'
require 'import/database_wrappers/genetic_test_result'
require 'import/database_wrappers/genetic_test'
require 'import/database_wrappers/genotype_wrapper'
require 'import/central_logger'
require 'import/import_key'
module Import
  module StorageManager
    # The default filter lets everything through
    class DefaultFilter < GenotypeFilter
      def valid?(_genotype)
        @total_genotypes += 1 # genotype.attribute_map["gene"].nil?
        genotype_passes = true
        @rejected_genotypes += 1 unless genotype_passes
        genotype_passes
      end
    end
  end
end
