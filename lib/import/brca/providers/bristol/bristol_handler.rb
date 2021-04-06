require 'possibly'
require 'pry'
module Import
  module Brca
    module Providers
      module Bristol
        # Process Bristol-specific record details into generalized internal genotype format
        class BristolHandler < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS = %w[age consultantcode
                                   servicereportidentifier
                                   providercode
                                   authoriseddate
                                   requesteddate
                                   practitionercode
                                   geneticaberrationtype].freeze
          CDNA_REGEX = /c\.(?<cdna>[0-9]+[^\s|^, ]+)/ .freeze
          PROTEIN_REGEX = /p.(?:\((?<impact>.*)\))/ .freeze

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            add_simple_fields(genotype, record)
            process_cdna_change(genotype, record)
            add_protein_impact(genotype, record)
            add_organisationcode_testresult(genotype)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '698V0'
          end

          def add_simple_fields(genotype, record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            # extractGeneAndLocation(record.raw_fields['chrpos'], genotype)
            genotype.add_gene(record.mapped_fields['gene'].to_i)
            genotype.add_gene_location(record.mapped_fields['codingdnasequencechange'])
            genotype.add_protein_impact(record.mapped_fields['proteinimpact'])
            genotype.add_variant_class(record.mapped_fields['variantpathclass'])
            genotype.add_received_date(record.raw_fields['received date'])
            process_genomic_change(genotype, record)
            genotype.add_test_scope(:full_screen)
            genotype.add_method('ngs')
          end

          def process_cdna_change(genotype, record)
            case record.mapped_fields['codingdnasequencechange']
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            else
              @logger.debug 'UNSUCCESSFUL cdna change parse'
            end
          end

          def add_protein_impact(genotype, record)
            case record.mapped_fields['proteinimpact']
            when PROTEIN_REGEX
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug 'SUCCESSFUL protein change parse for: ' \
              "#{$LAST_MATCH_INFO[:impact]}"
            end
          end

          def process_genomic_change(genotype, record)
            gchange = record.raw_fields['genomicchange']
            return if gchange.nil?

            case gchange
            when /(?<chr_num>\d+):(?<g_num>\d+)/
              genotype.add_parsed_genomic_change($LAST_MATCH_INFO[:chr_num],
                                                 $LAST_MATCH_INFO[:g_num])
            else
              @logger.warn "Could not process genomic change, adding raw: #{gchange}"
              genotype.add_raw_genomic_change(gchange)
            end
          end
        end
      end
    end
  end
end
