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
              genotype_string = Maybe(record.raw_fields['genotype']).
                                      or_else(Maybe(record.raw_fields['report_result']).
                                       or_else(''))
              if full_screen?(genetictestscope_field)
                genotype.add_test_scope(:full_screen)
              elsif targeted?(genetictestscope_field, genotype_string)
                genotype.add_test_scope(:targeted_mutation)
              elsif ashkenazi?(genetictestscope_field, genotype_string)
                genotype.add_test_scope(:aj_screen)
              else 
                genotype.add_test_scope(:no_genetictestscope)
              end
            end

            def process_tests(record, genotype)
              genotypes = []
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
              report_string = Maybe([record.raw_fields['report'],
                              record.mapped_fields['report'],
                              record.raw_fields['firstofreport']].
                              reject(&:nil?).first).or_else('')
              if predictive_test?(record, genotype, genotypes)
                process_predictive_tests(record,genotype, genotypes)
              elsif double_normal_test?(record, genotype, genotypes)
                process_doublenormal_tests(record,genotype, genotypes)
              elsif variant_seq?(record, genotype, genotypes)
                process_variantseq_tests(record, genotype, genotypes)
              elsif variant_class?(record, genotype, genotypes)
               process_variant_class_records(record, genotype, genotypes)
              elsif confirmation_test?(record, genotype, genotypes)
                process_confirmation_test(record, genotype, genotypes)
              elsif ashkenazi_test?(record, genotype, genotypes)
                process_ashkenazi_tests(record, genotype, genotypes)
              elsif double_normal_test_mlpa_fail?(record, genotype, genotypes)
                process_double_normal_mlpa_test(record, genotype, genotypes)
              elsif truncating_variant_test?(record, genotype, genotypes)
                process_truncating_variant_test(record, genotype, genotypes)
              elsif word_report_test?(record, genotype, genotypes)
                process_word_report_tests(record, genotype, genotypes)
              elsif class_m_record?(record, genotype, genotypes)
                process_class_m_tests(record, genotype, genotypes)
              elsif familial_class_record?(record, genotype, genotypes)
                process_familial_class_tests(record, genotype, genotypes)
              end
              genotypes
            end

            def full_screen?(genetictestscope_field)
              return if genetictestscope_field.nil?

              FULL_SCREEN_LIST.include?(genetictestscope_field.downcase.to_s) ||
              genetictestscope_field.downcase.scan(FULL_SCREEN_REGEX).size.positive?
            end

            def targeted?(genetictestscope_field, genotype_string)
              return if genetictestscope_field.nil?

              (TARGETED_LIST.include?(genetictestscope_field.downcase.to_s) ||
              genetictestscope_field.downcase.scan(TARGETED_REGEX).size.positive?) && 
              (genotype_string.scan(AJNEGATIVE_REGEX).size.zero? &&
              genotype_string.scan(AJPOSITIVE_REGEX).size.zero?)
            end

            def ashkenazi?(genetictestscope_field, genotype_string)
              return if genetictestscope_field.nil?

              (genetictestscope_field.downcase.include? ('ashkenazi') or
              genetictestscope_field.include?('AJ')) ||
              (genotype_string.downcase.include? ('ashkenazi') or
              genotype_string.include?('AJ'))
            end

            def familial_class_record?(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
                                
              genotype_string.scan(/Familial Class/i.freeze).size.positive?
            end

            def class_m_record?(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
                                
              genotype_string.scan(CLASS_M_REGEX).size.positive?
            end

            def predictive_test?(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
                                
              genotype_string.scan(PREDICTIVE_VALID_REGEX).size.positive?
            end

            def word_report_test?(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
                                
              genotype_string.scan(WORD_REPORT_NORMAL_REGEX).size.positive?
            end

            def process_familial_class_tests(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
              report_string = Maybe([record.raw_fields['report'],
                              record.mapped_fields['report'],
                              record.raw_fields['firstofreport']].
                              reject(&:nil?).first).or_else('')
              positive_gene = report_string.scan(Import::Brca::Core::GenotypeBrca::BRCA_REGEX).
                              flatten.compact.uniq
              genotype.add_gene(positive_gene.join)
              if genotype_string.scan(/pos/i).size.positive?
                genotype.add_variant_class( genotype_string.scan(/[0-9]/i).join.to_i)
                if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                  process_negative_genes(positive_gene, genotype, genotypes)
                end
                if report_string.scan(CDNA_VARIANT_CLASS_REGEX).size.positive?
                  variant = report_string.match(CDNA_VARIANT_CLASS_REGEX)
                  Maybe(variant[:location]).map { |x| genotype.add_gene_location(x)}
                  Maybe(variant[:protein]).map {|x| genotype.add_protein_impact(x)}
                  Maybe(variant[:zygosity]).map {|x| genotype.add_zygosity(x)}
                  Maybe(variant[:variantclass]).map { |x| genotype.add_variant_class(x)}  
                elsif report_string.scan(CDNA_MUTATION_TYPES_REGEX).size.positive?
                  variant = report_string.match(CDNA_MUTATION_TYPES_REGEX)
                  Maybe(variant[:cdna]).map { |x| genotype.add_gene_location(x)}
                  Maybe(variant[:impact]).map {|x| genotype.add_protein_impact(x)}
                end
                genotypes.append(genotype)
              elsif genotype_string.scan(/neg/i).size.positive?
                  genotype.add_gene(report_string)
                  genotype.add_status(1)
                  genotypes.append(genotype)
              else binding.pry
              end
              genotypes
            end

            def process_word_report_tests(record, genotype, genotypes)
              if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                reported_genes = ['BRCA1', 'BRCA2']
                reported_genes.each do |negative_gene|
                  genotype2 = genotype.dup
                  genotype2.add_gene(negative_gene)
                  genotype2.add_status(4)
                  genotypes.append(genotype2)
                end
                genotypes
              else 
                genotype.add_status(4)
                genotypes.append(genotype)
              end
              genotypes
            end

            def ashkenazi_test?(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))

              genotype_string.scan(AJNEGATIVE_REGEX).size.positive? ||
              genotype_string.scan(AJPOSITIVE_REGEX).size.positive? ||
              (genotype_string.downcase.include? ('ashkenazi') or
              genotype_string.include?('AJ'))
            end

            def truncating_variant_test?(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))

              genotype_string.scan(TRUNCATING_VARIANT_REGEX).size.positive?
            end
 
            # TODO: implement 'else' cases
            def process_class_m_tests(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
              report_string = Maybe([record.raw_fields['report'],
                              record.mapped_fields['report'],
                              record.raw_fields['firstofreport']].
                              reject(&:nil?).first).or_else('')
                              
              positive_gene   = [DEPRECATED_BRCA_NAMES_MAP[
                                genotype_string.scan(DEPRECATED_BRCA_NAMES_REGEX).join
                                ]]
              if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                process_negative_genes(positive_gene, genotype, genotypes)
              end
              genotype.add_gene(positive_gene.join)
              if report_string.scan(CDNA_REGEX).size.positive?
                genotype.add_gene_location(report_string.match(CDNA_REGEX)[:cdna])
                if report_string.scan(PROTEIN_REGEX).size.positive?
                  genotype.add_gene_location(report_string.match(PROTEIN_REGEX)[:impact])
                end
                genotypes.append(genotype)
              # else binding.pry
              end
            end

            def process_truncating_variant_test(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
              report_string = Maybe([record.raw_fields['report'],
                              record.mapped_fields['report'],
                              record.raw_fields['firstofreport']].
                              reject(&:nil?).first).or_else('')
                              
              positive_gene   = [DEPRECATED_BRCA_NAMES_MAP[
                                genotype_string.scan(DEPRECATED_BRCA_NAMES_REGEX).join
                                ]]
              if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                process_negative_genes(positive_gene, genotype, genotypes)
              end
              genotype.add_gene(positive_gene.join)
              if report_string.scan(CDNA_MUTATION_TYPES_REGEX).size.positive?
                variant = report_string.match(CDNA_MUTATION_TYPES_REGEX)
                Maybe(variant[:cdna]).map { |x| genotype.add_gene_location(x)}
                Maybe(variant[:zygosity]).map { |x| genotype.add_zygosity(x)}
                Maybe(variant[:type]).map { |x| genotype.add_variant_impact(x)}
                Maybe(variant[:impact]).map {|x| genotype.add_protein_impact(x)}
                genotypes.append(genotype)
              elsif report_string.scan(CDNA_REGEX).size.positive?
                cdnas = report_string.scan(CDNA_REGEX).flatten.compact.uniq
                cdnas.each do |cdna|
                  mutant_genotype = genotype.dup
                  mutant_genotype.add_gene_location(cdna)
                  mutant_genotype.add_status(2)
                  genotypes.append(mutant_genotype)
                  genotypes
                end
                genotypes
              end
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

            def double_normal_test_mlpa_fail?(record, genotype, genotypes)
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
              genotype_string.scan(DOUBLE_NORMAL_MLPA_FAIL).size.positive?
            end
            
            
            def process_double_normal_mlpa_test(record, genotype, genotypes)
              report_string = Maybe([record.raw_fields['report'],
                              record.mapped_fields['report'],
                              record.raw_fields['firstofreport']].
                              reject(&:nil?).first).or_else('')
              genotype_string = Maybe(record.raw_fields['genotype']).
                                or_else(Maybe(record.raw_fields['report_result']).
                                or_else(''))
              if report_string.scan(SEQUENCE_ANALYSIS_SCREENING_MLPA).size.positive?
                genotype2 = genotype.dup
                genotype.add_gene(1)
                genotype.add_status(1)
                genotype2.add_gene(2)
                genotype2.add_status(1)
                genotypes.append(genotype, genotype2)
                if report_string.match(MLPA_FAIL_REGEX)
                  genotype3 = genotype.dup
                  genotype3.add_gene($LAST_MATCH_INFO[:brca])
                  genotype3.add_method('mlpa')
                  genotype3.add_status(9)
                  genotypes.append(genotype3)
                end
                genotypes
              end
              genotypes
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

              def process_ashkenazi_tests(record, genotype, genotypes)
                report_string = Maybe([record.raw_fields['report'],
                                record.mapped_fields['report'],
                                record.raw_fields['firstofreport']].
                                reject(&:nil?).first).or_else('')
                genotype_string = Maybe(record.raw_fields['genotype']).
                                  or_else(Maybe(record.raw_fields['report_result']).
                                  or_else(''))
                if  genotype_string.scan(AJPOSITIVE_REGEX).size.positive?
                  if report_string.scan(CDNA_MUTATION_TYPES_REGEX).size.positive?
                    variant = report_string.match(CDNA_MUTATION_TYPES_REGEX)
                    Maybe(variant[:brca]).map { |x| genotype.add_gene(x)}
                    Maybe(variant[:cdna]).map { |x| genotype.add_gene_location(x)}
                    Maybe(variant[:zygosity]).map { |x| genotype.add_zygosity(x)}
                    Maybe(variant[:variantclass]).map { |x| genotype.add_variant_class(x)}
                    Maybe(variant[:impact]).map {|x| genotype.add_protein_impact(x)}
                    genotype.add_status(2)
                    genotypes.append(genotype)
                  end
                  genotypes
                elsif  genotype_string.scan(AJNEGATIVE_REGEX).size.positive?
                  genotype.add_gene(report_string.match(CDNA_MUTATION_TYPES_REGEX)[:brca])
                  genotype.add_status(1)
                  genotypes.append(genotype)
                end
                genotypes
              end

              # TODO: find more exceptions
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
                    genotype.add_status(2)
                    genotypes.append(genotype)
                  elsif report_string.scan(PREDICTIVE_POSITIVE_EXON).size.positive?
                    exon_variant = report_string.match(PREDICTIVE_POSITIVE_EXON)
                    Maybe(exon_variant[:zygosity]).map { |x| genotype.add_zygosity(x)}
                    Maybe(exon_variant[:variantclass]).map {|x| genotype.add_variant_class(x)}
                    Maybe(exon_variant[:brca]).map { |x| genotype.add_gene(x)}
                    Maybe(exon_variant[:mutationtype]).map { |x| genotype.add_variant_type(x)}
                    Maybe(exon_variant[:exons]).map { |x| genotype.add_exon_location(x)}
                    genotype.add_status(2)
                    genotypes.append(genotype)
                  elsif report_string.scan(PREDICTIVE_MLPA_POSITIVE).size.positive?
                    mlpa_exon_variant = report_string.match(PREDICTIVE_MLPA_POSITIVE)
                    Maybe(mlpa_exon_variant[:zygosity]).map { |x| genotype.add_zygosity(x)}
                    Maybe(mlpa_exon_variant[:variantclass]).map {|x| genotype.add_variant_class(x)}
                    Maybe(mlpa_exon_variant[:brca]).map { |x| genotype.add_gene(x)}
                    Maybe(mlpa_exon_variant[:mutationtype]).map { |x| genotype.add_variant_type(x)}
                    Maybe(mlpa_exon_variant[:exons]).map { |x| genotype.add_exon_location(x)}
                    genotype.add_status(2)
                    genotypes.append(genotype)
                  elsif report_string.scan(CDNA_VARIANT_CLASS_REGEX).size.positive?
                    cdna_variant = report_string.match(CDNA_VARIANT_CLASS_REGEX)
                    Maybe(cdna_variant[:brca]).map { |x| genotype.add_gene(x)}
                    Maybe(cdna_variant[:location]).map { |x| genotype.add_gene_location(x)}
                    Maybe(cdna_variant[:protein]).map {|x| genotype.add_protein_impact(x)}
                    Maybe(cdna_variant[:zygosity]).map {|x| genotype.add_zygosity(x)}
                    Maybe(cdna_variant[:variantclass]).map { |x| genotype.add_variant_class(x)}
                    genotype.add_status(2)
                    genotypes.append(genotype)
                  end
                end
              end

              # TODO: find more exceptions
              def process_variant_class_records(record, genotype, genotypes)
                report_string = Maybe([record.raw_fields['report'],
                                record.mapped_fields['report'],
                                record.raw_fields['firstofreport']].
                                reject(&:nil?).first).or_else('')
                genotype_string = Maybe(record.raw_fields['genotype']).
                                  or_else(Maybe(record.raw_fields['report_result']).
                                  or_else(''))
                tested_gene = genotype_string.match(VARIANT_CLASS_REGEX)[:brca]
                positive_gene = [DEPRECATED_BRCA_NAMES_MAP[tested_gene]]
                if report_string.scan(EXON_LOCATION).size.positive?
                  if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                    process_negative_genes(positive_gene, genotype, genotypes)
                  end
                  exon_variant = report_string.match(EXON_LOCATION)
                  genotype.add_gene(positive_gene.join)
                  Maybe(exon_variant[:variantclass]).map { |x| genotype.add_variant_class(x) }
                  Maybe(exon_variant[:mutationtype]).map { |x| genotype.add_variant_type(x) }
                  Maybe(exon_variant[:exons]).map { |x| genotype.add_exon_location(x)}
                  genotype.add_status(2)
                  genotypes.append(genotype)
                elsif report_string.scan(PROMOTER_EXON_LOCATION).size.positive?
                  if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                    process_negative_genes(positive_gene, genotype, genotypes)
                  end
                  promoter_variant = report_string.match(PROMOTER_EXON_LOCATION)
                  genotype.add_gene(positive_gene.join)
                  Maybe(promoter_variant[:variantclass]).map { |x| genotype.add_variant_class(x) }
                  Maybe(promoter_variant[:mutationtype]).map { |x| genotype.add_variant_type(x) }
                  Maybe(promoter_variant[:exons]).map { |x| genotype.add_exon_location(x)}
                  genotype.add_status(2)
                  genotypes.append(genotype)
                elsif report_string.scan(EXON_LOCATION_EXCEPTIONS).size.positive?
                  if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                    process_negative_genes(positive_gene, genotype, genotypes)
                  end
                  exc_exon_variant = report_string.match(EXON_LOCATION_EXCEPTIONS)
                  genotype.add_gene(positive_gene.join)
                  Maybe(exc_exon_variant[:mutationtype]).map { |x| genotype.add_variant_type(x) }
                  Maybe(exc_exon_variant[:exons]).map { |x| genotype.add_exon_location(x)}
                  genotype.add_status(2)
                  genotypes.append(genotype)
                elsif report_string.scan(CDNA_VARIANT_CLASS_REGEX).size.positive?
                  if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                    process_negative_genes(positive_gene, genotype, genotypes)
                  end
                  cdna_variant = report_string.match(CDNA_VARIANT_CLASS_REGEX)
                  genotype.add_gene(positive_gene.join)
                  Maybe(cdna_variant[:location]).map { |x| genotype.add_gene_location(x)}
                  Maybe(cdna_variant[:protein]).map {|x| genotype.add_protein_impact(x)}
                  Maybe(cdna_variant[:zygosity]).map {|x| genotype.add_zygosity(x)}
                  Maybe(cdna_variant[:variantclass]).map { |x| genotype.add_variant_class(x)}
                  genotype.add_status(2)
                  genotypes.append(genotype)
                elsif report_string.scan(CDNA_MUTATION_TYPES_REGEX).size.positive?
                  if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                    process_negative_genes(positive_gene, genotype, genotypes)
                  end
                  cdna_variants_types = report_string.match(CDNA_MUTATION_TYPES_REGEX)
                  genotype.add_gene(positive_gene.join)
                  Maybe(cdna_variants_types[:zygosity]).map {|x| genotype.add_zygosity(x)}
                  Maybe(cdna_variants_types[:variantclass]).map { |x| genotype.add_variant_class(x)}
                  Maybe(cdna_variants_types[:type]).map { |x| genotype.add_variant_impact(x)}
                  Maybe(cdna_variants_types[:cdna]).map { |x| genotype.add_gene_location(x)}
                  Maybe(cdna_variants_types[:impact]).map {|x| genotype.add_protein_impact(x)}
                  genotype.add_status(2)
                  genotypes.append(genotype)
                elsif report_string.scan(MUTATION_DETECTED_REGEX).size.positive?
                  if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                    process_negative_genes(positive_gene, genotype, genotypes)
                  end
                  detected_variant = report_string.match(MUTATION_DETECTED_REGEX)
                  genotype.add_gene(positive_gene.join)
                  Maybe(detected_variant[:zygosity]).map {|x| genotype.add_zygosity(x)}
                  Maybe(detected_variant[:variantclass]).map { |x| genotype.add_variant_class(x)}
                  Maybe(detected_variant[:cdna]).map { |x| genotype.add_gene_location(x)}
                  Maybe(detected_variant[:impact]).map {|x| genotype.add_protein_impact(x)}
                  genotype.add_status(2)
                  genotypes.append(genotype)
                elsif report_string.scan(CDNA_REGEX).uniq.size > 1
                  if report_string.sub(/.*?\. /, '').scan(BRCA_REGEX).uniq.size == 1
                    if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                      process_negative_genes(positive_gene, genotype, genotypes)
                    end
                    if report_string.scan(CDNA_REGEX).uniq.size == 2 
                      if report_string.scan(PROTEIN_REGEX).uniq.size == 2
                        cdnas = report_string.scan(CDNA_REGEX).flatten.compact.uniq
                        proteins = report_string.scan(PROTEIN_REGEX).flatten.compact
                        variants = cdnas.zip(proteins)
                        variants.each do |cdna, protein|
                          mutant_genotype = genotype.dup
                          mutant_genotype.add_gene(positive_gene.join)
                          mutant_genotype.add_gene_location(cdna)
                          mutant_genotype.add_protein_impact(protein)
                          mutant_genotype.add_status(2)
                          genotypes.append(mutant_genotype)
                          genotypes
                        end
                        genotypes
                      else
                        cdnas = report_string.scan(CDNA_REGEX).flatten.compact.uniq
                        cdnas.each do |cdna|
                          mutant_genotype = genotype.dup
                          mutant_genotype.add_gene(positive_gene.join)
                          mutant_genotype.add_gene_location(cdna)
                          mutant_genotype.add_status(2)
                          genotypes.append(mutant_genotype)
                          genotypes
                        end
                        genotypes
                      end
                    else
                      cdnas = report_string.scan(CDNA_REGEX).flatten.compact.uniq
                      cdnas.each do |cdna|
                        mutant_genotype = genotype.dup
                        mutant_genotype.add_gene(positive_gene.join)
                        mutant_genotype.add_gene_location(cdna)
                        mutant_genotype.add_status(2)
                        genotypes.append(mutant_genotype)
                        genotypes
                      end
                      genotypes
                    end
                  elsif report_string.sub(/.*?\. /, '').scan(BRCA_REGEX).uniq.size == 2
                    genes = report_string.sub(/.*?\. /, '').scan(BRCA_REGEX).uniq.flatten.compact
                    cdnas = report_string.sub(/.*?\. /, '').scan(CDNA_REGEX).uniq.flatten.compact
                    variants = genes.zip(cdnas)
                    variants.each do |gene, cdna|
                      mutant_genotype = genotype.dup
                      mutant_genotype.add_gene(gene)
                      mutant_genotype.add_gene_location(cdna)
                      mutant_genotype.add_status(2)
                      genotypes.append(mutant_genotype)
                      genotypes
                    end
                    genotypes
                  end
                elsif report_string.scan(CDNA_PROTEIN_COMBO_EXCEPTIONS).size.positive?
                  if genotype.attribute_map['genetictestscope'] == "Full screen BRCA1 and BRCA2"
                    process_negative_genes(positive_gene, genotype, genotypes)
                  end
                  cdna_variants_exceptions = report_string.match(CDNA_PROTEIN_COMBO_EXCEPTIONS)
                  genotype.add_gene(positive_gene.join)
                  genotype.add_gene_location(cdna_variants_exceptions[:cdna])
                  genotype.add_protein_impact(cdna_variants_exceptions[:impact])
                  genotype.add_status(2)
                  genotypes.append(genotype)
                  genotypes
                end
                genotypes
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

          end
        end
      end
    end
  end
end
