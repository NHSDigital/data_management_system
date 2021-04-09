require 'possibly'
require 'pry'

module Import
  module Brca
    module Providers
      module Birmingham
        # Process Birmingham-specific record details into generalized internal genotype format
        class BirminghamHandler < Import::Brca::Core::ProviderHandler
          TEST_SCOPE_MAP = { 'diagnosis'           => :full_screen,
                             'diagnosis (2)'       => :full_screen,
                             'mainstreaming test'  => :full_screen,
                             'indirect testing'    => :full_screen,
                             'presymptomatic'      => :targeted_mutation,
                             'presymptomatic mlpa' => :targeted_mutation,
                             'confirmation'        => :targeted_mutation,
                             'mlpa only'           => :targeted_mutation,
                             'family studies'      => :targeted_mutation,
                             'ajp confirmation'    => :aj_screen }.freeze

          TEST_TYPE_MAP = {  'confirmation' => :diagnostic,
                             'diagnosis' => :diagnostic,
                             'diagnosis (2)' => :diagnostic,
                             'ajp confirmation' => :diagnostic,
                             'mainstreaming test' => :diagnostic,
                             'presymptomatic' => :predictive,
                             'presymptomatic mlpa' => :predictive,
                             'indirect testing' => :predictive,
                             'family studies' => :predictive,
                             'mlpa only' => nil }.freeze
          PASS_THROUGH_FIELDS = %w[age gene
                                   geneticabberrationtype
                                   authoriseddate
                                   consultantcode
                                   servicereportidentifier
                                   providercode
                                   requesteddate
                                   practitionercode
                                   geneticaberrationtype].freeze

          CDNA_REGEX = /c\.(?<cdna>.*)/i.freeze

          def initialize(batch)
            @ex = Import::ExtractionUtilities::LocationExtractor.new
            @failed_genotype_parse_counter = 0
            @genotype_counter = 0
            super
          end

          def process_fields(record)
            @lines_processed += 1
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)

            # TODO: reference transcript id - do we pass this through as is?
            #  Maybe(record.mapped_fields['codingdnasequencechange']).each do |cdna|
            #    @failed_genotype_parse_counter += genotype.add_typed_location(@ex.extract_type(cdna))
            #  end
            process_cdna_change(genotype, record)
            process_impact(genotype, record)
            process_genomic_change(genotype, record)
            process_test_scope_and_type(genotype, record)
            add_organisationcode_testresult(genotype)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699F0'
          end

          # TODO: this same parser occurs in Cambridge as well - should find a nice
          #       way to factor them out, preferably without putting them in Genotype
          def process_genomic_change(genotype, record)
            genomic_change = record.raw_fields['genomicchange']
            case genomic_change.strip
            when /NC_0*(?<chr_num>\d+)\.\d+:g\.(?<genomicchange>.+)/i
              genotype.add_parsed_genomic_change($LAST_MATCH_INFO[:chr_num].to_i,
                                                 $LAST_MATCH_INFO[:genomicchange])
            when nil, ''
              @logger.warn 'Genomic change was empty'
            else
              @logger.warn 'Genomic change did not match expected format,'\
                           "adding raw: #{genomic_change}"
              genotype.add_raw_genomic_change(genomic_change)
            end
          end

          def process_impact(genotype, record)
            Maybe(record.mapped_fields['proteinimpact']).each do |protein|
              case protein
              when /p\.\((?<impact>.+)\)/
                genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              else
                @logger.warn "Could not parse impact: #{protein}"
              end
              # TODO: possibly do some validation here, but less critical
              genotype.add_protein_impact(protein)
            end
          end

          # def process_cdna_change(genotype, record)
          #  case record.mapped_fields['codingdnasequencechange']
          #    when CDNA_REGEX
          #    genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
          #    @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
          #    @positive_test += 1
          #    genotype.add_status(:positive) #Added after coding
          #  else
          #    @logger.debug 'FAILED cdna change parse for:' \
          #                   "#{record.raw_fields['codingdnasequencechange']}"
          #    genotype.add_status(:negative) #Added after coding
          #    @failed_genotype_counter += 1
          #    @negative_test += 1
          #  end
          # end

          def process_test_scope_and_type(genotype, record)
            # TODO: see Fiona about details for genomic change format
            Maybe(record.mapped_fields['genetictestscope']).each do |ttype|
              # TODO: do we trust the provided mapping?? And is scope useful beyond this?
              genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[ttype.strip.downcase])
              scope = TEST_SCOPE_MAP[ttype.strip.downcase]
              genotype.add_test_scope(scope) if scope
            end
          end

          def process_cdna_change(genotype, record)
            case record.mapped_fields['codingdnasequencechange']
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
              genotype.add_status(:positive) # Added after coding
            else
              @logger.debug 'FAILED cdna change parse for: '\
                            "#{record.mapped_fields['codingdnasequencechange']}"
              genotype.add_status(:negative) # Added after coding
            end
          end

          def summarize
            @logger.info '***************** Handler Report ******************'
            @logger.info "Num failed genotype parses: #{@failed_genotype_parse_counter}"\
                         "of #{@genotype_counter}"
            @logger.info "Total lines processed: #{@lines_processed}"
          end
        end
      end
    end
  end
end
