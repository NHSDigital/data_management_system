module Import
  module Helpers
    module Brca
      module Providers
        module Rq3
          # Helper methods for Brimingham Germline extractor
          module Rq3Helper
            include Import::Helpers::Brca::Providers::Rq3::Rq3Constants

            def check_positive_record?
              %w[P ? UV PATHOGENIC].include? @posnegtest.upcase
            end

            def check_negative_record?
              (@posnegtest.upcase == 'N' || @posnegtest.upcase == 'NORMAL') &&
                @testresult.scan(/INTERNAL REPORT/i).size.zero? &&
                !@testreport.nil?
            end

            def add_variantpathclass_uv_records(genotype_object)
              return if @posnegtest.nil?

              genotype_object.attribute_map['variantpathclass'] = 3 if @posnegtest == 'UV'
            end

            def process_genetictestscope(genotype, record)
              indication = record.raw_fields['indication']
              reason = record.raw_fields['reason']
              report = record.raw_fields['report']
              moltesttype = record.raw_fields['moleculartestingtype']&.downcase&.strip
              if (indication == 'AZOVCA') || (reason == 'Mainstreaming Test')
                genotype.add_test_scope(:full_screen)
              elsif !report.nil? && report =~ REPORT_GENETICTESTSCOPE_REGEX
                genotype.add_test_scope(:targeted_mutation)
              else
                scope = TEST_SCOPE_MAP_BRCA[moltesttype]
                scope = :no_genetictestscope if scope.blank?
                genotype.add_test_scope(scope)
              end
            end

            def add_organisationcode_testresult(genotype)
              genotype.attribute_map['organisationcode_testresult'] = '699F0'
            end

            # rubocop:disable Metrics/AbcSize to maintain readability
            def process_positive_records
              if @testresult.scan(BRCA_REGEX).empty?
                process_result_without_brca_genes
              elsif @testresult.scan(NO_EVIDENCE_REGEX).join.size.positive?
                process_noevidence_records
              elsif check_cdna_variant?
                process_testresult_cdna_variants
              elsif @testresult.scan(CHR_VARIANTS_REGEX).size.positive?
                process_chr_variants
              elsif @testresult.scan(CHR_MALFORMED_REGEX).size.positive?
                process_chr_malformed_variants
              elsif check_malformed_cdna_variant?
                process_positive_malformed_variants
              elsif check_emptyreport_result?
                process_empty_testreport_results
              end
            end
            # rubocop:enable Metrics/AbcSize

            def check_cdna_variant?
              @testresult.scan(CDNA_REGEX).size.positive? ||
                @testresult.scan(MUTATION_REGEX).size.positive? ||
                @testresult.scan(MALFORMED_MUTATION_REGEX).size.positive?
            end

            def check_malformed_cdna_variant?
              @testresult.scan(CDNA_REGEX).blank? &&
                @testresult.scan(BRCA_REGEX).size.positive? &&
                @testreport.scan(BRCA_REGEX).size.positive?
            end

            def check_emptyreport_result?
              @testreport.scan(BRCA_REGEX).blank? &&
                @testresult.scan(BRCA_REGEX).size.positive?
            end

            def process_result_without_brca_genes
              positive_gene = BRCA_MALFORMED_GENE_MAPPING[@testresult]
              if full_screen?
                genelist = sometimes_tested? ? unique_brca_genes_from(@testreport) : @genelist
                negativegenes = genelist - [positive_gene]
                process_negative_genes(negativegenes)
              end
              @genotype.add_gene(positive_gene)
              @genotype.add_gene_location(get_cdna_for_positive_cases(@testresult))
              @genotype.add_protein_impact(get_protein_impact(@testresult))
              @genotype.add_status(2)
              add_variantpathclass_uv_records(@genotype)
              @genotypes.append(@genotype)
            end

            def process_noevidence_records
              # regex looks for first period to extract no evidence statement
              # so if not already there, we add it
              @testresult += '.'
              no_evidence = @testresult.scan(NO_EVIDENCE_REGEX).join
              true_variant = @testresult.gsub(NO_EVIDENCE_REGEX, '')
              negativegenes = no_evidence.scan(BRCA_REGEX).flatten - true_variant.
                              scan(BRCA_REGEX).flatten
              process_negative_genes(negativegenes)
              @genotype.add_gene(unique_brca_genes_from(true_variant).join)
              process_cdna(true_variant, @genotype)
              process_protein_impact(true_variant, @genotype)
              process_exon(true_variant, @genotype)
              add_variantpathclass_uv_records(@genotype)
              @genotypes.append(@genotype)
            end

            def process_testresult_cdna_variants
              if (@testresult.scan(CDNA_REGEX).size > 1) ||
                 (@testresult.scan(MUTATION_REGEX).size > 1) ||
                 (@testresult.scan(MALFORMED_MUTATION_REGEX).size > 1)
                process_testresult_multiple_cdnavariant
              else
                process_testresult_single_cdnavariant
              end
            end

            def process_testresult_single_cdnavariant
              process_full_screen_negative_genes
              if unique_brca_genes_from(@testresult).one?
                @genotype.add_gene(unique_brca_genes_from(@testresult).join)
                process_cdna(@testresult, @genotype)
                process_protein_impact(@testresult, @genotype)
                process_exon(@testresult, @genotype)
                add_variantpathclass_uv_records(@genotype)
                @genotypes.append(@genotype)
              else
                process_multigene_multivariants
              end
            end

            def process_testresult_multiple_cdnavariant
              process_full_screen_negative_genes
              genes = unique_brca_genes_from(@testresult)
              if genes.size > 1
                cdnas = collect_cdnas
              elsif genes.one?
                cdnas = check_false_cdnas
                genes *= cdnas.size
              end
              proteins = @testresult.scan(PROTEIN_REGEX).flatten.compact
              if cdnas.size > proteins.size && !proteins.size.zero?
                proteins = [] # to avoid assosciating wrong protein with mutation
              end
              positive_results = genes.zip(cdnas, proteins)
              positive_multiple_cdna_variants(positive_results)
            end

            def check_false_cdnas
              if @testresult.scan(/known as #{CDNA_REGEX}/i).size.positive?
                false_cdnas = @testresult.scan(/known as #{CDNA_REGEX}/i).flatten.compact
                cdnas = @testresult.scan(CDNA_REGEX).flatten.compact - false_cdnas
              else
                cdnas = collect_cdnas
              end
              cdnas
            end

            def positive_multiple_cdna_variants(positive_results)
              positive_results.each do |gene, cdna, protein|
                abnormal_genotype = @genotype.dup
                abnormal_genotype.add_gene(gene)
                abnormal_genotype.add_gene_location(cdna)
                abnormal_genotype.add_protein_impact(protein)
                abnormal_genotype.add_status(2)
                add_variantpathclass_uv_records(abnormal_genotype)
                @genotypes.append(abnormal_genotype)
              end
            end

            def process_multigene_multivariants
              testresult_str = @testresult.remove("\n",
                                                  'BRCA1 and BRCA2 mutation analysis complete.')
              split_gene = unique_brca_genes_from(testresult_str)[0]
              testresult_arr = testresult_str.split(split_gene, 2)
              testresult_arr[0] += split_gene
              testresult_arr.each do |testresult|
                genotype_dup = @genotype.dup
                genes = unique_brca_genes_from(testresult)
                gene = genes.one? ? genes : genes - [split_gene]
                genotype_dup.add_gene(gene[0])
                process_split_testresult(testresult, genotype_dup)
                add_variantpathclass_uv_records(genotype_dup)
                @genotypes.append(genotype_dup)
              end
            end

            def process_split_testresult(testresult, genotype)
              if positive_malformed_cdna?(testresult) ||
                 positive_exonvariant?(testresult) ||
                 positive_cdna?(testresult)
                process_cdna(testresult, genotype)
                process_protein_impact(testresult, genotype)
                process_exon(testresult, genotype)
              else
                genotype.add_status(1)
              end
            end

            def process_chr_variants
              process_full_screen_negative_genes
              process_chromosomal_variant(@testresult)
            end

            def process_chromosomal_variant(testcolumn)
              brca_genes = unique_brca_genes_from(testcolumn)
              @genotype.add_gene(brca_genes.join)
              @genotype.add_variant_type(testcolumn.scan(CHR_VARIANTS_REGEX).uniq.join)
              process_exon(@testresult, @genotype)
              @genotype.add_status(2)
              add_variantpathclass_uv_records(@genotype)
              @genotypes.append(@genotype)
            end

            def process_chr_malformed_variants
              process_full_screen_negative_genes
              gene = unique_brca_genes_from(@testresult)
              duplicated_genotype = @genotype.dup
              duplicated_genotype.add_status(2)
              duplicated_genotype.add_gene(gene.join)
              duplicated_genotype.add_gene_location(get_cdna_for_positive_cases(@testresult))
              process_protein_impact(@testresult, duplicated_genotype)
              process_exon(@testresult, duplicated_genotype)
              add_variantpathclass_uv_records(duplicated_genotype)
              @genotypes.append(duplicated_genotype)
            end

            def process_positive_malformed_variants
              if !@testreport.nil? &&
                 @testresult.scan(CDNA_REGEX).blank? &&
                 @testreport.scan(CDNA_REGEX).blank? &&
                 @testreport.scan(BRCA_REGEX).size.positive?
                process_full_screen_negative_genes
                genes = unique_brca_genes_from(@testresult)
                genes.each do |gene|
                  duplicated_genotype = @genotype.dup
                  duplicated_genotype.add_status(2)
                  duplicated_genotype.add_gene(gene)
                  duplicated_genotype.add_gene_location('')
                  add_variantpathclass_uv_records(duplicated_genotype)
                  @genotypes.append(duplicated_genotype)
                end
              end
            end

            def process_empty_testreport_results
              @genotype.add_status(2)
              @genotype.add_gene(unique_brca_genes_from(@testresult).join)
              @genotype.add_gene_location('')
              add_variantpathclass_uv_records(@genotype)
              @genotypes.append(@genotype)
            end

            def unique_brca_genes_from(string)
              string.scan(BRCA_REGEX).flatten.uniq
            end

            def full_screen?
              return if @genotype.attribute_map['genetictestscope'].nil?

              @genotype.attribute_map['genetictestscope'].scan(/Full screen/i).size.positive?
            end

            def process_negative_records
              if full_screen?
                negativegenes = sometimes_tested? ? unique_brca_genes_from(@testreport) : @genelist
              else
                testreport_genes = unique_brca_genes_from(@testreport)
                negativegenes = testreport_genes.flatten.uniq
              end
              process_negative_genes(negativegenes)
            end

            def process_full_screen_negative_genes
              return unless full_screen?

              genelist = sometimes_tested? ? unique_brca_genes_from(@testreport) : @genelist
              negativegenes = genelist - unique_brca_genes_from(@testresult)
              process_negative_genes(negativegenes)
            end

            def process_negative_genes(negativegenes)
              negativegenes.each do |negativegene|
                duplicated_genotype = @genotype.dup
                @logger.debug "Found #{negativegene} for list #{negativegenes}"
                duplicated_genotype.add_status(1)
                duplicated_genotype.add_gene(negativegene)
                duplicated_genotype.add_protein_impact(nil)
                duplicated_genotype.add_gene_location(nil)
                @genotypes.append(duplicated_genotype)
              end
            end

            def positive_cdna?(testresult)
              testresult.scan(CDNA_REGEX).size.positive? ||
                testresult.scan(MUTATION_REGEX).size.positive?
            end

            def positive_malformed_cdna?(testresult)
              testresult.scan(MALFORMED_MUTATION_REGEX).size.positive?
            end

            def positive_exonvariant?(testresult)
              testresult.scan(EXON_LOCATION).size.positive?
            end

            def process_cdna(testcolumn, genotype)
              if testcolumn.scan(CDNA_REGEX).size.positive?
                genotype.add_status(2)
                genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              elsif testcolumn.scan(MUTATION_REGEX).size.positive?
                genotype.add_status(2)
                genotype.add_gene_location($LAST_MATCH_INFO[:mutation])
              elsif testcolumn.scan(MALFORMED_MUTATION_REGEX).size.positive?
                genotype.add_status(2)
                genotype.add_gene_location($LAST_MATCH_INFO[:cdnamutation])
              end
            end

            def get_cdna_for_positive_cases(testcolumn)
              if testcolumn.scan(CDNA_REGEX).size.positive?
                $LAST_MATCH_INFO[:cdna]
              elsif testcolumn.scan(MUTATION_REGEX).size.positive?
                $LAST_MATCH_INFO[:mutation]
              elsif testcolumn.scan(MALFORMED_MUTATION_REGEX).size.positive?
                $LAST_MATCH_INFO[:cdnamutation]
              else
                ''
              end
            end

            def get_protein_impact(testcolumn)
              testcolumn.match(PROTEIN_REGEX)
              $LAST_MATCH_INFO[:impact] unless $LAST_MATCH_INFO.nil?
            end

            def collect_cdnas
              cdnas = @testresult.scan(CDNA_REGEX).flatten.compact
              cdnas = @testresult.scan(MUTATION_REGEX).flatten.compact unless cdnas.size.positive?
              unless cdnas.size.positive?
                cdnas = @testresult.scan(MALFORMED_MUTATION_REGEX).flatten.compact
              end
              cdnas
            end

            def process_protein_impact(testcolumn, genotype)
              return unless testcolumn.scan(PROTEIN_REGEX).size.positive?

              genotype.add_status(2)
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
            end

            def process_exon(testcolumn, genotype)
              return unless testcolumn.scan(EXON_LOCATION).size.positive?

              genotype.add_status(2)
              genotype.add_exon_location($LAST_MATCH_INFO[:exons])
            end

            def sometimes_tested?
              @record.raw_fields['indication'] == 'BRCA' ||
                @record.raw_fields['indication'] == 'PANCA' ||
                @record.raw_fields['indication'] == 'OVARIAN' ||
                @record.raw_fields['indication'] == 'LFS'
            end
          end
        end
      end
    end
  end
end
