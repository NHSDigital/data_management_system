require_relative 'kgc_constants'
require_relative 'kgc_helper'

module Import
  module Helpers
    module Colorectal
      module Providers
        module Kgc
          # Processing methods for Union lynch genes
          module KgcUnionLynchGeneHelper
            include KgcConstants
            include KgcHelper

            def process_union_lynchgenes(raw_genotype, clinicomm, genocolorectal, genotypes)
              @logger.debug 'Found NON_LYNCH and LYNCH test'
              if raw_genotype.scan(COLORECTAL_GENES_REGEX).size.positive?
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                if raw_genotype.scan(CDNA_REGEX).count.positive? && raw_genotype !~ EXON_REGEX
                  process_union_lynch_cdna_change(raw_genotype, mutatedgene, clinicomm,
                                                  genocolorectal, genotypes)
                elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                  process_union_lynch_exon(raw_genotype, clinicomm, genocolorectal, genotypes)
                elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                  process_union_lynch_exon_and_cdna_change(raw_genotype, clinicomm, genocolorectal,
                                                           genotypes)
                else
                  process_method = UNION_LYNCHGENE_PROCESS_METHODS[raw_genotype]
                  if process_method
                    send(process_method, raw_genotype, clinicomm, genocolorectal, genotypes)
                  end
                end
              elsif /no mutation|No mutation detected/i.match(raw_genotype)
                nonlynchgenes = non_lynch_genes_from(clinicomm)
                uniongenes    = lynchgenes + nonlynchgenes
                @logger.debug "Found no mutation; Genes #{uniongenes.flatten.uniq} are normal"
                add_negative_test_for(uniongenes.flatten.uniq, genotypes, genocolorectal,
                                      NEGATIVE_NON_LYNCH_TEST_LOG)
              end
            end

            def lynchgenes
              %w[MLH1 MSH2 MSH6 EPCAM]
            end

            def process_union_lynch_cdna_change(raw_genotype, mutatedgene, clinicomm,
                                                genocolorectal, genotypes)
              mutatedcdna    = raw_genotype.scan(CDNA_REGEX).flatten
              mutatedprotein = raw_genotype.scan(PROTEIN_REGEX_COLO).flatten
              mutations      = mutatedgene.zip(mutatedcdna, mutatedprotein)
              @logger.debug 'Found BROAD LYNCH dna mutation in ' \
                            "#{raw_genotype.scan(COLORECTAL_GENES_REGEX)} LYNCH and " \
                            'NON-LYNCH RELATED GENE(s) in '\
                            "position #{raw_genotype.scan(CDNA_REGEX)} " \
                            "with impact #{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
              process_mutated_genes(mutations, genocolorectal, genotypes)
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              uniongenes    = lynchgenes + nonlynchgenes.flatten
              negativegenes = uniongenes.uniq - mutatedgene
              # TODO: Unsure why this doesn't work
              # process_negative_genes(negativegenes.flatten.uniq, genotypes, genocolorectal,
              #                        NEGATIVE_LYNCH_AND_NON_LYNCH_TEST_LOG)
              return unless negativegenes.any?

              @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test in LYNCH AND NON-LYNCH' \
              " for: #{negativegenes.flatten.uniq}"
              negativegenes.flatten.uniq.each do |genes|
                genocolorectal1 = genocolorectal.dup_colo
                @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test in LYNCH' \
                "AND NON-LYNCH for: #{genes}"
                genocolorectal1.add_status(1)
                genocolorectal1.add_gene_colorectal(genes)
                genocolorectal1.add_protein_impact(nil)
                genocolorectal1.add_gene_location(nil)
                genotypes.append(genocolorectal1)
              end
            end

            def process_union_lynch_exon(raw_genotype, clinicomm, genocolorectal, genotypes)
              @logger.debug 'Found LYNCH CHROMOSOME' \
                            "#{EXON_REGEX.match(raw_genotype)[:deldupins]} "\
                            "in #{COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal]} " \
                            'LYNCH and NON-LYNCH RELATED GENE(s) at '\
                            "position #{EXON_REGEX.match(raw_genotype)[:exno]}"
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              uniongenes    = lynchgenes + nonlynchgenes.flatten
              negativegenes = uniongenes.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)
              result = { gene: coloractal_gene_from(raw_genotype), exon: exon_from(raw_genotype),
                         variant: variant_from(raw_genotype) }
              add_result_to(genocolorectal, genotypes, result)
            end

            def process_union_lynch_exon_and_cdna_change(raw_genotype, clinicomm, genocolorectal,
                                                         genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              uniongenes    = lynchgenes + nonlynchgenes.flatten
              negativegenes = uniongenes.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)
              mutatedexongenotype = genocolorectal.dup_colo
              add_mutated_result_to(mutatedexongenotype, raw_genotype, genotypes)
              result = { gene: raw_genotype.scan(COLORECTAL_GENES_REGEX)[1].join,
                         gene_location: gene_location_from(raw_genotype),
                         protein: protein_impact_from(raw_genotype) }
              add_result_to(genocolorectal, genotypes, result)
            end

            def union_lynchgene_bmpr1a(raw_genotype, clinicomm, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              uniongenes    = lynchgenes + nonlynchgenes.flatten
              negativegenes = uniongenes.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)

              result = { gene: 'BMPR1A', gene_location: '972dupT' }
              add_result_to(genocolorectal, genotypes, result)
            end

            def union_lynchgene_apc(raw_genotype, clinicomm, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              uniongenes    = lynchgenes + nonlynchgenes.flatten
              negativegenes = uniongenes.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)
              result = { gene: 'APC', gene_location: '1880dupA' }
              add_result_to(genocolorectal, genotypes, result)
            end

            def union_lynchgene_msh6(raw_genotype, clinicomm, genocolorectal, genotypes)
              mutatedgene   = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              nonlynchgenes = non_lynch_genes_from(clinicomm)
              uniongenes    = lynchgenes + nonlynchgenes.flatten
              negativegenes = uniongenes.uniq - mutatedgene
              process_negative_genes(negativegenes, genotypes, genocolorectal,
                                     NEGATIVE_NON_LYNCH_TEST_LOG)

              result = { gene: 'MSH6', gene_location: '*24_28del' }
              add_result_to(genocolorectal, genotypes, result)
            end
          end
        end
      end
    end
  end
end
