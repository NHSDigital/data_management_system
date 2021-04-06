require 'possibly'

module Import
  module Brca
    module Providers
      module Salisbury

        # Process Salisbury-specific record details into generalized internal genotype format
        class SalisburyHandler < Import::Brca::Core::ProviderHandler
          TEST_SCOPE_MAPPING = { 'breast cancer full screen'           => :full_screen,
                                 'breast cancer full screen data only' => :full_screen,
                                 'brca mainstreaming'                  => :full_screen,
                                 'breast cancer predictives'           => :targeted_mutation,
                                 'brca mlpa only'                      => :targeted_mutation,
                                 'brca ashkenazi mutations'            => :aj_screen } .freeze
          TEST_TYPE_MAPPING = { 'breast cancer full screen'           => :diagnostic,
                                'breast cancer full screen data only' => :diagnostic,
                                'brca mainstreaming'                  => :diagnostic,
                                'brca mlpa only'                      => :predictive,
                                'breast cancer predictives'           => :predictive,
                                'brca ashkenazi mutations'            => nil } .freeze

          PASS_THROUGH_FIELDS = %w[age consultantcode
                                   servicereportidentifier
                                   providercode
                                   authoriseddate
                                   requesteddate] .freeze

          POSITIVE_TEST = /variant|pathogenic|deletion/i.freeze
          FAILED_TEST = /Fail*+/i.freeze
          GENE_REGEX = /B(?:R)?(?:C)?(?:A)?(1|2)(?:_(\d*[A-Z]*))?/i.freeze
          GENE_LOCATION_REGEX = /.*c\.(?<gene>[^ ]+)(?: p\.\((?<protein>.*)\))?.*/i.freeze
          EXON_LOCATION_REGEX = /exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?)/i.freeze
          # TODO: make this more conservative
          DEL_DUP_REGEX = /(?:\W*(del)(?:etion|[^\W])?)|(?:\W*(dup)(?:lication|[^\W])?)/i.freeze

          def initialize(batch)
            super
            @logger.level = Logger::INFO
          end

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            extract_gene(record.raw_fields['test'], genotype)
            extract_variant(record.raw_fields['genotype'], genotype)
            Maybe(record.raw_fields['moleculartestingtype']).each do |ttype|
              genotype.add_molecular_testing_type_strict(TEST_TYPE_MAPPING[ttype])
              scope = TEST_SCOPE_MAPPING[ttype.downcase.strip]
              genotype.add_test_scope(scope) if scope
            end
            extract_teststatus(genotype, record)
            add_organisationcode_testresult(genotype)
            genotype.add_specimen_type(record.mapped_fields['specimentype'])
            genotype.add_received_date(record.raw_fields['date of receipt'])
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            @persister.integrate_and_store(genotype)
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699H0'
          end

          def extract_gene(test_string, genotype)
            if test_string.scan(GENE_REGEX).size > 1
              @logger.error "Multiple genes detected in input string: #{test_string};"\
                            'record will be incomplete!'
            end
            Maybe(GENE_REGEX.match(test_string)).
              map { |match|  match[1].to_i }.
              map { |gene|   genotype.add_gene(gene) }
            #       map { |gene|   genotype.add_gene(gene) }.
            #       or_else { @logger.error "Cannot extract gene name from raw test: #{test_string}" }
          end

          def extract_teststatus(genotype, record)
            if POSITIVE_TEST.match(record.raw_fields['status'])
              genotype.add_status(:positive)
              @logger.debug "POSITIVE status for : #{record.raw_fields['status']}"
            elsif FAILED_TEST.match(record.raw_fields['status'])
              genotype.add_status(:failed)
              @logger.debug "FAILED status for : #{record.raw_fields['status']}"
            else genotype.add_status(:negative)
            end
          end

          def extract_variant(genotype_string, genotype)
            matches = GENE_LOCATION_REGEX.match(genotype_string)
            exon_matches = EXON_LOCATION_REGEX.match(genotype_string)
            if genotype_string.blank?
              genotype.set_negative # TODO: what is the desired value to put in here? Negative?
              return
            end
            if matches
              genotype.add_gene_location(matches[:gene]) if matches[1]
              @logger.debug "SUCCESSFUL cdna change parse for: #{matches[:gene]}"
              genotype.add_protein_impact(matches[:protein]) if matches[2]
              @logger.debug "SUCCESSFUL protein impact parse for: #{matches[:protein]}"
            elsif exon_matches
              genotype.add_exon_location(exon_matches[1].delete(' '))
              genotype.add_variant_type(genotype_string)
            else
              @logger.warn "Cannot extract gene location from raw test: #{genotype_string}"
            end
          end

        end
      end
    end
  end
end
