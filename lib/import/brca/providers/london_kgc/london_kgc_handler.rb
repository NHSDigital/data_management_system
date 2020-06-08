require 'possibly'
require 'import/genotype'
require 'import/storage_manager/persister'
require 'core/provider_handler'
require 'core/extraction_utilities'
require 'pry'

module LondonKgc
  # London KGC Importer
  class LondonKgcHandler < Import::Brca::Core::ProviderHandler
    PASS_THROUGH_FIELDS = %w[age sex consultantcode collecteddate
                             receiveddate authoriseddate servicereportidentifier
                             providercode receiveddate ] .freeze

    BRCA_REGEX = /(?<brca>BRCA(1|2)).+/i .freeze
    CDNA_REGEX = /c\.(?<cdna>[0-9]+[^\s]+)/i .freeze
    PATHCLASS_REGEX = /(?<pathclass>[1-5]) \-/i .freeze
    EXON_LOCATION_REGEX = /(?<exons> exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?))/i .freeze

    def initialize(batch)
      super
    end

    def process_fields(record)
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      PASS_THROUGH_FIELDS)
      process_cdna_change(genotype, record)
      process_varpathclass(genotype, record)
      process_exons(genotype, record)
      @persister.integrate_and_store(genotype)
    end

    def process_cdna_change(genotype, record)
      case record.mapped_fields['genotype']
      when CDNA_REGEX
        genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
        @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
        genotype.add_status(:positive)
      when /No mutation detected/
        @logger.debug 'No mutation detected'
        genotype.add_status(:negative)
      else
        @logger.debug 'Impossible to parse cdna change'
      end
    end

    def process_gene(genotype, record)
      case record.mapped_fields['genotype']
      when BRCA_REGEX
        genotype.add_gene($LAST_MATCH_INFO[:brca])
        @logger.debug "Successful parse for #{$LAST_MATCH_INFO[:brca]}"
      else
        @logger.debug 'No gene detected'
      end
    end

    def process_varpathclass(genotype, record)
      case record.mapped_fields['variantpathclass']
      when PATHCLASS_REGEX
        genotype.add_variant_class($LAST_MATCH_INFO[:pathclass].to_i)
        @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:pathclass]}"
      end
    end

    def process_exons(genotype, record)
      case record.mapped_fields['genotype']
      when EXON_LOCATION_REGEX
        genotype.add_exon_location($LAST_MATCH_INFO[:exons])
        genotype.add_variant_type(record.mapped_fields['genotype'])
        @logger.debug "SUCCESSFUL exon parse for: #{record.mapped_fields['genotype']}"
      end
    end
  end
end
