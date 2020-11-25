require_relative 'kgc_constants'
require_relative 'kgc_helper'

module Import
  module Helpers
    module Colorectal
      module Providers
        module Kgc
          # Processing methods for Non lynch genes
          module KgcNonLynchGeneHelper
            include KgcConstants
            include KgcHelper

            def process_non_lynch_genes(raw_genotype, clinicomm, genocolorectal, genotypes)
              if raw_genotype == 'No mutation detected' &&
                 clinicomm == 'Familial Adenomatous Polyposis;MUTYH-associated Polyposis;' \
                              'Trusight Cancer panel;pole/pold1 testing'
                add_negative_test_for(%w[APC MUTYH POLD1 POLE], genotypes, genocolorectal,
                                      NEGATIVE_NON_LYNCH_TEST_LOG)
              elsif raw_genotype == 'No mutation detected' &&
                    clinicomm == 'Trusight Cancer panel; familial adenomatous polyposis; MAP'
                add_negative_test_for(%w[APC MUTYH], genotypes, genocolorectal,
                                      NEGATIVE_NON_LYNCH_TEST_LOG)
              elsif raw_genotype.scan(COLORECTAL_GENES_REGEX).count.positive?
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                process_non_lynch_colo_genes(raw_genotype, clinicomm, genocolorectal, genotypes,
                                             mutatedgene)
              elsif /no mutation|No mutation detected|Normal result/i.match(raw_genotype)
                nonlynchgenes = non_lynch_genes_from(clinicomm)
                @logger.debug "Found no mutation; Genes #{nonlynchgenes.flatten.uniq} are normal"
                add_negative_test_for(nonlynchgenes.flatten.uniq, genotypes, genocolorectal,
                                      NEGATIVE_NON_LYNCH_TEST_LOG)
              end
            end

            def process_non_lynch_colo_genes(raw_genotype, clinicomm, genocolorectal, genotypes,
                                             mutatedgene)
              if raw_genotype.scan(CDNA_REGEX).count.positive? && raw_genotype !~ EXON_REGEX
                process_non_lynch_cdna_change(raw_genotype, mutatedgene, clinicomm,
                                                       genocolorectal, genotypes)
              elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                process_non_lynch_exon(raw_genotype, clinicomm, genocolorectal, genotypes)
              elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                process_non_lynch_exon_and_cdna_change(raw_genotype, clinicomm, genocolorectal,
                                                       genotypes)
              else
                process_method = NON_LYNCHGENE_PROCESS_METHODS[raw_genotype]
                if process_method
                  send(process_method, raw_genotype, clinicomm, genocolorectal, genotypes)
                end
              end
            end

            def process_non_lynch_cdna_change(raw_genotype, mutatedgene, clinicomm, genocolorectal,
                                              genotypes)
              mutatedcdna    = raw_genotype.scan(CDNA_REGEX).flatten
              mutatedprotein = raw_genotype.scan(PROTEIN_REGEX_COLO).flatten
              if raw_genotype.scan(CDNA_REGEX).count > 1 && mutatedgene.flatten.one?
                mutatedgene = mutatedgene.map { |mutatedgene| [mutatedgene] * 2 }
              end
              mutations      = mutatedgene.flatten.zip(mutatedcdna, mutatedprotein)
              @logger.debug "Found NON-LYNCH dna mutation in #{mutatedgene} LYNCH RELATED " \
                            "GENE(s) in position #{raw_genotype.scan(CDNA_REGEX)} with impact " \
                            "#{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
              process_mutated_genes(mutations, genocolorectal, genotypes)
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              negativegenes = nonlynchgenes.flatten.uniq - mutatedgene.flatten
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)
            end

            def process_non_lynch_exon(raw_genotype, clinicomm, genocolorectal, genotypes)
              @logger.debug 'Found NON-LYNCH CHROMOSOME ' \
                            "#{EXON_REGEX.match(raw_genotype)[:deldupins]} "\
                            "in #{COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal]} " \
                            'NON-LYNCH GENE at '\
                            "position #{EXON_REGEX.match(raw_genotype)[:exno]}"
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)
              result = { gene: coloractal_gene_from(raw_genotype), exon: exon_from(raw_genotype),
                         variant: variant_from(raw_genotype) }
              add_result_to(genocolorectal, genotypes, result)
            end

            def process_non_lynch_exon_and_cdna_change(raw_genotype, clinicomm, genocolorectal,
                                                       genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)
              mutatedexongenotype = genocolorectal.dup_colo
              add_mutated_result_to(mutatedexongenotype, raw_genotype, genotypes)

              result = { gene: raw_genotype.scan(COLORECTAL_GENES_REGEX)[1].join,
                         gene_location: gene_location_from(raw_genotype),
                         protein: protein_impact_from(raw_genotype) }
              add_result_to(genocolorectal, genotypes, result)
            end

            def non_lynchgene_apc_promoter_1b(raw_genotype, clinicomm, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)
              result = { gene: coloractal_gene_from(raw_genotype), variant: 'del' }
              add_result_to(genocolorectal, genotypes, result)
            end

            def non_lynchgene_apc_c423_34_423(raw_genotype, clinicomm, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)
              result = { gene: coloractal_gene_from(raw_genotype),
                         gene_location: '423-34_423-17delinsA' }
              add_result_to(genocolorectal, genotypes, result)
            end

            def non_lynchgene_apc_ex10_18del(raw_genotype, clinicomm, genocolorectal, genotypes)
              mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)
              result = { gene: coloractal_gene_from(raw_genotype), exon: '10-18', variant: 'del' }
              add_result_to(genocolorectal, genotypes, result)
            end

            def non_lynchgene_mutyh_p_glu480(raw_genotype, clinicomm, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)
              result = { gene: coloractal_gene_from(raw_genotype), protein: 'Glu480*' }
              add_result_to(genocolorectal, genotypes, result)
            end

            def non_lynchgene_stk11_ex1_10del(raw_genotype, clinicomm, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)
              result = { gene: coloractal_gene_from(raw_genotype), exon: '1-10', variant: 'del' }
              add_result_to(genocolorectal, genotypes, result)
            end
          end
        end
      end
    end
  end
end
