module Import
  module Helpers
    module Colorectal
      module Providers
        module Rq3
          # Processing methods used by BirminghamHandlerColorectal
          module Rq3Helper
            include Import::Helpers::Colorectal::Providers::Rq3::Rq3Constants

            def process_genetictestscope(genocolorectal, record)
              Maybe(record.raw_fields['moleculartestingtype']).each do |tscope|
                if TEST_SCOPE_MAP_COLO[tscope.downcase.strip]
                  genocolorectal.add_test_scope(TEST_SCOPE_MAP_COLO[tscope.downcase.strip])
                else
                  genocolorectal.add_test_scope(:no_genetictestscope)
                end
              end
            end

            def add_organisationcode_testresult(genocolorectal)
              genocolorectal.attribute_map['organisationcode_testresult'] = '699F0'
            end

            def full_screen?(record)
              moleculartestingtype = record.raw_fields['moleculartestingtype'].downcase.strip
              testscope = TEST_SCOPE_MAP_COLO[moleculartestingtype]
              testscope == :full_screen
            end

            def process_negative_genes(negativegenes)
              negativegenes.each do |negativegene|
                dup_genocolorectal = @genocolorectal.dup_colo
                @logger.debug "Found #{negativegene} for list #{negativegenes}"
                dup_genocolorectal.add_status(1)
                dup_genocolorectal.add_gene_colorectal(negativegene)
                dup_genocolorectal.add_protein_impact(nil)
                dup_genocolorectal.add_gene_location(nil)
                @genotypes.append(dup_genocolorectal)
              end
            end

            def positive_multiple_chromosomal_variants(positive_results)
              positive_results.each do |gene, chromosomalvariant|
                abnormal_genocolorectal = @genocolorectal.dup_colo
                abnormal_genocolorectal.add_gene_colorectal(gene)
                abnormal_genocolorectal.add_status(2)
                abnormal_genocolorectal.add_variant_type(chromosomalvariant)
                @genotypes.append(abnormal_genocolorectal)
              end
            end

            def positive_multiple_cdna_variants(positive_results)
              positive_results.each do |gene, cdna, protein|
                abnormal_genocolorectal = @genocolorectal.dup_colo
                abnormal_genocolorectal.add_gene_colorectal(gene)
                abnormal_genocolorectal.add_gene_location(cdna)
                abnormal_genocolorectal.add_protein_impact(protein)
                abnormal_genocolorectal.add_status(2)
                @genotypes.append(abnormal_genocolorectal)
              end
            end

            def process_mutyh_single_cdna_variants
              @genocolorectal.add_gene_colorectal('MUTYH')
              @genocolorectal.add_gene_location(@testresult.scan(CDNA_REGEX).join)
              @genocolorectal.add_status(2)
              if @testresult.scan(PROTEIN_REGEX).size.positive?
                @genocolorectal.add_protein_impact(@testresult.scan(PROTEIN_REGEX).join)
              end
              @genotypes.append(@genocolorectal)
            end

            def process_mutyh_specific_variants
              if @testresult.scan(CDNA_REGEX).size.positive?
                process_positive_mutyh_variants
              else
                @genocolorectal.add_gene_colorectal('MUTYH')
                @genocolorectal.add_gene_location('')
                @genocolorectal.add_status(2)
                @genotypes.append(@genocolorectal)
                if full_screen?(@record)
                  negativegenes = @genelist - ['MUTYH']
                  process_negative_genes(negativegenes)
                end
              end
            end

            def process_positive_mutyh_variants
              case @testresult.scan(CDNA_REGEX).size
              when 1
                process_mutyh_single_cdna_variants
              when 2
                genes = ['MUTYH'] * @testresult.scan(CDNA_REGEX).size
                cdnas = @testresult.scan(CDNA_REGEX).flatten
                proteins = @testresult.scan(PROTEIN_REGEX).flatten
                positive_results = genes.zip(cdnas, proteins)
                positive_multiple_cdna_variants(positive_results)
              end
              return unless full_screen?(@record)

              negativegenes = @genelist - ['MUTYH']
              process_negative_genes(negativegenes)
            end

            def process_testreport_cdna_variants
              genes_size = @testreport.scan(COLORECTAL_GENES_REGEX).uniq.size
              if genes_size == 1
                @genocolorectal.add_gene_colorectal(unique_colorectal_genes_from(@testreport).join)
                @genocolorectal.add_gene_location(@testreport.scan(CDNA_REGEX).join)
                @genocolorectal.add_status(2)
                if @testreport.scan(PROTEIN_REGEX).size.positive?
                  @genocolorectal.add_protein_impact(@testreport.scan(PROTEIN_REGEX).join)
                end
                @genotypes.append(@genocolorectal)
              elsif genes_size == 2 && @testreport.scan(CDNA_REGEX).size == 2
                process_multicdnavariants
              end
            end

            def process_multicdnavariants
              genes = colorectal_genes_from(@testreport)
              cdnas = @testreport.scan(CDNA_REGEX).flatten
              proteins = @testreport.scan(PROTEIN_REGEX).flatten
              positive_results = genes.zip(cdnas, proteins)
              positive_multiple_cdna_variants(positive_results)
            end

            def process_malformed_variants
              if (@testresult =~ /FAP/ && @testreport.scan(/APC/i).size.positive?) ||
                 (@testresult =~ /High risk haplotype identified in this patient/ &&
                 @testreport.scan(/APC/i).size.positive?)
                gene = 'APC'
              elsif @testreport.match(COLORECTAL_GENES_REGEX)
                gene = @testreport.match(COLORECTAL_GENES_REGEX)[0]
              end
              @genocolorectal.add_gene_colorectal(gene)
              if full_screen?(@record)
                negativegenes = @genelist - [gene]
                process_negative_genes(negativegenes)
              end
              @genocolorectal.add_gene_location('')
              @genocolorectal.add_status(2)
              @genotypes.append(@genocolorectal)
            end

            def process_testresult_cdna_variants
              case @testresult.scan(CDNA_REGEX).size
              when 1
                process_testresult_single_cdnavariant
              when 2
                process_testresult_multiple_cdnavariant
              end
            end

            def process_chr_variants
              process_full_screen if full_screen?(@record)
              process_chromosomal_variant(@testresult)
            end

            def process_full_screen
              genelist = if sometimes_tested?(@record)
                           unique_colorectal_genes_from(@testreport)
                         else
                           COLORECTAL_GENES_MAP[@record.raw_fields['indication']]
                         end
              negativegenes = genelist - unique_colorectal_genes_from(@testresult)
              process_negative_genes(negativegenes)
            end

            def process_chromosomal_variant(testcolumn)
              colorectal_genes = unique_colorectal_genes_from(testcolumn)
              if colorectal_genes.one?
                varianttype = get_varianttype(testcolumn)
                @genocolorectal.add_variant_type(varianttype)
                @genocolorectal.add_gene_colorectal(colorectal_genes.join)
                @genocolorectal.add_status(2)
                @genotypes.append(@genocolorectal)
              elsif colorectal_genes.size > 1
                genes = colorectal_genes_from(testcolumn)
                chromosomalvariants = get_chromosomalvariants(testcolumn, genes)
                positive_results = genes.zip(chromosomalvariants)
                positive_multiple_chromosomal_variants(positive_results)
              end
            end

            def get_chromosomalvariants(testcolumn, genes)
              if testcolumn.scan(CHR_VARIANTS_REGEX).size == 1
                testcolumn.scan(CHR_VARIANTS_REGEX).flatten * genes.size
              else
                testcolumn.scan(CHR_VARIANTS_REGEX).flatten
              end
            end

            def get_varianttype(testcolumn)
              if testcolumn.scan(CHR_VARIANTS_REGEX).size == 1
                testcolumn.scan(CHR_VARIANTS_REGEX).join
              else
                testcolumn.scan(CHR_VARIANTS_REGEX)[1]
              end
            end

            def process_positive_records
              @logger.debug 'ABNORMAL TEST'
              @genocolorectal.add_variant_class(3) if @posnegtest.upcase == 'UV'
              if @testresult.scan(/MYH/).size.positive?
                process_mutyh_specific_variants
              elsif colorectal_genes_from_test_result.empty?
                process_result_without_colorectal_genes
              elsif @testresult.scan(CDNA_REGEX).size.positive?
                process_testresult_cdna_variants
              elsif @testresult.scan(CHR_VARIANTS_REGEX).size.positive?
                process_chr_variants
              elsif @testresult.match(/No known pathogenic/i)
                process_negative_genes(@genelist)
              else
                process_remainder
              end
            end

            def process_negative_records
              @logger.debug 'NORMAL TEST FOUND'
              if full_screen?(@record)
                testreportgenes = unique_colorectal_genes_from(@testreport)
                negativegenes = sometimes_tested?(@record) ? testreportgenes : @genelist
              elsif !full_screen?(@record) && @testreport.match(/MYH/i)
                negativegenes = ['MUTYH']
              else
                testreportgenes = unique_colorectal_genes_from(@testreport)
                negativegenes = testreportgenes.flatten.uniq
              end
              process_negative_genes(negativegenes)
            end

            def process_testresult_single_cdnavariant
              if unique_colorectal_genes_from(@testresult).one?
                process_full_screen_negatives
                @genocolorectal.add_gene_colorectal(unique_colorectal_genes_from(@testresult).join)
              else
                process_fs_single_cdnavariant if full_screen?(@record)
                @genocolorectal.add_gene_colorectal(unique_colorectal_genes_from(@testresult)[0])
              end
              @genocolorectal.add_gene_location(@testresult.scan(CDNA_REGEX).join)
              @genocolorectal.add_status(2)
              if @testresult.scan(PROTEIN_REGEX).size.positive?
                @genocolorectal.add_protein_impact(@testresult.scan(PROTEIN_REGEX).join)
              end
              @genotypes.append(@genocolorectal)
            end

            def process_fs_single_cdnavariant
              if sometimes_tested?(@record)
                genelist = unique_colorectal_genes_from(@testreport)
                negativegenes = genelist - unique_colorectal_genes_from(@testresult)
              else
                negativegenes = @genelist - [unique_colorectal_genes_from(@testresult)[0]]
              end
              process_negative_genes(negativegenes)
            end

            def sometimes_tested?(record)
              record.raw_fields['indication'] == 'HNPCC' ||
                record.raw_fields['indication'] == 'COLON' ||
                record.raw_fields['indication'] == 'NGS_COLON' ||
                record.raw_fields['indication'] == 'POLY'
            end

            def process_testresult_multiple_cdnavariant
              process_full_screen_negatives
              if @testresult.scan(COLORECTAL_GENES_REGEX).uniq.size == 2
                genes = colorectal_genes_from(@testresult)
              elsif unique_colorectal_genes_from(@testresult).one?
                genes = unique_colorectal_genes_from(@testresult) * 2
              end
              cdnas = @testresult.scan(CDNA_REGEX).flatten
              proteins = @testresult.scan(PROTEIN_REGEX).flatten
              positive_results = genes.zip(cdnas, proteins)
              positive_multiple_cdna_variants(positive_results)
            end

            def process_full_screen_negatives
              return unless full_screen?(@record)

              if sometimes_tested?(@record)
                genelist = unique_colorectal_genes_from(@testreport)
                negativegenes = genelist - unique_colorectal_genes_from(@testresult)
              else
                negativegenes = @genelist - unique_colorectal_genes_from(@testresult)
              end
              process_negative_genes(negativegenes)
            end

            def colorectal_genes_from(string)
              string.scan(COLORECTAL_GENES_REGEX).flatten
            end

            def unique_colorectal_genes_from(string)
              colorectal_genes_from(string).uniq
            end
          end
        end
      end
    end
  end
end
