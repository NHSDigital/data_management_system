require 'possibly'

module Import
  module Brca
    module Providers
      module Nottingham
        # Process Nottingham-specific record details into generalized internal genotype format
        class NottinghamHandlerDeprecated < Import::Brca::Core::ProviderHandler
          include Utility
          TEST_TYPE_MAP = { 'confirmation'   => :diagnostic,
                            'diagnostic'     => :diagnostic,
                            'predictive'     => :predictive,
                            'family studies' => :predictive,
                            'indirect'       => :predictive } .freeze
          PASS_THROUGH_FIELDS = %w[age authoriseddate
                                   receiveddate
                                   specimentype
                                   providercode
                                   consultantcode
                                   servicereportidentifier].freeze

          NEGATIVE_TEST = /Normal/i.freeze

          def initialize(batch)
            @failed_genotype_parse_counter = 0
            @genotype_counter = 0
            @ex = LocationExtractor.new
            super
          end

          def process_fields(record)
            @lines_processed += 1
            genotype = Import::Brca::Core::Genotype.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            add_simple_fields(genotype, record)
            add_complex_fields(genotype, record)
            extract_teststatus(genotype, record) # added by Francesco
            @persister.integrate_and_store(genotype)
          end

          def add_simple_fields(genotype, record)
            testingtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[testingtype.downcase.strip])
            gene = record.raw_fields['gene']
            genotype.add_gene(gene) unless gene.nil?
            variant_path_class = record.raw_fields['assigned pathogenicity score']
            genotype.add_variant_class(variant_path_class.downcase) unless variant_path_class.nil?
            received_date = record.raw_fields['sample received in lab date']
            genotype.add_received_date(received_date.downcase) unless received_date.nil?
          end

          def add_complex_fields(genotype, record)
            Maybe(record.raw_fields['disease']).each do |disease|
              case disease.downcase.strip
              when 'hereditary breast and ovarian cancer (brca1/brca2)'
                genotype.add_test_scope(:full_screen)
              when 'brca1/brca2 pst'
                genotype.add_test_scope(:targeted_mutation)
              end
            end
            Maybe(record.raw_fields['genotype']).each do |geno|
              @genotype_counter += 1
              @failed_genotype_parse_counter += genotype.add_typed_location(@ex.extract_type(geno))
            end
          end

          def extract_teststatus(genotype, record)
            case record.raw_fields['teststatus']
            when NEGATIVE_TEST
              genotype.add_status(:negative)
            else genotype.add_status(:positive)
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
