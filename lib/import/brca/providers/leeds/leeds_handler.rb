require 'pry'

module Import
  module Brca
    module Providers
      module Leeds
        # Process Leeds-specific record details into generalized internal genotype format
        class LeedsHandler < Import::Brca::Core::ProviderHandler
          include Import::Helpers::Brca::Providers::Rr8::Rr8Constants
          include Import::Helpers::Brca::Providers::Rr8::Rr8Helper
          
          # FIELD_NAME_MAPPINGS = { 'consultantcode'  => 'practitionercode',
          #                         'instigated_date' => 'requesteddate' }.freeze
          # CDNA_REGEX = /c\.(?<cdna>[0-9]+.>[A-Za-z]+)|c\.(?<cdna>[0-9]+.[0-9]+[A-Za-z]+)/i.freeze
          # PROTEIN_REGEX = /\(?p\.\(?(?<impact>.\w+\d+\w+)\)/i.freeze
          # BRCA1_REGEX = /B1/i.freeze
          # BRCA2_REGEX = /B2/i.freeze
          # TESTSTATUS_REGEX = /unaffected|neg|normal/i.freeze
          # GENE_CDNA_PROTEIN_REGEX = /(?<brca> BRCA(1|2)) variant (c\.(?<cdna>[0-9]+.>[A-Za-z]+)|c\.(?<cdna>[0-9]+.[0-9]+[A-Za-z]+)) (?:p\.\((?<impact>.\w+\d+\w+)\))|(?<brca> BRCA(1|2)) sequence variant c\.(?<cdna>[0-9]+.>[A-Za-z]+)|c\.(?<cdna>[0-9]+.[0-9]+[A-Za-z]+) (?:p\.\((?<impact>.\w+\d+\w+)\))/i.freeze



          def initialize(batch)
            # @extractor = ReportExtractor::GenotypeAndReportExtractor.new
            @negative_test = 0 # Added by Francesco
            @positive_test = 0 # Added by Francesco
            super
          end

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS,
                                            FIELD_NAME_MAPPINGS)
            assess_scope_from_genotype(record, genotype)
            # process_tests(record, genotype, genotypes)
            res =process_tests(record, genotype)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
            # add_protein_impact_from_report(genotype, record) # Added by Francesco
            # add_cdna_change_from_report(genotype, record) # Added by Francesco
            # add_BRCA_from_raw_genotype(genotype, record) # Added by Francesco
            # add_teststatus_from_raw_genotype(genotype, record) # Added by Francesco
            # add_gene_cdna_protein_from_report(genotype, record) # Added by Francesco
            # add_scope_and_type_from_genotype(genotype, record) # Added by Francesco
            # add_b1_b2_c3_pos(genotype, record) # Added by Francesco ad hoc
            # add_organisationcode_testresult(genotype)
            # genotype.add_provider_name(record.raw_fields['reffac.name'])
            # sample_type = record.raw_fields['sampletype']
            # genotype.add_specimen_type(sample_type) unless sample_type.nil?
            # mtype = record.raw_fields['moleculartestingtype']
            # genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[mtype.downcase.strip]) unless mtype.
            #                                                                              nil?
            # report = Maybe([record.raw_fields['report'],
            #                 record.mapped_fields['report'],
            #                 record.raw_fields['firstofreport']].
            #                  reject(&:nil?).first).or_else('') # la report_string
            # geno = Maybe(record.raw_fields['genotype']).
            #        or_else(Maybe(record.raw_fields['report_result']).
            #        or_else(''))
            # process_scope(geno, genotype, record)
            # @persister.integrate_and_store(genotype)
            # res = @extractor.process(geno, report, genotype)
#             res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end
          
          # @geno_string = record.raw_fields['genotype']
          #
          # @report_string = Maybe([record.raw_fields['report'],
          #                 record.mapped_fields['report'],
          #                 record.raw_fields['report_result'],
          #                 record.raw_fields['firstofreport']].
          #                  reject(&:nil?).first).or_else('')

          # def assess_test_type(record)
          #   report_string = Maybe([record.raw_fields['report'],
          #                 record.mapped_fields['report'],
          #                 record.raw_fields['firstofreport']].
          #                  reject(&:nil?).first).or_else('')
          #   if report_string.scan(PREDICTIVE_REPORT_REGEX_NEGATIVE).size.positive?
          #     binding.pry
          #   end
          # end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '699C0'
          end
          #
          # def add_BRCA_from_raw_genotype(genotype, record)
          #   case record.raw_fields['genotype']
          #   when BRCA1_REGEX
          #     genotype.add_gene('BRCA1')
          #   when BRCA2_REGEX
          #     genotype.add_gene('BRCA2')
          #   end
          # end
          #
          # def add_teststatus_from_raw_genotype(genotype, record)
          #   case record.raw_fields['genotype']
          #   when TESTSTATUS_REGEX
          #     genotype.add_status('neg')
          #   else
          #     genotype.add_status('pos')
          #   end
          # end
          #
          # def add_gene_cdna_protein_from_report(genotype, record)
          #   case record.mapped_fields['report']
          #   when GENE_CDNA_PROTEIN_REGEX
          #     genotype.add_gene($LAST_MATCH_INFO[:brca])
          #     genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
          #     genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
          #     @logger.debug 'SUCCESSFUL cdna change parse for: '\
          #                   "#{$LAST_MATCH_INFO[:brca]}, #{$LAST_MATCH_INFO[:cdna]},#{$LAST_MATCH_INFO[:impact]}"
          #   else
          #     @logger.debug 'FAILED gene,cdna,protein impact parse from report'
          #   end
          # end
          #
          # def add_b1_b2_c3_pos(genotype, record)
          #   case record.raw_fields['genotype']
          #   when %r{B1/B2 - C3 pos}i
          #     genotype.add_test_scope(:full_screen)
          #     genotype.add_molecular_testing_type_strict(:diagnostic)
          #   end
          # end
          #
          # def add_cdna_change_from_report(genotype, record)
          #   case record.mapped_fields['report']
          #   when CDNA_REGEX
          #     genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
          #     @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
          #   else
          #     @logger.debug 'FAILED cdna change parse for: '\
          #                   "#{record.mapped_fields['report']}"
          #   end
          # end
          #
          # def add_protein_impact_from_report(genotype, record)
          #   case record.mapped_fields['report']
          #   when PROTEIN_REGEX
          #     genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
          #     @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
          #   else
          #     @logger.debug "FAILED protein change parse for: #{record.mapped_fields['report']}"
          #   end
          # end

          # def add_scope_and_type_from_genotype(genotype, record)
          #   Maybe(record.raw_fields['genotype']).each do |typescopegeno|
          #     genotype.add_molecular_testing_type_strict(TEST_TYPE_MAP[typescopegeno])
          #     scope = TEST_SCOPE_MAP[typescopegeno]
          #     genotype.add_test_scope(scope) if scope
          #   end
          # end

          # def process_scope(geno, genotype, record)
          #   scope = Maybe(record.raw_fields['reason']).
          #           or_else(Maybe(record.mapped_fields['genetictestscope']).or_else(''))
          #   # ------------ Set the test scope ---------------------
          #   if (geno.downcase.include? 'ashkenazi') || (geno.include? 'AJ')
          #     genotype.add_test_scope(:aj_screen)
          #   else
          #     stripped_scope = TEST_SCOPE_MAP[scope.downcase.strip]
          #     genotype.add_test_scope(stripped_scope) if stripped_scope
          #   end
          # end

          # def finalize
          #   @extractor.summary
          #   super
          # end
        end
      end
    end
  end
end
