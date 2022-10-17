require 'possibly'
require 'pry'

module Import
  module Colorectal
    module Providers
      module Cambridge
        # Process Cambridge-specific record details into generalized internal genotype format
        class CambridgeHandlerColorectal < Import::Germline::ProviderHandler
          PASS_THROUGH_FIELDS_COLO = %w[age consultantcode servicereportidentifier providercode
                                        authoriseddate requesteddate practitionercode genomicchange
                                        specimentype].freeze

          def initialize(batch)
            @failed_genocolorectal_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          CDNA_REGEX_COLO = /c\.(?<cdna>.*)/i.freeze
          PROTEIN_REGEX_COLO = /p.(?:\((?<impact>.*)\))/.freeze
          EXON_LOCATION_REGEX_COLO = /exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?)/i.freeze

          def process_fields(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            process_gene(genocolorectal, record)
            process_cdna_change(genocolorectal, record)
            add_protein_impact(genocolorectal, record)
            genocolorectal.add_variant_class(record.raw_fields['variantpathclass'].to_i)
            process_genomic_change(genocolorectal, record)
            # genocolorectal.add_received_date(record.raw_fields['received date'])
            genocolorectal.add_test_scope(:full_screen)
            genocolorectal.add_method('ngs')
            add_zygosity(genocolorectal, record)
            add_organisationcode_testresult(genocolorectal)
            process_exons(record.raw_fields['proteinimpact'], genocolorectal)
            @persister.integrate_and_store(genocolorectal)
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '69860'
          end

          def process_cdna_change(genocolorectal, record)
            case record.raw_fields['codingdnasequencechange']
            when CDNA_REGEX_COLO
              genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
              @positive_test += 1
              genocolorectal.add_status(:positive) # Added after coding
            else
              @logger.debug 'FAILED cdna change parse for: ' \
              "#{record.raw_fields['codingdnasequencechange']}"
              genocolorectal.add_status(:negative) # Added after coding
              @failed_genocolorectal_counter += 1
              @negative_test += 1
            end
          end

          def add_protein_impact(genocolorectal, record)
            case record.raw_fields['proteinimpact']
            when PROTEIN_REGEX_COLO
              genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug 'SUCCESSFUL protein change parse for: ' \
              "#{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug 'FAILED protein change parse for: ' \
              "#{record.raw_fields['proteinimpact']}"
            end
          end

          def process_genomic_change(genocolorectal, record)
            genomic_change = record.raw_fields['genomicchange']
            case genomic_change
            when /NC_0+(?<chr_num>\d+)\.\d+:g\.(?<genomicchange>.+)/i
              genocolorectal.add_parsed_genomic_change($LAST_MATCH_INFO[:chr_num].to_i,
                                                       $LAST_MATCH_INFO[:genomicchange])
              @logger.debug 'SUCCESSFUL chromosome change parse for: ' \
                            "#{$LAST_MATCH_INFO[:chr_num]} and " \
                            "#{$LAST_MATCH_INFO[:genomicchange]}"
            when nil
              @logger.warn 'Genomic change was empty'
            else
              @logger.warn 'Genomic change did not match expected format,'\
              "adding raw: #{genomic_change}"
              genocolorectal.add_raw_genomic_change(genomic_change)
            end
          end

          def process_gene(genocolorectal, record)
            genocolorectal.add_gene_colorectal(record.raw_fields['gene'].to_s)
            @successful_gene_counter += 1
          end

          def add_zygosity(genocolorectal, record)
            zygosity = record.raw_fields['variantgenotype'].to_str
            if zygosity == '0/1'
              genocolorectal.add_zygosity('het')
              @logger.debug 'SUCCESSFUL zygosity parse for: ' \
              "#{record.raw_fields['variantgenotype'].to_str}"
            elsif zygosity == '0/0'
              genocolorectal.add_zygosity('homo')
              @logger.debug 'SUCCESSFUL zygosity parse for: ' \
              "#{record.raw_fields['variantgenotype'].to_str}"
            else
              @logger.debug "Cannot determine zygosity; perhaps should be complex? #{zygosity}"
            end
          end

          def process_exons(genocolorectal_string, genocolorectal)
            exon_matches = EXON_LOCATION_REGEX_COLO.match(genocolorectal_string)
            if exon_matches
              genocolorectal.add_exon_location(exon_matches[1].delete(' '))
              genocolorectal.add_variant_type(genocolorectal_string)
              @logger.debug "SUCCESSFUL exon extraction for: #{genocolorectal_string}"
            else
              @logger.warn "Cannot extract exon from: #{genocolorectal_string}"
            end
          end

          def summarize
            @logger.info '***************** Handler Report *******************'
            @logger.info "Num genes failed to parse: #{@failed_gene_counter} of "\
            "#{@persister.genetic_tests.values.flatten.size} tests being attempted"
            @logger.info "Num genes successfully parsed: #{@successful_gene_counter} of"\
            "#{@persister.genetic_tests.values.flatten.size} attempted"
            @logger.info "Num genocolorectals failed to parse: #{@failed_genocolorectal_counter}"\
            "of #{@lines_processed} attempted"
            @logger.info "Num positive tests: #{@positive_test}"\
            "of #{@persister.genetic_tests.values.flatten.size} attempted"
            @logger.info "Num negative tests: #{@negative_test}"\
            "of #{@persister.genetic_tests.values.flatten.size} attempted"
          end
        end
      end
    end
  end
end
