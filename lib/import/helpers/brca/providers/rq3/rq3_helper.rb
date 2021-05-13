module Import
  module Helpers
    module Brca
      module Providers
        module Rq3
          # Processing methods used by BirminghamHandlerColorectal
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
              elsif TEST_SCOPE_MAP_COLO_COLO[moltesttype.downcase.strip]
                scope = TEST_SCOPE_MAP_COLO_COLO[moltesttype.strip.downcase]
                genotype.add_test_scope(scope)
              end
            end

            def add_organisationcode_testresult(genotype)
              genotype.attribute_map['organisationcode_testresult'] = '699F0'
            end

            def process_testreport_cdna_variants(testreport, genotypes, _genotype)
              case testreport.scan(CDNA_REGEX).size
              when 1
                if testreport.scan(BRCA_REGEX).uniq.size == 1
                  genocolorectal.add_gene_colorectal(unique_colorectal_genes_from(testreport).join)
                  genocolorectal.add_gene_location(testreport.scan(CDNA_REGEX).join)
                  genocolorectal.add_status(2)
                  if testreport.scan(PROTEIN_REGEX).size.positive?
                    genocolorectal.add_protein_impact(testreport.scan(PROTEIN_REGEX).join)
                  end
                  genotypes.append(genocolorectal)
                end
              when 2
                if testreport.scan(BRCA_REGEX).uniq.size == 2
                  genes = brca_genes_from(testreport)
                  cdnas = testreport.scan(CDNA_REGEX).flatten
                  proteins = testreport.scan(PROTEIN_REGEX).flatten
                  positive_results = genes.zip(cdnas, proteins)
                  positive_multiple_cdna_variants(positive_results, genotypes, genocolorectal)
                end
              end
            end

            def process_empty_testreport_results(testresult, _genelist, genotypes, _record, genotype)
              genotype.add_status(2)
              genotype.add_gene(brca_genes_from(testresult).join)
              genotype.add_gene_location('')
              genotypes.append(genotype)
            end

            def process_testresult_cdna_variants(testresult, testreport, genelist, genotypes, record, genotype)
              case testresult.scan(CDNA_REGEX).size
              when 1
                process_testresult_single_cdnavariant(testresult, testreport, record, genelist,
                                                      genotypes, genotype)
              when 2
                process_testresult_multiple_cdnavariant(testresult, testreport, record, genelist,
                                                        genotypes, genotype)
              end
            end

            def process_testresult_single_cdnavariant(testresult, testreport, record,
                                                      genelist, genotypes, genotype)
              if unique_brca_genes_from(testresult).one?
                if full_screen?(record)
                  if sometimes_tested?(record)
                    genelist = unique_brca_genes_from(testreport)
                    negativegenes = genelist - unique_brca_genes_from(testresult)
                    process_negative_genes(negativegenes, genotypes, genotype)
                  else
                    negativegenes = genelist - unique_brca_genes_from(testresult)
                    process_negative_genes(negativegenes, genotypes, genotype)
                  end
                end
                genotype.add_gene(@testprocessor.find_single_true_positives(@testresult)[:gene])
                genotype.add_gene_location(@testprocessor.find_single_true_positives(@testresult)[:cdna])
                genotype.add_status(2)
                if !@testprocessor.find_single_true_positives(@testresult).nil?
                  genotype.add_protein_impact(@testprocessor.find_single_true_positives(@testresult)[:protein])
                end
                genotypes.append(genotype)
              else
                if full_screen?(record)
                  if sometimes_tested?(record)
                    genelist = unique_brca_genes_from(testreport)
                    negativegenes = genelist - unique_brca_genes_from(testresult)
                    process_negative_genes(negativegenes, genotypes, genotype)
                  else
                    negativegenes = genelist - [unique_brca_genes_from(testresult)[0]]
                    process_negative_genes(negativegenes, genotypes, genotype)
                  end
                end
                genotype.add_gene(unique_brca_genes_from(testresult)[0])
                genotype.add_gene_location(testresult.scan(CDNA_REGEX).join)
                genotype.add_status(2)
                if testresult.scan(PROTEIN_REGEX).size.positive?
                  genotype.add_protein_impact(testresult.scan(PROTEIN_REGEX).join)
                end
                genotypes.append(genotype)
              end
            end

            def process_testresult_multiple_cdnavariant(testresult, testreport, record,
                                                        genelist, genotypes, genotype)
              if testresult.scan(BRCA_REGEX).uniq.size == 2
                if full_screen?(record)
                  if sometimes_tested?(record)
                    genelist = unique_brca_genes_from(testreport)
                    negativegenes = genelist - unique_brca_genes_from(testresult)
                    process_negative_genes(negativegenes, genotypes, genotype)
                  else
                    negativegenes = genelist - unique_brca_genes_from(testresult)
                    process_negative_genes(negativegenes, genotypes, genotype)
                  end
                end
                genes = brca_genes_from(testresult)
                cdnas = testresult.scan(CDNA_REGEX).flatten
                proteins = testresult.scan(PROTEIN_REGEX).flatten
                positive_results = genes.zip(cdnas, proteins)
                positive_multiple_cdna_variants(positive_results, genotypes, genotype)
              elsif unique_brca_genes_from(testresult).one?
                if full_screen?(record)
                  if sometimes_tested?(record)
                    genelist = unique_brca_genes_from(testreport)
                    negativegenes = genelist - unique_brca_genes_from(testresult)
                    process_negative_genes(negativegenes, genotypes, genotype)
                  else
                    negativegenes = genelist - unique_brca_genes_from(testresult)
                    process_negative_genes(negativegenes, genotypes, genotype)
                  end
                end
                genes = unique_brca_genes_from(testresult) * 2
                cdnas = testresult.scan(CDNA_REGEX).flatten
                proteins = testresult.scan(PROTEIN_REGEX).flatten
                positive_results = genes.zip(cdnas, proteins)
                positive_multiple_cdna_variants(positive_results, genotypes, genotype)
              end
            end

            def process_chr_variants(record, testresult, testreport, genotypes, genotype)
              if full_screen?(record)
                if sometimes_tested?(record)
                  genelist = unique_brca_genes_from(testreport)
                  negativegenes = genelist - unique_brca_genes_from(testresult)
                  process_negative_genes(negativegenes, genotypes, genotype)
                else
                  genelist = BRCA_GENES_MAP[record.raw_fields['indication']]
                  negativegenes = genelist - unique_brca_genes_from(testresult)
                  process_negative_genes(negativegenes, genotypes, genotype)
                end
              end
              testcolumn = testresult
              process_chromosomal_variant(testcolumn, genelist, genotypes, record, genotype)
            end

            def process_chromosomal_variant(testcolumn, _genelist, genotypes, _record, genotype)
              brca_genes = unique_brca_genes_from(testcolumn)
              if brca_genes.one?
                if testcolumn.scan(CHR_VARIANTS_REGEX).size == 1
                  genotype.add_gene(brca_genes.join)
                  genotype.add_variant_type(testcolumn.scan(CHR_VARIANTS_REGEX).join)
                  genotype.add_status(2)
                  genotypes.append(genotype)
                else
                  genotype.add_gene(brca_genes.join)
                  genotype.add_variant_type(testcolumn.scan(CHR_VARIANTS_REGEX)[1])
                  genotype.add_status(2)
                  genotypes.append(genotype)
                end
              elsif brca_genes.size > 1
                if testcolumn.scan(CHR_VARIANTS_REGEX).size == 1
                  genes = brca_genes_from(testcolumn)
                  chromosomalvariants = testcolumn.scan(CHR_VARIANTS_REGEX).flatten * genes.size
                  positive_results = genes.zip(chromosomalvariants)
                  positive_multiple_chromosomal_variants(positive_results, genotypes, genotype)
                else
                  genes = brca_genes_from(testcolumn)
                  chromosomalvariants = testcolumn.scan(CHR_VARIANTS_REGEX).flatten
                  positive_results = genes.zip(chromosomalvariants)
                  positive_multiple_chromosomal_variants(positive_results, genotypes, genotype)
                end
              end
            end

            def positive_multiple_chromosomal_variants(positive_results, genotypes, genotype)
              positive_results.each do |gene, chromosomalvariant|
                abnormal_genotype = genotype.dup
                abnormal_genotype.add_gene(gene)
                abnormal_genotype.add_status(2)
                abnormal_genotype.add_variant_type(chromosomalvariant)
                genotypes.append(abnormal_genotype)
              end
            end

            def positive_multiple_cdna_variants(positive_results, genotypes, genotype)
              positive_results.each do |gene, cdna, protein|
                abnormal_genotype = genotype.dup
                abnormal_genotype.add_gene(gene)
                abnormal_genotype.add_gene_location(cdna)
                abnormal_genotype.add_protein_impact(protein)
                abnormal_genotype.add_status(2)
                genotypes.append(abnormal_genotype)
              end
            end

            def unique_brca_genes_from(string)
              brca_genes_from(string).uniq
            end

            def brca_genes_from(string)
              string.scan(BRCA_REGEX).flatten
            end

            def process_negative_genes(negativegenes, genotypes, genotype)
              negativegenes.each do |negativegene|
                duplicated_genotype = genotype.dup
                @logger.debug "Found #{negativegene} for list #{negativegenes}"
                duplicated_genotype.add_status(1)
                duplicated_genotype.add_gene(negativegene)
                duplicated_genotype.add_protein_impact(nil)
                duplicated_genotype.add_gene_location(nil)
                genotypes.append(duplicated_genotype)
              end
            end

            def full_screen?(_genotype)
              @genotype.attribute_map['genetictestscope'] == 'Full screen BRCA1 and BRCA2'
            end

            def process_negative_records(genelist, genotypes, testresult,
                                         testreport, record, genotype)
              @logger.debug 'NORMAL TEST FOUND'
              if full_screen?(record)
                if sometimes_tested?(record)
                  negativegenes = unique_brca_genes_from(testreport)
                else
                  negativegenes = genelist
                end
              else
                testresultgenes = unique_brca_genes_from(testresult)
                testreportgenes = unique_brca_genes_from(testreport)
                negativegenes = testreportgenes.flatten.uniq
              end
              process_negative_genes(negativegenes, genotypes, genotype)
            end

            def process_positive_malformed_variants(genelist, genotypes, testresult,
                                                    testreport, record, genotype)
              if !testreport.nil? &&
                 testresult.scan(CDNA_REGEX).blank? &&
                 testreport.scan(CDNA_REGEX).blank? &&
                 testreport.scan(BRCA_REGEX).size.positive?
                if full_screen?(record)
                  negativegenes = genelist - unique_brca_genes_from(testresult)
                  process_negative_genes(negativegenes, genotypes, genotype)
                end
                genes = brca_genes_from(testreport)
                genes.uniq do |gene|
                  duplicated_genotype = genotype.dup
                  duplicated_genotype.add_status(2)
                  duplicated_genotype.add_gene(gene)
                  duplicated_genotype.add_gene_location('')
                  genotypes.append(duplicated_genotype)
                end
              end
            end

            def sometimes_tested?(record)
              record.raw_fields['indication'] == 'BRCA'
            end
            # if !@testreport.nil? &&
            #   @testresult.scan(CDNA_REGEX).blank? &&
            #   @testreport.scan(CDNA_REGEX).blank? &&
            #   @testreport.scan(BRCA_REGEX).size.positive?
            #   if full_screen?(@record)
            #     negativegenes = @genelist - unique_brca_genes_from(@testresult)
            #     process_negative_genes(negativegenes, @genotypes, @genotype)
            #   end
            #   genes = brca_genes_from(@testreport)
            #   genes.uniq do |gene|
            #     @logger.debug "FUCCKITY for list #{gene}"
            #     duplicated_genotype = @genotype.dup
            #     duplicated_genotype.add_status(2)
            #     duplicated_genotype.add_gene(gene)
            #     duplicated_genotype.add_gene_location('')
            #     @genotypes.append(duplicated_genotype)
            #   end
            # end
            # def process_testreport_cdna_variants(testreport, genotypes, genocolorectal)
            #   if testreport.scan(CDNA_REGEX).size == 1
            #     if testreport.scan(COLORECTAL_GENES_REGEX).uniq.size == 1
            #       genocolorectal.add_gene_colorectal(unique_colorectal_genes_from(testreport).join)
            #       genocolorectal.add_gene_location(testreport.scan(CDNA_REGEX).join)
            #       genocolorectal.add_status(2)
            #       if testreport.scan(PROTEIN_REGEX).size.positive?
            #         genocolorectal.add_protein_impact(testreport.scan(PROTEIN_REGEX).join)
            #       end
            #       genotypes.append(genocolorectal)
            #     end
            #   elsif testreport.scan(CDNA_REGEX).size == 2
            #     if testreport.scan(COLORECTAL_GENES_REGEX).uniq.size == 2
            #       genes = colorectal_genes_from(testreport)
            #       cdnas = testreport.scan(CDNA_REGEX).flatten
            #       proteins = testreport.scan(PROTEIN_REGEX).flatten
            #       positive_results = genes.zip(cdnas, proteins)
            #       positive_multiple_cdna_variants(positive_results, genotypes, genocolorectal)
            #     end
            #   end
            # end
            #
            # def process_malformed_variants(testresult, testreport, genelist, genotypes, genocolorectal, record)
            #   if (testresult =~ /FAP/ && testreport.scan(/APC/i).size.positive?) ||
            #      (testresult =~ /High risk haplotype identified in this patient/ && testreport.scan(/APC/i).size.positive?)
            #     if full_screen?(record)
            #       negativegenes = genelist - ['APC']
            #       process_negative_genes(negativegenes, genotypes, genocolorectal)
            #     end
            #     genocolorectal.add_gene_colorectal('APC')
            #     genocolorectal.add_gene_location('')
            #     genocolorectal.add_status(2)
            #     genotypes.append(genocolorectal)
            #   elsif testreport.match(COLORECTAL_GENES_REGEX)
            #     gene = testreport.match(COLORECTAL_GENES_REGEX)[0]
            #     if full_screen?(record)
            #       negativegenes = genelist - [gene]
            #       process_negative_genes(negativegenes, genotypes, genocolorectal)
            #     end
            #     genocolorectal.add_gene_colorectal(gene)
            #     genocolorectal.add_gene_location('')
            #     genocolorectal.add_status(2)
            #     genotypes.append(genocolorectal)
            #   end
            # end
            #

            # def process_chr_variants(record, testresult, testreport, genotypes, genocolorectal)
            #   if full_screen?(record)
            #     if sometimes_tested?(record)
            #       genelist = unique_colorectal_genes_from(testreport)
            #       negativegenes = genelist - unique_colorectal_genes_from(testresult)
            #       process_negative_genes(negativegenes, genotypes, genocolorectal)
            #     else
            #       genelist = COLORECTAL_GENES_MAP[record.raw_fields['indication']]
            #       negativegenes = genelist - unique_colorectal_genes_from(testresult)
            #       process_negative_genes(negativegenes, genotypes, genocolorectal)
            #     end
            #   end
            #   testcolumn = testresult
            #   process_chromosomal_variant(testcolumn, genelist, genotypes, record, genocolorectal)
            # end
            #
            # def process_full_screen(record, testresult, testreport, genotypes, genocolorectal)
            #   if sometimes_tested?(record)
            #     genelist = unique_colorectal_genes_from(testreport)
            #     negativegenes = genelist - unique_colorectal_genes_from(testresult)
            #     process_negative_genes(negativegenes, genotypes, genocolorectal)
            #   else
            #     genelist = COLORECTAL_GENES_MAP[record.raw_fields['indication']]
            #     negativegenes = genelist - unique_colorectal_genes_from(testresult)
            #     process_negative_genes(negativegenes, genotypes, genocolorectal)
            #   end
            # end
            #

            #
            # def sometimes_tested?(record)
            #   record.raw_fields['indication'] == 'HNPCC' ||
            #     record.raw_fields['indication'] == 'COLON' ||
            #     record.raw_fields['indication'] == 'NGS_COLON' ||
            #     record.raw_fields['indication'] == 'POLY'
            # end
            #
            # def process_testresult_multiple_cdnavariant(testresult, testreport, record,
            #                                             genelist, genotypes, genocolorectal)
            #   if testresult.scan(COLORECTAL_GENES_REGEX).uniq.size == 2
            #     if full_screen?(record)
            #       if sometimes_tested?(record)
            #         genelist = unique_colorectal_genes_from(testreport)
            #         negativegenes = genelist - unique_colorectal_genes_from(testresult)
            #         process_negative_genes(negativegenes, genotypes, genocolorectal)
            #       else
            #         negativegenes = genelist - unique_colorectal_genes_from(testresult)
            #         process_negative_genes(negativegenes, genotypes, genocolorectal)
            #       end
            #     end
            #     genes = colorectal_genes_from(testresult)
            #     cdnas = testresult.scan(CDNA_REGEX).flatten
            #     proteins = testresult.scan(PROTEIN_REGEX).flatten
            #     positive_results = genes.zip(cdnas, proteins)
            #     positive_multiple_cdna_variants(positive_results, genotypes, genocolorectal)
            #   elsif unique_colorectal_genes_from(testresult).one?
            #     if full_screen?(record)
            #       if sometimes_tested?(record)
            #         genelist = unique_colorectal_genes_from(testreport)
            #         negativegenes = genelist - unique_colorectal_genes_from(testresult)
            #         process_negative_genes(negativegenes, genotypes, genocolorectal)
            #       else
            #         negativegenes = genelist - unique_colorectal_genes_from(testresult)
            #         process_negative_genes(negativegenes, genotypes, genocolorectal)
            #       end
            #     end
            #     genes = unique_colorectal_genes_from(testresult) * 2
            #     cdnas = testresult.scan(CDNA_REGEX).flatten
            #     proteins = testresult.scan(PROTEIN_REGEX).flatten
            #     positive_results = genes.zip(cdnas, proteins)
            #     positive_multiple_cdna_variants(positive_results, genotypes, genocolorectal)
            #   end
            # end
            #
          end
        end
      end
    end
  end
end
