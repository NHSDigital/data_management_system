require 'possibly'

module Import
  module Colorectal
    module Providers
      module Nottingham
        # Process Nottingham-specific record details into generalized internal genotype format
        class NottinghamHandlerColorectal < Import::Brca::Core::ProviderHandler
          include ExtractionUtilities
          TEST_TYPE_MAP_COLO = { 'confirmation' => :diagnostic,
                                 'confirmation of familial mutation' => :diagnostic,
                                 'diagnostic' => :diagnostic,
                                 'family studies' => :predictive,
                                 'predictive' => :predictive,
                                 'indirect' => :predictive } .freeze

          PASS_THROUGH_FIELDS_COLO = %w[age authoriseddate
                                        receiveddate
                                        specimentype
                                        providercode
                                        consultantcode
                                        servicereportidentifier] .freeze

          NEGATIVE_TEST = /Normal/i . freeze
          COLORECTAL_GENES_REGEX = /(?<colorectal>APC|
                                                BMPR1A|
                                                EPCAM|
                                                MLH1|
                                                MSH2|
                                                MSH6|
                                                MUTYH|
                                                PMS2|
                                                POLD1|
                                                POLE|
                                                PTEN|
                                                SMAD4|
                                                STK11)/xi . freeze # Added by
          VARPATHCLASS_REGEX = /(?<varpathclass>[0-9](?=\:))/ .freeze

          CDNA_REGEX = /c\.(?<cdna>[0-9]+[A-Za-z]+>[A-Za-z]+)|
                        c\.(?<cdna>[0-9]+.(?:[0-9]+)[A-Za-z]+>[A-Z]+)|
                        c\.(?<cdna>[0-9]+.[0-9].[0-9]+.[0-9][A-Za-z]+)|
                        c\.(?<cdna>[0-9]+[A-Za-z]+)|
                        c\.(?<cdna>[0-9]+.[0-9]+[A-Za-z]+)|
                        c\.(?<cdna>.[0-9]+[A-Za-z]+>[A-Za-z]+)|
                        c\.(?<cdna>.[\W][0-9]+[\W]+[0-9]+[a-z]+)/ix .freeze

          ADHOC_CDNA_REGEX = /c\.(?<cdna>[\W][0-9]+..[0-9]+[a-z]+)|
                              c\.(?<cdna>[\W][0-9]+[a-z]+)|
                              c\.(?<cdna>[0-9]+.[0-9]+.[0-9]+.[0-9]+[a-z]+)/xi .freeze

          SPACE_CDNA_REGEX = /c\.(?<cdna>.+\s[A-Z]>[A-Z])/i .freeze

          PROTEIN_IMPACT_REGEX = /p\.\((?<impact>.+)\)/i .freeze

          def initialize(batch)
            @failed_genotype_parse_counter = 0
            @genotype_counter = 0
            @ex = LocationExtractor.new
            super
          end

          def process_fields(record)
            @lines_processed += 1
            genotype = Import::Colorectal::Core::Genocolorectal.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS_COLO)
            add_test_type(genotype, record)
            add_scope(genotype, record)
            add_variant(genotype, record)
            add_protein_impact(genotype, record)
            # process_gene(genotype, record) # Added by Francesco
            process_gene_colorectal(genotype, record) # Added by Francesco
            extract_variantclass_from_genotype(genotype, record) # Added by Francesco
            extract_teststatus(genotype, record) # added by Francesco
            add_organisationcode_testresult(genotype)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '698A0'
          end

          def add_test_type(genotype, record)
            testingtype = record.raw_fields['moleculartestingtype'].downcase
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[testingtype.strip])
          end

          def add_scope(genotype, record)
            Maybe(record.raw_fields['disease']).each do |disease|
              case disease.downcase.strip
              when 'bowel cancer panel'
                genotype.add_test_scope(:full_screen)
              when 'hereditary non-polyposis colorectal cancer'
                genotype.add_test_scope(:full_screen)
              when 'hnpcc pst'
                genotype.add_test_scope(:targeted_mutation)
              else @logger.debug 'UNSUCCESSFUL TEST SCOPE PARSE'
              end
            end
          end

          def add_variant(genotype, record)
            geno = record.raw_fields['genotype']
            case geno
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            when ADHOC_CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            when SPACE_CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            else
              @logger.debug 'UNSUCCESSFUL CDNA CHANGE PARSE'
            end
          end

          def add_protein_impact(genotype, record)
            protein = record.raw_fields['genotype']
            case protein
            when PROTEIN_IMPACT_REGEX
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
            else
              @logger.debug 'UNSUCCESSFUL PROTEIN CHANGE PARSE'
            end
          end

          def extract_teststatus(genotype, record)
            case record.raw_fields['teststatus'].to_s.downcase
            when /normal|completed|not pathogenic/i
              genotype.add_status(:negative)
            when ''
              genotype.add_status(:negative)
            else genotype.add_status(:positive)
            end
          end

          def extract_variantclass_from_genotype(genotype, record)
            varpathclass_field = record.raw_fields['teststatus'].to_s.downcase
            case varpathclass_field
            when VARPATHCLASS_REGEX
              genotype.add_variant_class($LAST_MATCH_INFO[:varpathclass].to_i) \
                       unless varpathclass_field.nil?
              @logger.debug "SUCCESSFUL VARPATHCLASS parse for: #{$LAST_MATCH_INFO[:varpathclass]}"
            else
              @logger.debug "FAILED VARPATHCLASS parse for: #{record.raw_fields['teststatus']}"
            end
          end

          # def process_gene(genotype,record) # Added by Francesco
          #   gene = record.mapped_fields['gene'].to_i # Added by Francesco
          #   Genotype.add_gene(gene) unless gene.nil? # Added by Francesco
          # end

          def process_gene_colorectal(genotype, record)
            colorectal_input = record.raw_fields['gene']
            case colorectal_input
            when COLORECTAL_GENES_REGEX
              genotype.add_gene_colorectal(colorectal_input)
              @logger.debug "SUCCESSFUL COLORECTAL gene parse for: #{record.raw_fields['gene']}"
            else
              @logger.debug "FAILED COLORECTAL gene parse for: #{record.raw_fields['gene']}"
            end
          end

          def summarize
            @logger.info '***************** Handler Report ******************'
            @logger.info "Num failed genotype parses: #{@failed_genotype_parse_counter}"\
            'of #{@genotype_counter}'
            @logger.info "Total lines processed: #{@lines_processed}"
          end
        end
      end
    end
  end
end
