require 'possibly'

module Import
  module Brca
    module Providers
      module Cambridge
        # Process Cambridge-specific record details into generalized internal genotype format
        class CambridgeHandler < Import::Germline::ProviderHandler
          PASS_THROUGH_FIELDS = %w[age consultantcode servicereportidentifier providercode
                                   authoriseddate requesteddate practitionercode genomicchange
                                   specimentype].freeze

          def initialize(batch)
            @failed_genotype_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          CDNA_REGEX = /c\.(?<cdna>.*)/i
          PROTEIN_REGEX = /p.(?:\((?<impact>.*)\))/
          EXON_LOCATION_REGEX = /exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?)/i
          ORG_CODE_MAP = {
            'north west thames genetics service' => 'R1K01',
            'royal free hampstead nhs trust' => 'RAL01',
            'royal free hospital' => 'RAL01',
            'royal united hospital' => 'RD130',
            "addenbrooke's hospital" => 'RGT01',
            'centre for medical genetics' => 'RGT01',
            'clinical genetics' => 'RGT01',
            'clinical genetics, box 134' => 'RGT01',
            'department of paediatrics' => 'RGT01',
            'genetics laboratories' => 'RGT01',
            'oncology' => 'RGT01',
            'royal devon & exeter hospital' => 'RH802',
            'portsmouth hospital' => 'RHU03',
            'st georges' => 'RJ701',
            'norfolk and norwich university hospital' => 'RM102',
            'norfolk & norwich hospital' => 'RM102',
            'james cook university hospital' => 'RTDCR'
          }.freeze

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields, record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            # genotype.add_gene(record.mapped_fields['gene'].to_i) # TODO: wrap in option for safety
            variantpathclass = record.raw_fields['variantpathclass'].to_i
            process_gene(genotype, record)
            process_cdna_change(genotype, record, variantpathclass)
            add_protein_impact(genotype, record)
            genotype.add_variant_class(variantpathclass)
            process_genomic_change(genotype, record)
            # genotype.add_received_date(record.raw_fields['received date'])
            genotype.add_test_scope(:full_screen)
            genotype.add_method('ngs')
            add_zygosity(genotype, record)
            process_exons(record.raw_fields['proteinimpact'], genotype)
            add_organisationcode_testresult(genotype)
            add_provider_code(genotype, record, ORG_CODE_MAP)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '69860'
          end

          def process_cdna_change(genotype, record, variantpathclass)
            case record.raw_fields['codingdnasequencechange']
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
              non_pathogenic_status?(genotype, variantpathclass)
            else
              @logger.debug 'FAILED cdna change parse for: ' \
                            "#{record.raw_fields['codingdnasequencechange']}"
              genotype.add_status(:negative) # Added after coding
              @failed_genotype_counter += 1
              @negative_test += 1
            end
          end

          def non_pathogenic_status?(genotype, variantpathclass)
            if [1, 2].include?(variantpathclass)
              genotype.add_status(10)
            else
              genotype.add_status(:positive) # Added after coding
              @positive_test += 1
            end
          end

          def add_protein_impact(genotype, record)
            case record.raw_fields['proteinimpact']
            when PROTEIN_REGEX
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug 'SUCCESSFUL protein change parse for: ' \
                            "#{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug 'FAILED protein change parse for: ' \
                            "#{record.raw_fields['proteinimpact']}"
            end
          end

          def process_genomic_change(genotype, record)
            genomic_change = record.raw_fields['genomicchange']
            case genomic_change
            when /NC_0+(?<chr_num>\d+)\.\d+:g\.(?<genomicchange>.+)/i
              genotype.add_parsed_genomic_change($LAST_MATCH_INFO[:chr_num].to_i,
                                                 $LAST_MATCH_INFO[:genomicchange])
              @logger.debug 'SUCCESSFUL chromosome change parse for: ' \
                            "#{$LAST_MATCH_INFO[:chr_num]} and #{$LAST_MATCH_INFO[:genomicchange]}"
            when nil
              @logger.warn 'Genomic change was empty'
            else
              @logger.warn 'Genomic change did not match expected format,' \
                           "adding raw: #{genomic_change}"
              genotype.add_raw_genomic_change(genomic_change)
            end
          end

          def process_gene(genotype, record)
            gene = record.mapped_fields['gene'].to_i
            case gene
            when Integer
              if (7..8).cover? gene
                genotype.add_gene(record.mapped_fields['gene'].to_i)
                @successful_gene_counter += 1
                @logger.debug 'SUCCESSFUL gene parse for: ' \
                              "#{record.mapped_fields['gene'].to_i}"
              else
                @logger.debug 'FAILED gene parse for: ' \
                              "#{record.mapped_fields['gene'].to_i}"
                @failed_gene_counter += 1
              end
            end
          end

          def add_zygosity(genotype, record)
            zygosity = record.raw_fields['variantgenotype'] # unless zygosity.nil?
            case zygosity
            when '0/1'
              genotype.add_zygosity('het')
              @logger.debug 'SUCCESSFUL zygosity parse for: ' \
                            "#{record.raw_fields['variantgenotype'].to_str}"
            when '0/0'
              genotype.add_zygosity('homo')
              @logger.debug 'SUCCESSFUL zygosity parse for: ' \
                            "#{record.raw_fields['variantgenotype'].to_str}"
            else
              @logger.debug "Cannot determine zygosity; perhaps should be complex? #{zygosity}"
            end
          end

          def process_exons(genotype_string, genotype)
            exon_matches = EXON_LOCATION_REGEX.match(genotype_string)
            if exon_matches
              genotype.add_exon_location(exon_matches[1].delete(' '))
              genotype.add_variant_type(genotype_string)
              @logger.debug "SUCCESSFUL exon extraction for: #{genotype_string}"
            else
              @logger.warn "Cannot extract exon from: #{genotype_string}"
            end
          end

          def summarize
            @logger.info '***************** Handler Report *******************'
            @logger.info "Num genes failed to parse: #{@failed_gene_counter} of " \
                         "#{@persister.genetic_tests.values.flatten.size} tests being attempted"
            @logger.info "Num genes successfully parsed: #{@successful_gene_counter} of" \
                         "#{@persister.genetic_tests.values.flatten.size} attempted"
            @logger.info "Num genotypes failed to parse: #{@failed_genotype_counter}" \
                         "of #{@lines_processed} attempted"
            @logger.info "Num positive tests: #{@positive_test}" \
                         "of #{@persister.genetic_tests.values.flatten.size} attempted"
            @logger.info "Num negative tests: #{@negative_test}" \
                         "of #{@persister.genetic_tests.values.flatten.size} attempted"
          end
        end
      end
    end
  end
end
