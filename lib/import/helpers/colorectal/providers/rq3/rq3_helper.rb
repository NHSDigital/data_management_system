module Import
  module Helpers
    module Colorectal
      module Providers
        module Rq3
          # Processing methods used by BirminghamHandlerColorectal
          module Rq3Helper
            include Import::Helpers::Colorectal::Providers::Rq3::Rq3Constants

            def process_negative_genes(negativegenes, genotypes, genocolorectal, record)
              negativegenes.each do |negativegene|
                dup_genocolorectal = genocolorectal.dup_colo
                @logger.debug "Found #{negativegene} for list #{negativegenes}"
                dup_genocolorectal.add_status(1)
                dup_genocolorectal.add_gene_colorectal(negativegene)
                dup_genocolorectal.add_protein_impact(nil)
                dup_genocolorectal.add_gene_location(nil)
                genotypes.append(dup_genocolorectal)
              end
            end

            def positive_multiple_chromosomal_variants(positive_results, genotypes, genocolorectal)
              positive_results.each do |gene,chromosomalvariant|
                abnormal_genocolorectal = genocolorectal.dup_colo
                abnormal_genocolorectal.add_gene_colorectal(gene)
                abnormal_genocolorectal.add_variant_type(chromosomalvariant)
                genotypes.append(abnormal_genocolorectal)
              end
            
            end

            def positive_multiple_cdna_variants(positive_results, genotypes, genocolorectal)
              positive_results.each do |gene,cdna,protein|
                abnormal_genocolorectal = genocolorectal.dup_colo
                abnormal_genocolorectal.add_gene_colorectal(gene)
                abnormal_genocolorectal.add_gene_location(cdna)
                abnormal_genocolorectal.add_protein_impact(protein)
                abnormal_genocolorectal.add_status(2)
                genotypes.append(abnormal_genocolorectal)
              end
            end

            def process_mutyh_single_cdna_variants(genocolorectal, record, testresult, genotypes)
              genocolorectal.add_gene_colorectal('MUTYH')
              genocolorectal.add_gene_location(testresult.scan(CDNA_REGEX).join())
              genocolorectal.add_status(2)
              if testresult.scan(PROTEIN_REGEX).size > 0
                genocolorectal.add_protein_impact(testresult.scan(PROTEIN_REGEX).join())
              end
              genotypes.append(genocolorectal)
            end

            def process_mutyh_specific_variants(testresult, genelist, genotypes, genocolorectal, record)
              if testresult.scan(CDNA_REGEX).size > 0
                if testresult.scan(CDNA_REGEX).size == 1
                  negativegenes = genelist - ['MUTYH']
                  process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                  process_mutyh_single_cdna_variants(genocolorectal, record, testresult, genotypes)
                elsif testresult.scan(CDNA_REGEX).size == 2
                  negativegenes = genelist - ['MUTYH']
                  process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                  genes = ['MUTYH'] * testresult.scan(CDNA_REGEX).size
                  cdnas = testresult.scan(CDNA_REGEX).flatten
                  proteins = testresult.scan(PROTEIN_REGEX).flatten
                  positive_results = genes.zip(cdnas,proteins)
                  positive_multiple_cdna_variants(positive_results, genotypes, genocolorectal)
                end
                genotypes
              else
                negativegenes = genelist - ['MUTYH']
                process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                genocolorectal.add_gene_colorectal('MUTYH')
                genocolorectal.add_gene_location('')
                genocolorectal.add_status(2)
                genotypes.append(genocolorectal)
              end
              genotypes
            end

            def process_testreport_cdna_variants(testreport, genelist, genotypes, genocolorectal, record)
              if testreport.scan(CDNA_REGEX).size == 1
                if testreport.scan(COLORECTAL_GENES_REGEX).uniq.size == 1
                  negativegenes = genelist - testreport.scan(COLORECTAL_GENES_REGEX).flatten
                  process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                  genocolorectal.add_gene_colorectal(testreport.scan(COLORECTAL_GENES_REGEX).join())
                  genocolorectal.add_gene_location(testreport.scan(CDNA_REGEX).join())
                  genocolorectal.add_status(2)
                  if testreport.scan(PROTEIN_REGEX).size > 0
                    genocolorectal.add_protein_impact(testreport.scan(PROTEIN_REGEX).join())
                  end
                  genotypes.append(genocolorectal)
                end
                genotypes
              elsif testreport.scan(CDNA_REGEX).size == 2
                if testreport.scan(COLORECTAL_GENES_REGEX).uniq.size == 2
                  negativegenes = genelist - testreport.scan(COLORECTAL_GENES_REGEX).flatten
                  process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                  genes = testreport.scan(COLORECTAL_GENES_REGEX).flatten
                  cdnas = testreport.scan(CDNA_REGEX).flatten
                  proteins = testreport.scan(PROTEIN_REGEX).flatten
                  positive_results = genes.zip(cdnas,proteins)
                  positive_multiple_cdna_variants(positive_results, genotypes, genocolorectal)
                end
                genotypes
              end
            end

            def process_testreport_chromosome_variants(testreport, genelist, genotypes, genocolorectal, record)
              if testreport.scan(COLORECTAL_GENES_REGEX).uniq.size == 1 
                negativegenes = genelist - testreport.scan(COLORECTAL_GENES_REGEX).flatten
                process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                genocolorectal.add_gene_colorectal(testreport.scan(COLORECTAL_GENES_REGEX).join())
                genocolorectal.add_variant_type(testreport.scan(CHR_VARIANTS_REGEX).join())
                genocolorectal.add_status(2)
                genotypes.append(genocolorectal)
              end
            end

            def process_malformed_variants(testresult, testreport, genelist, genotypes, genocolorectal, record)
              if (testresult =~ /FAP/ && testreport.scan(/APC/).size > 0) ||
                (testresult =~ /High risk haplotype identified in this patient/ && testreport.scan(/APC/).size > 0)
                negativegenes = genelist - ['APC']
                process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                genocolorectal.add_gene_colorectal('APC')
                genocolorectal.add_gene_location('.')
                genocolorectal.add_status(2)
                genotypes.append(genocolorectal)
              elsif testreport.match(COLORECTAL_GENES_REGEX)
                gene = testreport.match(COLORECTAL_GENES_REGEX)[0]
                negativegenes = genelist - [gene]
                process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                genocolorectal.add_gene_colorectal(gene)
                genocolorectal.add_gene_location('.')
                genocolorectal.add_status(2)
                genotypes.append(genocolorectal)
              end
            end

            def process_testresult_cdna_variants(testresult, genelist, genotypes, record, genocolorectal)
              if testresult.scan(CDNA_REGEX).size == 1
                if testresult.scan(COLORECTAL_GENES_REGEX).uniq.size == 1
                  negativegenes = genelist - testresult.scan(COLORECTAL_GENES_REGEX).flatten
                  process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                  genocolorectal.add_gene_colorectal(testresult.scan(COLORECTAL_GENES_REGEX).join())
                  genocolorectal.add_gene_location(testresult.scan(CDNA_REGEX).join())
                  genocolorectal.add_status(2)
                  if testresult.scan(PROTEIN_REGEX).size > 0
                    genocolorectal.add_protein_impact(testresult.scan(PROTEIN_REGEX).join())
                  end
                  genotypes.append(genocolorectal)
                else
                  negativegenes = genelist - [testresult.scan(COLORECTAL_GENES_REGEX).flatten.uniq[0]]
                  process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                  genocolorectal.add_gene_colorectal(testresult.scan(COLORECTAL_GENES_REGEX).flatten.uniq[0])
                  genocolorectal.add_gene_location(testresult.scan(CDNA_REGEX).join())
                  genocolorectal.add_status(2)
                  if testresult.scan(PROTEIN_REGEX).size > 0
                    genocolorectal.add_protein_impact(testresult.scan(PROTEIN_REGEX).join())
                  end
                  genotypes.append(genocolorectal)
                end
                genotypes
              elsif testresult.scan(CDNA_REGEX).size == 2
                if testresult.scan(COLORECTAL_GENES_REGEX).uniq.size == 2
                  negativegenes = genelist - testresult.scan(COLORECTAL_GENES_REGEX).flatten
                  process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                  genes = testresult.scan(COLORECTAL_GENES_REGEX).flatten
                  cdnas = testresult.scan(CDNA_REGEX).flatten
                  proteins = testresult.scan(PROTEIN_REGEX).flatten
                  positive_results = genes.zip(cdnas,proteins)
                  positive_multiple_cdna_variants(positive_results, genotypes, genocolorectal)
                elsif testresult.scan(COLORECTAL_GENES_REGEX).uniq.size == 1
                    negativegenes = genelist - testresult.scan(COLORECTAL_GENES_REGEX).flatten
                    process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                    genes = testresult.scan(COLORECTAL_GENES_REGEX).flatten * 2
                    cdnas = testresult.scan(CDNA_REGEX).flatten
                    proteins = testresult.scan(PROTEIN_REGEX).flatten
                    positive_results = genes.zip(cdnas,proteins)
                    positive_multiple_cdna_variants(positive_results, genotypes, genocolorectal)
                end
                genotypes
              end
            end

            def process_testresult_chromosomal_variants(testresult, genelist, genotypes, record, genocolorectal)
              if testresult.scan(CHR_VARIANTS_REGEX).size == 1
                if testresult.scan(COLORECTAL_GENES_REGEX).uniq.size == 1 
                  negativegenes = genelist - testresult.scan(COLORECTAL_GENES_REGEX).flatten
                  process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                  genocolorectal.add_gene_colorectal(testresult.scan(COLORECTAL_GENES_REGEX).join())
                  genocolorectal.add_variant_type(testresult.scan(CHR_VARIANTS_REGEX).join())
                  genocolorectal.add_status(2)
                  genotypes.append(genocolorectal)
                else 
                  genes = testresult.scan(COLORECTAL_GENES_REGEX).flatten
                  chromosomalvariants = testresult.scan(CHR_VARIANTS_REGEX).flatten * genes.size
                  positive_results = genes.zip(chromosomalvariants)
                  positive_multiple_chromosomal_variants(positive_results, genotypes, genocolorectal)
                end
              elsif testresult.scan(COLORECTAL_GENES_REGEX).uniq.size == 1 
                negativegenes = genelist - testresult.scan(COLORECTAL_GENES_REGEX).flatten
                process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                genocolorectal.add_gene_colorectal(testresult.scan(COLORECTAL_GENES_REGEX).join())
                genocolorectal.add_variant_type(testresult.scan(CHR_VARIANTS_REGEX)[1])
                genocolorectal.add_status(2)
                genotypes.append(genocolorectal)
              else
                negativegenes = genelist - testresult.scan(COLORECTAL_GENES_REGEX).flatten
                process_negative_genes(negativegenes, genotypes, genocolorectal, record)
                genes = testresult.scan(COLORECTAL_GENES_REGEX).flatten
                chromosomalvariants = testresult.scan(CHR_VARIANTS_REGEX).flatten
                positive_results = genes.zip(chromosomalvariants)
                positive_multiple_chromosomal_variants(positive_results, genotypes, genocolorectal)
              end
            end

          end
        end
      end
    end
  end
end
