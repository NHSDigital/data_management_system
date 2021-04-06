require 'pry'
require 'possibly'

module Import
  module Brca
    module Providers
      module Sheffield
        # Process Sheffield-specific record details into generalized internal genotype format
        class SheffieldHandlerNew2 < Import::Brca::Core::ProviderHandler
          TEST_SCOPE_MAPPING = { 'BRCA1 and 2 familial mutation' => :targeted_mutation,
                                 'Breast & Ovarian cancer panel' => :full_screen,
                                 'Breast Ovarian & Colorectal cancer panel' => :full_screen,
                                 'Confirmation of Familial Mutation' => :targeted_mutation,
                                 'Diagnostic testing for known mutation' => :targeted_mutation,
                                 'Confirmation of Research Result' => :targeted_mutation,
                                 'Predictive testing' => :targeted_mutation,
                                 'Family Studies' => :targeted_mutation } .freeze

          TEST_TYPE_MAPPING = { 'Diagnostic testing' => :diagnostic,
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

          BRCA_REGEX = /(?<brca>BRCA[0-9]).+/i.freeze
          NEW_BRCA = /(?<brca>^BRCA[0-9])[^2]*\z/i.freeze
          # WRONG_BRCA = /(BRCA1).+*(BRCA2)/i
          CDNA_REGEX = /c.\[(?<cdna>[^\]]+)\];\[=\] | *c.\[(?:\()(?<cdna>[^\]]+)\](?:\));\[=\], | *c.\[(?<cdna>[^.]+)\];\[=\],/i.freeze
          PROTEIN_REGEX = / p.(?:\[\(?(?<impact>[^\)\]]+)\)?\]|\[(?<impact>[^\]\)]+)\]);(?:\[\(=\)\]|\[=\]) | *p\.\[\((?<impact>[^ ]+(?=\)\];))/.freeze
          EXON_LOCATION_REGEX = /exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?)/i.freeze
          DEL_DUP_REGEX = /(?:\W*(del)(?:etion|[^\W])?)|(?:\W*(dup)(?:lication|[^\W])?)/i.freeze

          def initialize(batch)
            @failed_genotype_counter = 0
            @successful_gene_counter = 0
            @gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          def process_fields(record)
            genotype = Import::Brca::Core::Genotype.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            process_cdna_change(genotype, record)
            process_protein_impact(genotype, record)
            # process_test_type(genotype,record)
            add_test_scope(genotype, record)
            add_test_type(genotype, record)
            # add_test_scope_from_type(genotype,record)
            add_test_scope_from_karyo(genotype, record)
            process_gene(genotype, record)
            process_exons(record.raw_fields['genotype'], genotype)
            @persister.integrate_and_store(genotype)
            # @lines_processed += 1 # TODO: factor this out to be automatic across handlers
          end

          def add_test_scope(genotype, record)
            Maybe(record.mapped_fields['genetictestscope']).each do |scope|
              @logger.debug 'PERFORMING TEST for function add_test_scope'
              @logger.debug "PERFORMING TEST for: #{record.raw_fields['genetictestscope']}"
              case scope
              when 'BRCA1 and 2 familial mutation'
                genotype.add_test_scope(:targeted_mutation)
                @logger.debug "ADDED TARGETED TEST for: #{record.mapped_fields['genetictestscope']}"
                # when 'BRCA1 and 2 gene analysis'
                #  genotype.add_test_scope(:full_screen)
              when 'Breast & Ovarian cancer panel'
                genotype.add_test_scope(:full_screen)
                @logger.debug "ADDED FULL_SCREEN TEST for: #{record.mapped_fields['genetictestscope']}"
              when 'Breast Ovarian & Colorectal cancer panel'
                genotype.add_test_scope(:full_screen)
                @logger.debug "ADDED FULL_SCREEN TEST for: #{record.mapped_fields['genetictestscope']}"
              end
            end
          end

          #    def add_test_scope_from_type(genotype, record)
          #      Maybe(record.raw_fields['moleculartestingtype']).each do |scope_from_type|
          #        case scope_from_type
          #        when 'Confirmation of Familial Mutation'
          #          genotype.add_test_scope(:targeted_mutation)
          #        when 'Confirmation of Research Result'
          #          genotype.add_test_scope(:targeted_mutation)
          #        when 'Diagnostic testing for known mutation'
          #          genotype.add_test_scope(:targeted_mutation)
          #        when 'Predictive testing'
          #          genotype.add_test_scope(:targeted_mutation)
          #        when 'Family Studies'
          #          genotype.add_test_scope(:targeted_mutation)
          #        end
          #      end
          #    end

          # def add_test_scope_from_karyo(genotype, record)
          #   Maybe(record.raw_fields['karyotypingmethod']).each do |scope_from_karyo|
          #     case scope_from_karyo
          #     when 'BRCA1 and 2 gene sequencing'
          #       genotype.add_test_scope(:full_screen)
          #     when 'Full Screen'
          #       genotype.add_test_scope(:full_screen)
          #     end
          #   end
          # end

          def add_test_scope_from_karyo(genotype, record)
            geno = record.mapped_fields['genetictestscope']
            karyo = record.raw_fields['karyotypingmethod']
            @logger.debug 'PERFORMING TEST for function add_test_scope_from_karyo'
            @logger.debug "PERFORMING TEST for: #{record.raw_fields['karyotypingmethod']}"
            @logger.debug "PERFORMING TEST for: #{record.raw_fields['genetictestscope']}"
            if (geno == 'BRCA1 and 2 gene analysis' && karyo == 'BRCA1 and 2 gene sequencing') || (geno == 'BRCA1 and 2 gene analysis' && karyo == 'Full Screen')
              @logger.debug "ADDED FULL_SCREEN TEST for: #{record.raw_fields['karyotypingmethod']}"
              genotype.add_test_scope(:full_screen)
            else
              if (geno == 'BRCA1 and 2 gene analysis' && karyo != 'BRCA1 and 2 gene sequencing') || (geno == 'BRCA1 and 2 gene analysis' && karyo != 'Full Screen')
                @logger.debug "ADDED TARGETED TEST for: #{record.raw_fields['karyotypingmethod']}"
                genotype.add_test_scope(:targeted_mutation)
              end
            end
          end

          #  def process_test_type(genotype, record)
          #    Maybe(record.raw_fields['moleculartestingtype']).each do |ttype|
          #      genotype.add_molecular_testing_type_strict(TEST_TYPE_MAPPING[ttype.strip.downcase])
          #     end
          #  end

          def add_test_type(genotype, record)
            Maybe(record.raw_fields['moleculartestingtype']).each do |type|
              case type
              when 'Diagnostic testing'
                genotype.add_molecular_testing_type_strict(:diagnostic)
              when 'Confirmation of Familial Mutation'
                genotype.add_molecular_testing_type_strict(:diagnostic)
              when 'Confirmation of Research Result'
                genotype.add_molecular_testing_type_strict(:diagnostic)
              when 'Further sample for diagnostic testing'
                genotype.add_molecular_testing_type_strict(:diagnostic)
              when 'Diagnostic testing for known mutation'
                genotype.add_molecular_testing_type_strict(:diagnostic)
              when 'Predictive testing'
                genotype.add_molecular_testing_type_strict(:predictive)
              when 'Family Studies'
                genotype.add_molecular_testing_type_strict(:predictive)
              end
            end
          end

          def process_cdna_change(genotype, record)
            case record.raw_fields['genotype']
            when /No mutation detected/
              genotype.add_status(:negative)
            when %r{No pathogenic deletion/duplication mutation detected}
              genotype.add_status(:negative)
            when /No pathogenic mutation detected/i
              genotype.add_status(:negative)
              @negative_test += 1
            when /No pathogenic muatation detected/i
              genotype.add_status(:negative)
              @negative_test += 1
            when /No pathogenic mutation detected - incomplete analysis/i
              genotype.add_status(:negative)
              @negative_test += 1
            when /No pathogenic mutation detected./i
              genotype.add_status(:negative)
              @negative_test += 1
            when /No pathogenic mutation deteected/i
              genotype.add_status(:negative)
              @negative_test += 1
            when /No pathogenic mutation was detected/i
              genotype.add_status(:negative)
              @negative_test += 1
            when /No pathogenic mutations detected/i
              genotype.add_status(:negative)
              @negative_test += 1
            when /familial pathogenic mutation not detected/i
              genotype.add_status(:negative)
              @negative_test += 1
            when /Incomplete analysis - see below/i
              genotype.add_status(:negative)
              @negative_test += 1
            when /Familial pathogenic mutation NOT detected/i
              genotype.add_status(:negative)
              @negative_test += 1
            when /Familial pathogenic mutation not detected/i
              genotype.add_status(:negative)
              @negative_test += 1
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
              genotype.add_status(:positive)
              @positive_test += 1
            else
              @logger.debug "FAILED cdna change parse for: #{record.raw_fields['genotype']}"
              @failed_genotype_counter += 1
            end
          end

          def process_protein_impact(genotype, record)
            case record.raw_fields['genotype']
            when PROTEIN_REGEX
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug "FAILED protein change parse for: #{record.raw_fields['genotype']}"
            end
          end

          def process_gene(genotype, record)
            #   | unless record.raw_fields['karyotypingmethod'].nil?
            # unless record.raw_fields['karyotypingmethod'].nil?
            if BRCA_REGEX.match(record.raw_fields['genotype'])
              genotype.add_gene($LAST_MATCH_INFO[:brca])
              @successful_gene_counter += 1
              @gene_counter += 1
              @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:brca]}"
            elsif NEW_BRCA.match(record.raw_fields['karyotypingmethod'])
              genotype.add_gene($LAST_MATCH_INFO[:brca])
              @successful_gene_counter += 1
              @gene_counter += 1
              @logger.debug "SBADIBI for #{$LAST_MATCH_INFO[:brca]} "
            else
              @logger.debug 'FAILED gene parse'
              @logger.debug "FAILED gene parse for: #{record.raw_fields['karyotypingmethod']} and/or #{record.raw_fields['genotype']}"
              @failed_gene_counter += 1
              @gene_counter += 1
            end
          end

          # def process_gene(genotype, record)
          #  case record.raw_fields['genotype']
          #  when BRCA_REGEX
          #   genotype.add_gene($LAST_MATCH_INFO[:brca])
          #   @successful_gene_counter += 1
          #   @gene_counter += 1
          #   @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:brca]}"
          # else
          #   @logger.debug "FAILED gene parse for: #{record.raw_fields['genotype']}"
          #   @failed_gene_counter += 1
          #   @gene_counter += 1
          # end
          # end

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

          # def process_gene(genotype, record)
          #     gene_string = record.raw_fields['gene']
          #     case gene_string
          #     when String
          #      @gene_counter += 1
          #       brca_base = 'br?c?a?'
          #       case gene_string
          #      when /#{brca_base}1 and #{brca_base}2/i, /#{brca_base}2 and #{brca_base}1/i then
          #        #genotype.add_test_scope(:full_screen)
          #         genotype2 = genotype.dup
          #         genotype.add_gene(1)
          #        genotype2.add_gene(2)
          #        [genotype, genotype2]
          #       when /#{brca_base}(?<brca_num>1|2)/i then
          #         #genotype.add_test_scope(:targeted_mutation)
          #         genotype.add_gene($LAST_MATCH_INFO[:brca_num].to_i)
          #       [genotype]
          #      else
          #        @failed_gene_counter += 1
          #        @logger.debug "FAILED gene parse for: #{geneString}"
          #        [genotype]
          #       end
          #     when nil
          #       @logger.error 'Gene field absent for this record; cannot process'
          #             [genotype]
          #     end
          #   end

          def summarize
            @logger.info '***************** Handler Report *******************'
            @logger.info "Num genes failed to parse: #{@failed_gene_counter} of "\
                         "#{@persister.genetic_tests.values.flatten.size} tests being attempted"
            @logger.info "Num genes successfully parsed: #{@successful_gene_counter} of"\
                          "#{@persister.genetic_tests.values.flatten.size} attempted"
            @logger.info "Num genotypes failed to parse: #{@failed_genotype_counter}"\
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
