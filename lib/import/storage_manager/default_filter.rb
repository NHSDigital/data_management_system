require 'possibly'
require 'pry'
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
