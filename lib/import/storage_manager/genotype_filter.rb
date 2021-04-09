require 'possibly'
require 'pry'
module Import
  module StorageManager
    # Selectively remove genotypes from the stream before they are integrated
    class GenotypeFilter
      def initialize
        @rejected_genotypes = 0
        @total_genotypes    = 0
        @logger = Import::Log.get_logger
      end

      def invalid?(genotype)
        !valid?(genotype)
      end

      def valid?(_genotype)
        @total_genotypes += 1
        true
      end

      def summarize
        @logger.info '******************* Filter Report ********************'
        @logger.info "Filter rejected #{@rejected_genotypes} of" \
        "#{@total_genotypes} genotypes seen"
      end
    end

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
