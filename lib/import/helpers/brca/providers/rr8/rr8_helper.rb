module Import
  module Helpers
    module Brca
      module Providers
        module Rr8
          module Rr8Helper
            include Import::Helpers::Brca::Providers::Rr8::Rr8Constants

            def assess_scope_from_genotype(record, genotype)
              genetictestscope_field = Maybe([record.raw_fields['reason'],
                                              record.raw_fields['moleculartestingtype']].
                             reject(&:nil?).first).or_else('')
              if full_screen?(genetictestscope_field)
                genotype.add_test_scope(:full_screen)
              elsif targeted?(genetictestscope_field)
                genotype.add_test_scope(:targeted_mutation)
              elsif ashkenazi?(genetictestscope_field)
                genotype.add_test_scope(:aj_screen)
              else 
                genotype.add_test_scope(:no_genetictestscope)
              end
            end

            def full_screen?(genetictestscope_field)
                     
              return if genetictestscope_field.nil?
              FULL_SCREEN_LIST.include?(genetictestscope_field.downcase.to_s) ||
              genetictestscope_field.downcase.scan(FULL_SCREEN_REGEX).size.positive?
            end

            def targeted?(genetictestscope_field)
              return if genetictestscope_field.nil?
              TARGETED_LIST.include?(genetictestscope_field.downcase.to_s) ||
              genetictestscope_field.downcase.scan(TARGETED_REGEX).size.positive?
            end

            def ashkenazi?(genetictestscope_field)
              return if genetictestscope_field.nil?
              genetictestscope_field.downcase.include? ('ashkenazi') ||
              genetictestscope_field.include?('AJ')
            end


            def extract_single_mutation(report_string, genotype)
              return false if report_string.nil?

              if report_string.scan(LOCATION_REGEX).chunk { |x| x } .map(&:first).size == 1
                matches = report_string.match(LOCATION_REGEX)
                genotype.add_gene_location(matches[:location])
                genotype.add_protein_impact(matches[:protein])
                genotype.add_exon_location(matches[:exons])
                if report_string.scan(ZYGOSITY_REGEX).size == 1
                  matches = report_string.match(ZYGOSITY_REGEX)
                  genotype.add_zygosity(matches[:zygosity])
                end
                true
              else
                false # TODO: clean up
              end
            end

            def extract_predictive_records(genotype_string, report_string, genotype)
              @report_parse_attempt_counter += 1
              if self.class::VALID_REGEX.match(genotype_string)
                genotype.add_gene($LAST_MATCH_INFO[:brca])
                genotype.add_method($LAST_MATCH_INFO[:method])
                genotype.add_status($LAST_MATCH_INFO[:status])
              end
              if genotype.positive?
                @failed_report_parse_counter += 1 unless extract_single_mutation(report_string, genotype)
              else
                case report_string.gsub('\n', '')
                when REPORT_REGEX_POSITIVE then
                  # TODO: add familial
                  Maybe($LAST_MATCH_INFO[:zygosity]).map { |x| genotype.add_zygosity(x) }
                  Maybe($LAST_MATCH_INFO[:location]).map { |x| genotype.add_gene_location(x) }
                  Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
                  Maybe($LAST_MATCH_INFO[:variantclass]).map { |x| genotype.add_variant_class(x) }
                when REPORT_REGEX_NEGATIVE then
                  Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
                when REPORT_REGEX_INHERITED then
                  Maybe($LAST_MATCH_INFO[:location]).map { |x| genotype.add_gene_location(x) }
                  Maybe($LAST_MATCH_INFO[:protein]).map { |x| genotype.add_protein_impact(x) }
                  Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
                when MLPA_NEGATIVE then
                  
                  Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
                  # Maybe($LAST_MATCH_INFO[:mutationtype]).map { |x| genotype.add_variant_type(x) }
                  # Maybe($LAST_MATCH_INFO[:exons]).map { |x| genotype.add_exon_location(x) }
                when INHERITED_EXON then
                  # Maybe($LAST_MATCH_INFO[:status]).map { |x| genotype.add_status(x) }
                  # TODO: make this fail loudly if contradictory
                  Maybe($LAST_MATCH_INFO[:variantclass]).map { |x| genotype.add_variant_class(x) }
                  Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
                  Maybe($LAST_MATCH_INFO[:mutationtype]).map { |x| genotype.add_variant_type(x) }
                  Maybe($LAST_MATCH_INFO[:exons]).map { |x| genotype.add_exon_location(x) }
                else
                  @failed_report_parse_counter += 1
                end
              end
              [genotype]
            end
          end
        end
      end
    end
  end
end
