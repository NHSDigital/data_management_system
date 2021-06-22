module Import
  module Helpers
    module Brca
      module Providers
        module Rq3
          module Rq3Helper
            include Import::Helpers::Brca::Providers::Rq3::Rq3Constants

            def process_genetictestscope(genotype, record)
              indication = record.raw_fields['indication']
              reason = record.raw_fields['reason']
              report = record.raw_fields['report'] unless record.raw_fields['report'].nil?
              moltesttype = record.raw_fields['moleculartestingtype']
              if indication == 'AZOVCA'
                genotype.add_test_scope(:full_screen)
              elsif reason == 'Mainstreaming Test'
                genotype.add_test_scope(:full_screen)
              elsif !report.nil? && report =~ /previously identified in this family|previously reported in this family|previously found in an affected relative/
                genotype.add_test_scope(:targeted_mutation)
              elsif TEST_SCOPE_MAP_BRCA[moltesttype.downcase.strip]
                scope = TEST_SCOPE_MAP_BRCA[moltesttype.strip.downcase]
                genotype.add_test_scope(scope)
              end
            end

            def add_organisationcode_testresult(genotype)
              genotype.attribute_map['organisationcode_testresult'] = '699F0'
            end

            def process_noevidence_records
              no_evidence = @testresult.scan(/no evidence(?!\.).+[^.]|no further(?!\.).+[^.]/i).join
              true_variant = @testresult.gsub(/no evidence(?!\.).+[^.]|no further(?!\.).+[^.]/i, '')
              negativegenes = no_evidence.scan(BRCA_REGEX).flatten - true_variant.scan(BRCA_REGEX).flatten
              process_negative_genes(negativegenes)
              @genotype.add_gene(unique_brca_genes_from(true_variant).join)
              @genotype.add_gene_location(true_variant.scan(CDNA_REGEX).join)
              @genotype.add_status(2)
              if true_variant.scan(PROTEIN_REGEX).size.positive?
                @genotype.add_protein_impact(true_variant.scan(PROTEIN_REGEX).join)
              end
              @genotypes.append(@genotype)
            end

            def process_testreport_cdna_variants
              case @testreport.scan(CDNA_REGEX).size
              when 1
                if testreport.scan(BRCA_REGEX).uniq.size == 1
                  genocolorectal.add_gene_colorectal(unique_colorectal_genes_from(testreport).join)
                  genocolorectal.add_gene_location(testreport.scan(CDNA_REGEX).join)
                  genocolorectal.add_status(2)
                  if @testreport.scan(PROTEIN_REGEX).size.positive?
                    genocolorectal.add_protein_impact(@testreport.scan(PROTEIN_REGEX).join)
                  end
                  @genotypes.append(genocolorectal)
                end
              when 2
                if @testreport.scan(BRCA_REGEX).uniq.size == 2
                  genes = brca_genes_from(@testreport)
                  cdnas = @testreport.scan(CDNA_REGEX).flatten
                  proteins = @testreport.scan(PROTEIN_REGEX).flatten
                  positive_results = genes.zip(cdnas, proteins)
                  positive_multiple_cdna_variants(positive_results, @genotypes, genocolorectal)
                end
              end
            end

            def process_empty_testreport_results
              @genotype.add_status(2)
              @genotype.add_gene(brca_genes_from(@testresult).join)
              @genotype.add_gene_location('')
              @genotypes.append(@genotype)
            end

            def process_testresult_cdna_variants
              if @testresult.scan(CDNA_REGEX).size == 1
                process_testresult_single_cdnavariant
              else
                process_testresult_multiple_cdnavariant
              end
            end

            def process_testresult_single_cdnavariant
              if unique_brca_genes_from(@testresult).one?
                if full_screen?
                  genelist = sometimes_tested? ? unique_brca_genes_from(@testreport) : @genelist
                  negativegenes = genelist - unique_brca_genes_from(@testresult)
                  process_negative_genes(negativegenes)
                end
                @genotype.add_gene(unique_brca_genes_from(@testresult).join)
              else
                if full_screen?
                  if sometimes_tested?
                    genelist = unique_brca_genes_from(@testreport)
                    negativegenes = genelist - unique_brca_genes_from(@testresult)
                  else
                    negativegenes = @genelist - [unique_brca_genes_from(@testresult)[0]]
                  end
                  process_negative_genes(negativegenes)
                end
                @genotype.add_gene(unique_brca_genes_from(@testresult)[0])
              end
              @genotype.add_gene_location(@testresult.scan(CDNA_REGEX).join)
              if @testresult.scan(PROTEIN_REGEX).size.positive?
                @genotype.add_protein_impact(@testresult.scan(PROTEIN_REGEX).join)
              end
              @genotype.add_status(2)
              @genotypes.append(@genotype)
            end

            def process_testresult_multiple_cdnavariant
              if @testresult.scan(BRCA_REGEX).uniq.size > 1
                if full_screen?
                  genelist = sometimes_tested? ? unique_brca_genes_from(@testreport) : @genelist
                  negativegenes = genelist - unique_brca_genes_from(@testresult)
                  process_negative_genes(negativegenes)
                end
                genes = brca_genes_from(@testresult)
                cdnas = @testresult.scan(CDNA_REGEX).flatten
                proteins = @testresult.scan(PROTEIN_REGEX).flatten
                positive_results = genes.zip(cdnas, proteins)
                positive_multiple_cdna_variants(positive_results)
              elsif unique_brca_genes_from(@testresult).one?
                if full_screen?
                  genelist = sometimes_tested? ? unique_brca_genes_from(@testreport) : @genelist
                  negativegenes = genelist - unique_brca_genes_from(@testresult)
                  process_negative_genes(negativegenes)
                end
                if @testresult.scan(/known as #{CDNA_REGEX}/i).size.positive?
                  false_cdnas = @testresult.scan(/known as #{CDNA_REGEX}/i).flatten
                  cdnas = @testresult.scan(CDNA_REGEX).flatten - false_cdnas
                else cdnas = @testresult.scan(CDNA_REGEX).flatten
                end
                genes = unique_brca_genes_from(@testresult) * cdnas.size
                proteins = @testresult.scan(PROTEIN_REGEX).flatten
                positive_results = genes.zip(cdnas, proteins)
                positive_multiple_cdna_variants(positive_results)
              end
            end

            def process_chr_variants
              if full_screen?
                genelist = if sometimes_tested?
                             unique_brca_genes_from(@testreport)
                           else
                             BRCA_GENES_MAP[@record.raw_fields['indication']]
                           end
                negativegenes = genelist - unique_brca_genes_from(@testresult)
                process_negative_genes(negativegenes)
              end
              process_chromosomal_variant(@testresult)
            end

            def process_chromosomal_variant(testcolumn)
              brca_genes = unique_brca_genes_from(testcolumn)
              if brca_genes.one?
                @genotype.add_gene(brca_genes.join)
                if testcolumn.scan(CHR_VARIANTS_REGEX).size == 1
                  @genotype.add_variant_type(testcolumn.scan(CHR_VARIANTS_REGEX).join)
                else
                  @genotype.add_variant_type(testcolumn.scan(CHR_VARIANTS_REGEX)[1])
                end
                @genotype.add_status(2)
                @genotypes.append(@genotype)
              elsif brca_genes.size > 1
                genes = brca_genes_from(testcolumn)
                if testcolumn.scan(CHR_VARIANTS_REGEX).size == 1
                  chromosomalvariants = testcolumn.scan(CHR_VARIANTS_REGEX).flatten * genes.size
                else
                  genes = brca_genes_from(testcolumn)
                  chromosomalvariants = testcolumn.scan(CHR_VARIANTS_REGEX).flatten
                end
                positive_results = genes.zip(chromosomalvariants)
                positive_multiple_chromosomal_variants(positive_results)
              end
            end

            def positive_multiple_chromosomal_variants(positive_results)
              positive_results.each do |gene, chromosomalvariant|
                abnormal_genotype = @genotype.dup
                abnormal_genotype.add_gene(gene)
                abnormal_genotype.add_status(2)
                abnormal_genotype.add_variant_type(chromosomalvariant)
                @genotypes.append(abnormal_genotype)
              end
            end

            def positive_multiple_cdna_variants(positive_results)
              positive_results.each do |gene, cdna, protein|
                abnormal_genotype = @genotype.dup
                abnormal_genotype.add_gene(gene)
                abnormal_genotype.add_gene_location(cdna)
                abnormal_genotype.add_protein_impact(protein)
                abnormal_genotype.add_status(2)
                @genotypes.append(abnormal_genotype)
              end
            end

            def unique_brca_genes_from(string)
              brca_genes_from(string).uniq
            end

            def brca_genes_from(string)
              string.scan(BRCA_REGEX).flatten
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

            def full_screen?
              @genotype.attribute_map['genetictestscope'] == 'Full screen BRCA1 and BRCA2'
            end

            def process_negative_records
              @logger.debug 'NORMAL TEST FOUND'
              if full_screen?
                negativegenes = if sometimes_tested?
                                  unique_brca_genes_from(@testreport)
                                else
                                  @genelist
                                end
              else
                testreport_genes = unique_brca_genes_from(@testreport)
                negativegenes = testreport_genes.flatten.uniq
              end
              process_negative_genes(negativegenes)
            end

            def process_positive_malformed_variants
              if !@testreport.nil? &&
                 @testresult.scan(CDNA_REGEX).blank? &&
                 @testreport.scan(CDNA_REGEX).blank? &&
                 @testreport.scan(BRCA_REGEX).size.positive?
                if full_screen?
                  genelist = sometimes_tested? ? unique_brca_genes_from(@testreport) : @genelist
                  negativegenes = genelist - unique_brca_genes_from(@testresult)
                  process_negative_genes(negativegenes)
                end
                genes = brca_genes_from(@testreport)
                genes.uniq do |gene|
                  duplicated_genotype = @genotype.dup
                  duplicated_genotype.add_status(2)
                  duplicated_genotype.add_gene(gene)
                  duplicated_genotype.add_gene_location('')
                  @genotypes.append(duplicated_genotype)
                end
              end
            end

            def sometimes_tested?
              @record.raw_fields['indication'] == 'BRCA'
            end
          end
        end
      end
    end
  end
end
