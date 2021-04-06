require 'pry'
require 'possibly'

module Import
  module Brca
    module Providers
      module Sheffield
        # Process Sheffield-specific record details into generalized internal genotype format
        class SheffieldHandlerDeprecated < Import::Brca::Core::ProviderHandler
          TEST_SCOPE_MAPPING = { 'BRCA1 and 2 familial mutation' => :targeted_mutation,
                                 'BRCA1 and 2 gene analysis' => :full_screen,
                                 'Breast & Ovarian cancer panel' => :full_screen,
                                 'Breast Ovarian & Colorectal cancer panel' => :full_screen } .freeze

          TEST_TYPE_MAPPING = { 'Further sample as requested' => :diagnostic,
                                'Diagnostic testing' => :diagnostic,
                                'Further sample for diagnostic testing' => :diagnostic,
                                'Confirmation of Familial Mutation' => :diagnostic,
                                'Confirmation of Research Result' => :diagnostic,
                                'Diagnostic testing for known mutation' => :diagnostic,
                                'Predictive testing' => :predictive,
                                'Family Studies' => :predictive } .freeze

          PASS_THROUGH_FIELDS = %w[consultantcode
                                   providercode
                                   collecteddate
                                   receiveddate
                                   authoriseddate
                                   servicereportidentifier
                                   genotype
                                   age].freeze

          #    MUTATION_REGEX = "c.\[(?<cdna>[^\]]+)\];\[=\], p.(?:\[\(?(?<protein>[^\)\]]+)\)?\]|\[(?<protein>[^\]\)]+)\]);(?:\[\(=\)\]|\[=\])" .freeze
          MUTATION_REGEX = /c.\[(?<cdna>[^\]]+)\];\[=\], p.(?:\[\(?(?<impact>[^\)\]]+)\)?\]|\[(?<impact>[^\]\)]+)\]);(?:\[\(=\)\]|\[=\]) | *p\.\[\((?<impact>[^ ]+(?=\)\];))/.freeze

          def initialize(batch)
            @failed_genotype_counter = 0
            @gene_counter = 0
            @failed_gene_counter = 0
            super
          end

          def process_fields(record)
            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            genotype = Import::Brca::Core::Genotype.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            variant_class = record.raw_fields['assigned pathogenicity score']
            genotype.add_variant_class(variant_class) unless variant_class.nil?
            mtype = record.raw_fields['moleculartestingtype']
            genotype.add_molecular_testing_type_strict(TEST_TYPE_MAPPING[mtype.downcase.strip])

            process_raw_genotype(genotype, record)
            res = process_gene(genotype, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def process_raw_genotype(genotype, record)
            case record.raw_fields['genotype']
            when /no pathogenic mutation (?:was )?detected/i
              genotype.add_status(1)
            when /familial pathogenic mutation not detected/i
              genotype.add_status(1)
            when MUTATION_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              genotype.add_protein_impact($LAST_MATCH_INFO[:protein])
              genotype.add_status(2)
            else
              @logger.debug "FAILED genotype parse for: #{record.raw_fields['genotype']}"
              @failed_genotype_counter += 1
            end
          end

          def process_gene(genotype, record)
            gene_string = record.raw_fields['gene']
            case gene_string
            when String
              @gene_counter += 1
              brca_base = 'br?c?a?'
              case gene_string
              when /#{brca_base}1 and #{brca_base}2/i, /#{brca_base}2 and #{brca_base}1/i then
                genotype.add_test_scope(:full_screen)
                genotype2 = genotype.dup
                genotype.add_gene(1)
                genotype2.add_gene(2)
                [genotype, genotype2]
              when /#{brca_base}(?<brca_num>1|2)/i then
                genotype.add_test_scope(:targeted_mutation)
                genotype.add_gene($LAST_MATCH_INFO[:brca_num].to_i)
                [genotype]
              else
                @failed_gene_counter += 1
                @logger.debug "FAILED gene parse for: #{geneString}"
                [genotype]
              end
            when nil
              @logger.error 'Gene field absent for this record; cannot process'
              [genotype]
            end
          end

          def summarize
            @logger.info '***************** Handler Report *******************'
            @logger.info "Num genes failed to parse: #{@failed_gene_counter} of"\
                         "#{@gene_counter} attempted"
            @logger.info "Num genotypes failed to parse: #{@failed_genotype_counter}"\
                         "of #{@lines_processed} attempted"
          end
        end
      end
    end
  end
end
