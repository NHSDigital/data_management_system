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

            def process_tests(record, genotype)
              genotypes = []
              if predictive_test?(record, genotype, genotypes)
                process_predictive_tests(record,genotype, genotypes)
              elsif double_normal_test?(record, genotype, genotypes)
                process_doublenormal_tests(record,genotype, genotypes)
              elsif variant_seq?(record, genotype, genotypes)
                process_variantseq_tests(record, genotype, genotypes)
              elsif variant_class?(record, genotype, genotypes)
                process_variang_class_records(record, genotype, genotypes)
              elsif confirmation_test?(record, genotype, genotypes)
                process_confirmation_test(record, genotype, genotypes)
              end
              genotypes
            end

            def predictive_test?(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
                                
              genotype_string.scan(PREDICTIVE_VALID_REGEX).size.positive?
            end

            def double_normal_test?(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
              words = genotype_string.split(/,| |\//) 
              trimmed_words = words.map(&:downcase).
                              reject { |x| DOUBLE_NORMAL_EXCLUDEABLE.include? x }
              all_safe = trimmed_words.
                         reject { |x| DOUBLE_NORMAL_LIST.include? x }.
                         empty? # TODO: flag/error if false?
              all_present = trimmed_words.include?('b1') &&
                            trimmed_words.include?('b2') &&
                            (trimmed_words.include?('normal') ||
                            trimmed_words.include?('unaffected'))
              all_safe && all_present
            end

              def variant_seq?(record, genotype, genotypes)
                genotype_string = Maybe(record.raw_fields['genotype']).
                                  or_else(Maybe(record.raw_fields['report_result']).
                                  or_else(''))
                                
                genotype_string.scan(VARIANTSEQ_REGEX).size.positive?
              end

              def variant_class?(record, genotype, genotypes)
                genotype_string = Maybe(record.raw_fields['genotype']).
                                  or_else(Maybe(record.raw_fields['report_result']).
                                  or_else(''))
                                
                genotype_string.scan(VARIANT_CLASS_REGEX).size.positive?
              end

              def confirmation_test?(record, genotype, genotypes)
                genotype_string = Maybe(record.raw_fields['genotype']).
                                  or_else(Maybe(record.raw_fields['report_result']).
                                  or_else(''))
                genotype_string.scan(CONFIRMATION_REGEX).size.positive?
              end

              def process_confirmation_test(record, genotype, genotypes)
                report_string = Maybe([record.raw_fields['report'],
                                record.mapped_fields['report'],
                                record.raw_fields['firstofreport']].
                                reject(&:nil?).first).or_else('')
                genotype_string = Maybe(record.raw_fields['genotype']).
                                  or_else(Maybe(record.raw_fields['report_result']).
                                  or_else(''))
                confirmation_test_details = genotype_string.match(CONFIRMATION_REGEX)
                if confirmation_test_details[:status] == 'neg'
                  genotype.add_gene(confirmation_test_details[:brca].to_i)
                  genotype.add_status(1)
                  genotypes.append(genotype)
                elsif confirmation_test_details[:status] == 'pos'
                  if report_string.scan(PREDICTIVE_REPORT_REGEX_POSITIVE).size.positive?
                    variant = report_string.match(PREDICTIVE_REPORT_REGEX_POSITIVE)
                    Maybe(variant[:brca]).map { |x| genotype.add_gene(x)}
                    Maybe(variant[:location]).map { |x| genotype.add_gene_location(x)}
                    Maybe(variant[:zygosity]).map { |x| genotype.add_zygosity(x)}
                    Maybe(variant[:variantclass]).map { |x| genotype.add_variant_class(x)}
                    genotypes.append(genotype)
                  elsif report_string.scan(PREDICTIVE_POSITIVE_EXON).size.positive?
                    exon_variant = report_string.match(PREDICTIVE_POSITIVE_EXON)
                    Maybe(exon_variant[:zygosity]).map { |x| genotype.add_zygosity(x)}
                    Maybe(exon_variant[:variantclass]).map {|x| genotype.add_variant_class(x)}
                    Maybe(exon_variant[:brca]).map { |x| genotype.add_gene(x)}
                    Maybe(exon_variant[:mutationtype]).map { |x| genotype.add_variant_type(x)}
                    Maybe(exon_variant[:exons]).map { |x| genotype.add_exon_location(x)}
                    genotypes.append(genotype)
                  elsif report_string.scan(PREDICTIVE_MLPA_POSITIVE).size.positive?
                    mlpa_exon_variant = report_string.match(PREDICTIVE_MLPA_POSITIVE)
                    Maybe(mlpa_exon_variant[:zygosity]).map { |x| genotype.add_zygosity(x)}
                    Maybe(mlpa_exon_variant[:variantclass]).map {|x| genotype.add_variant_class(x)}
                    Maybe(mlpa_exon_variant[:brca]).map { |x| genotype.add_gene(x)}
                    Maybe(mlpa_exon_variant[:mutationtype]).map { |x| genotype.add_variant_type(x)}
                    Maybe(mlpa_exon_variant[:exons]).map { |x| genotype.add_exon_location(x)}
                    genotypes.append(genotype)
                  elsif report_string.scan(CDNA_VARIANT_CLASS_REGEX).size.positive?
                    cdna_variant = report_string.match(CDNA_VARIANT_CLASS_REGEX)
                    genotype.add_gene(positive_gene.join)
                    Maybe(cdna_variant[:location]).map { |x| genotype.add_gene_location(x)}
                    Maybe(cdna_variant[:protein]).map {|x| genotype.add_protein_impact(x)}
                    Maybe(cdna_variant[:zygosity]).map {|x| genotype.add_zygosity(x)}
                    Maybe(cdna_variant[:variantclass]).map { |x| genotype.add_variant_class(x)}
                    genotypes.append(genotype)
                  elsif report_string.scan(CDNA_VARIANT_CLASS_REGEX).size.positive?
                    binding.pry
                  else binding.pry
                  end
                end
              end

              def process_variang_class_records(record, genotype, genotypes)
                report_string = Maybe([record.raw_fields['report'],
                                record.mapped_fields['report'],
                                record.raw_fields['firstofreport']].
                                reject(&:nil?).first).or_else('')
                genotype_string = Maybe(record.raw_fields['genotype']).
                                  or_else(Maybe(record.raw_fields['report_result']).
                                  or_else(''))
                tested_gene = genotype_string.match(VARIANT_CLASS_REGEX)[:brca]
                positive_gene = [DEPRECATED_BRCA_NAMES_MAP[tested_gene]]
                if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                  process_negative_genes(positive_gene, genotype, genotypes)
                end
                if  report_string.scan(EXON_LOCATION).size.positive?
                  exon_variant = report_string.match(EXON_LOCATION)
                  genotype.add_gene(positive_gene.join)
                  Maybe(exon_variant[:variantclass]).map { |x| genotype.add_variant_class(x) }
                  Maybe(exon_variant[:mutationtype]).map { |x| genotype.add_variant_type(x) }
                  Maybe(exon_variant[:exons]).map { |x| genotype.add_exon_location(x)}
                  genotypes.append(genotype)
                elsif report_string.scan(CDNA_VARIANT_CLASS_REGEX).size.positive?
                  cdna_variant = report_string.match(CDNA_VARIANT_CLASS_REGEX)
                  genotype.add_gene(positive_gene.join)
                  Maybe(cdna_variant[:location]).map { |x| genotype.add_gene_location(x)}
                  Maybe(cdna_variant[:protein]).map {|x| genotype.add_protein_impact(x)}
                  Maybe(cdna_variant[:zygosity]).map {|x| genotype.add_zygosity(x)}
                  Maybe(cdna_variant[:variantclass]).map { |x| genotype.add_variant_class(x)}
                  genotypes.append(genotype)
                else binding.pry
                end
              end

              def process_variantseq_tests(record, genotype, genotypes)
                report_string = Maybe([record.raw_fields['report'],
                                record.mapped_fields['report'],
                                record.raw_fields['firstofreport']].
                                reject(&:nil?).first).or_else('')
                genotype_string = Maybe(record.raw_fields['genotype']).
                                  or_else(Maybe(record.raw_fields['report_result']).
                                  or_else(''))
                positive_gene = report_string.scan(BRCA_REGEX)
                variant = report_string.match(GENE_LOCATION)
                if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                  process_negative_genes(positive_gene, genotype, genotypes)
                end
                genotype.add_gene(report_string.match(BRCA_REGEX)[:brca])
                genotype.add_gene_location(variant[:location])
                genotype.add_protein_impact(variant[:protein])
                genotypes.append(genotype)
              end

              def process_negative_genes(positive_gene, genotype, genotypes)
                negative_genes = ['BRCA1', 'BRCA2'] - positive_gene
                negative_genes.each do |negative_gene|
                  genotype2 = genotype.dup
                  genotype2.add_gene(negative_gene)
                  genotype2.add_status(1)
                  genotypes.append(genotype2)
                end
                genotypes
              end

            def process_doublenormal_tests(record, genotype, genotypes)
              genotype2 = genotype.dup
              genotype.add_gene('BRCA1')
              genotype.add_status(1)
              genotypes.append(genotype)
              genotype2.add_gene('BRCA2')
              genotype2.add_status(1)
              genotypes.append(genotype2)
            end

            def process_predictive_tests(record,genotype, genotypes)
              
              report_string = Maybe([record.raw_fields['report'],
                              record.mapped_fields['report'],
                              record.raw_fields['firstofreport']].
                              reject(&:nil?).first).or_else('')
              if report_string.scan(PREDICTIVE_REPORT_REGEX_POSITIVE).size.positive?
                process_positive_predictive(report_string, genotype, genotypes)
              elsif report_string.scan(PREDICTIVE_REPORT_REGEX_NEGATIVE).size.positive?
                process_negative_predictive(report_string, genotype, genotypes)
              elsif report_string.scan(PREDICTIVE_REPORT_NEGATIVE_INHERITED_REGEX).size.positive?
                process_negative_inherited_predictive(report_string, genotype, genotypes)
              elsif report_string.scan(PREDICTIVE_POSITIVE_EXON).size.positive?
                process_positive_predictive_exonvariant(report_string, genotype, genotypes)
              elsif report_string.scan(PREDICTIVE_MLPA_NEGATIVE).size.positive?
                process_negative_mlpa_predictive(report_string, genotype, genotypes)
              elsif report_string.scan(PREDICTIVE_MLPA_POSITIVE).size.positive?
                process_positive_mlpa_predictive(report_string, genotype, genotypes)
              end
            end
            
            def process_positive_predictive(report_string, genotype, genotypes)
              variant = report_string.gsub('\n', '').match(PREDICTIVE_REPORT_REGEX_POSITIVE)
              Maybe(variant[:zygosity]).map { |x| genotype.add_zygosity(x) }
              Maybe(variant[:location]).map { |x| genotype.add_gene_location(x) }
              Maybe(variant[:brca]).map { |x| genotype.add_gene(x) }
              Maybe(variant[:variantclass]).map { |x| genotype.add_variant_class(x) }
              genotype.add_status(2)
              genotypes.append(genotype)
              @logger.debug 'Sucessfully parsed positive pred record'
            end

            def process_negative_predictive(report_string, genotype, genotypes)
              Maybe(report_string.match(PREDICTIVE_REPORT_REGEX_NEGATIVE)[:brca]).map { |x| genotype.add_gene(x) }
              genotype.add_status(1)
              genotypes.append(genotype)
              @logger.debug 'Sucessfully parsed negative pred record'
            end

            def process_negative_inherited_predictive(report_string, genotype, genotypes)
              Maybe(report_string.match(PREDICTIVE_REPORT_NEGATIVE_INHERITED_REGEX)[:brca]).map { |x| genotype.add_gene(x) }
              genotype.add_status(1)
              genotypes.append(genotype)
              @logger.debug 'Sucessfully parsed negative INHERITED pred record'
            end

            def process_positive_predictive_exonvariant(report_string, genotype, genotypes)
              variant = report_string.gsub('\n', '').match(PREDICTIVE_POSITIVE_EXON)
              Maybe(variant[:zygosity]).map { |x| genotype.add_zygosity(x) }
              Maybe(variant[:variantclass]).map { |x| genotype.add_variant_class(x) }
              Maybe(variant[:brca]).map { |x| genotype.add_gene(x) }
              Maybe(variant[:mutationtype]).map { |x| genotype.add_variant_type(x) }
              Maybe(variant[:exons]).map { |x| genotype.add_exon_location(x) }
              genotypes.append(genotype)
              @logger.debug 'Sucessfully parsed POSITIVE EXON pred record'
            end
            
            def process_negative_mlpa_predictive(report_string, genotype, genotypes)
              Maybe(report_string.match(PREDICTIVE_MLPA_NEGATIVE)[:brca]).map { |x| genotype.add_gene(x) }
              genotype.add_status(1)
              genotypes.append(genotype)
              @logger.debug 'Sucessfully parsed NEGATIVE MLPA pred record'
            end
            
            def process_positive_mlpa_predictive(report_string, genotype, genotypes)
              variant = report_string.gsub('\n', '').match(PREDICTIVE_MLPA_POSITIVE)
              Maybe(variant[:zygosity]).map { |x| genotype.add_zygosity(x) }
              Maybe(variant[:variantclass]).map { |x| genotype.add_variant_class(x) }
              Maybe(variant[:brca]).map { |x| genotype.add_gene(x) }
              Maybe(variant[:mutationtype]).map { |x| genotype.add_variant_type(x) }
              Maybe(variant[:exons]).map { |x| genotype.add_exon_location(x) }
              genotypes.append(genotype)
              @logger.debug 'Sucessfully parsed POSITIVE MLPA pred record'
            end

            # def extract_predictive_records(genotype_string, report_string, genotype)
            #   @report_parse_attempt_counter += 1
            #   if self.class::VALID_REGEX.match(genotype_string)
            #     genotype.add_gene($LAST_MATCH_INFO[:brca])
            #     genotype.add_method($LAST_MATCH_INFO[:method])
            #     genotype.add_status($LAST_MATCH_INFO[:status])
            #   end
            #   if genotype.positive?
            #     @failed_report_parse_counter += 1 unless extract_single_mutation(report_string, genotype)
            #   else
            #     case report_string.gsub('\n', '')
            #     when REPORT_REGEX_POSITIVE then
            #       # TODO: add familial
            #       Maybe($LAST_MATCH_INFO[:zygosity]).map { |x| genotype.add_zygosity(x) }
            #       Maybe($LAST_MATCH_INFO[:location]).map { |x| genotype.add_gene_location(x) }
            #       Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
            #       Maybe($LAST_MATCH_INFO[:variantclass]).map { |x| genotype.add_variant_class(x) }
            #     when REPORT_REGEX_NEGATIVE then
            #       Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
            #     when REPORT_REGEX_INHERITED then
            #       Maybe($LAST_MATCH_INFO[:location]).map { |x| genotype.add_gene_location(x) }
            #       Maybe($LAST_MATCH_INFO[:protein]).map { |x| genotype.add_protein_impact(x) }
            #       Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
            #     when MLPA_NEGATIVE then
            #
            #       Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
            #       # Maybe($LAST_MATCH_INFO[:mutationtype]).map { |x| genotype.add_variant_type(x) }
            #       # Maybe($LAST_MATCH_INFO[:exons]).map { |x| genotype.add_exon_location(x) }
            #     when INHERITED_EXON then
            #       # Maybe($LAST_MATCH_INFO[:status]).map { |x| genotype.add_status(x) }
            #       # TODO: make this fail loudly if contradictory
            #       Maybe($LAST_MATCH_INFO[:variantclass]).map { |x| genotype.add_variant_class(x) }
            #       Maybe($LAST_MATCH_INFO[:brca]).map { |x| genotype.add_gene(x) }
            #       Maybe($LAST_MATCH_INFO[:mutationtype]).map { |x| genotype.add_variant_type(x) }
            #       Maybe($LAST_MATCH_INFO[:exons]).map { |x| genotype.add_exon_location(x) }
            #     else
            #       @failed_report_parse_counter += 1
            #     end
            #   end
            #   [genotype]
            # end
          end
        end
      end
    end
  end
end
