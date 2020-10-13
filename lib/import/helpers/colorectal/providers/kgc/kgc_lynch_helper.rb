require_relative 'kgc_constants'
require_relative 'kgc_helper'
module Import
  module Helpers
    module Colorectal
      module Providers
        module Kgc
          # Processing methods for Lynch genes
          module KgcLynchHelper
            include KgcConstants
            include KgcHelper

            def process_lynchgenes(raw_genotype, _clinicomm, genocolorectal, genotypes)
              if raw_genotype.scan(COLORECTAL_GENES_REGEX).size.positive?
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                if raw_genotype.scan(CDNA_REGEX).size.positive? && raw_genotype !~ EXON_REGEX
                  process_cdna_change(raw_genotype, mutatedgene, genocolorectal, genotypes)
                elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                  process_exon(raw_genotype, genocolorectal, genotypes)
                elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                  process_exon_and_cdna_change(raw_genotype, genocolorectal, genotypes)
                else
                  process_method = LYNCHGENE_PROCESS_METHODS[raw_genotype]
                  send(process_method, raw_genotype, genocolorectal, genotypes) if process_method
                end
              elsif /no mutation|No mutation detected/i.match(raw_genotype)
                process_no_lynch_gene_mutation(genotypes, genocolorectal)
              end
            end

            def process_cdna_change(raw_genotype, mutatedgene, genocolorectal, genotypes)
              mutatedcdna    = raw_genotype.scan(CDNA_REGEX).flatten
              mutatedprotein = raw_genotype.scan(PROTEIN_REGEX_COLO).flatten
              mutations      = mutatedgene.zip(mutatedcdna, mutatedprotein)
              @logger.debug 'Found BROAD LYNCH dna mutation in ' \
                            "#{raw_genotype.scan(COLORECTAL_GENES_REGEX)} LYNCH RELATED GENE(s) " \
                            "in position #{raw_genotype.scan(CDNA_REGEX)} " \
                            "with impact #{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
              process_mutated_genes(mutations, genocolorectal, genotypes)
              negativegenes = LYNCHGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
            end

            def process_exon(raw_genotype, genocolorectal, genotypes)
              @logger.debug "Found LYNCH CHROMOSOME #{variant_from(raw_genotype)} "\
                            "in #{coloractal_gene_from(raw_genotype)} LYNCH RELATED GENE at "\
                            "position #{exon_from(raw_genotype)}"
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = LYNCHGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
              result = { gene: coloractal_gene_from(raw_genotype), exon: exon_from(raw_genotype),
                         variant: variant_from(raw_genotype) }
              add_result_to(genocolorectal, genotypes, result)
            end

            def process_exon_and_cdna_change(raw_genotype, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = LYNCHGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
              mutatedexongenotype = genocolorectal.dup_colo
              add_mutated_result_to(mutatedexongenotype, raw_genotype, genotypes)
              result = { gene: raw_genotype.scan(COLORECTAL_GENES_REGEX)[1].join,
                         gene_location: gene_location_from(raw_genotype),
                         protein: protein_impact_from(raw_genotype) }

              add_result_to(genocolorectal, genotypes, result)
            end

            def process_no_lynch_gene_mutation(genotypes, genocolorectal)
              @logger.debug 'Found no mutation in broad lynch genes'
              add_negative_test_for(LYNCHGENES, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
            end

            def lynchgene_msh2_ex1_6(raw_genotype, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = LYNCHGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
              result_details = { gene: 'MSH2', exon: '1-6', variant: 'dup' }
              add_result_to(genocolorectal, genotypes, result_details)
            end

            def lynchgene_msh2_c_1760_2(raw_genotype, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = LYNCHGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
              result_details = { gene: 'MSH2', gene_location: '1760-2_1783del', protein: 'Gly587Aspfs*' }
              add_result_to(genocolorectal, genotypes, result_details)
            end

            def lynchgene_msh2_del_exon11(raw_genotype, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = LYNCHGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
              result_details = { gene: 'MSH2', exon: '11', variant: 'del' }
              add_result_to(genocolorectal, genotypes, result_details)
            end

            def lynchgene_msh2_ex11del(raw_genotype, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = LYNCHGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
              result_details = { gene: 'MSH2', exon: '11', variant: 'del' }
              add_result_to(genocolorectal, genotypes, result_details)
            end

            def lynchgene_msh2_c_532del(raw_genotype, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = LYNCHGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
              add_result_to(genocolorectal, genotypes, gene: 'MLH1', gene_location: '532delG')
            end

            def lynchgene_deletion_epcam(raw_genotype, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = LYNCHGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
              genocolorectal2 = genocolorectal.dup_colo
              epcam_details = { gene: 'EPCAM', exon: '2-9', variant: 'del' }
              add_result_to(genocolorectal2, genotypes, epcam_details)
              msh2_details = { gene: 'MSH2', exon: '1-5', variant: 'del' }
              add_result_to(genocolorectal, genotypes, msh2_details)
            end

            def lynchgene_no_mutation(raw_genotype, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes = LYNCHGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
            end

            def lynchgene_msh2_ex7del(raw_genotype, genocolorectal, genotypes)
              mutatedgene    = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              negativegenes  = LYNCHGENES - mutatedgene
              add_negative_test_for(negativegenes, genotypes, genocolorectal, NEGATIVE_TEST_LOG)
              result_details = { gene: 'MSH2', exon: '7', variant: 'del' }
              add_result_to(genocolorectal, genotypes, result_details)
            end
          end
        end
      end
    end
  end
end
