require_relative 'kgc_constants'
require_relative 'kgc_helper'

module Import
  module Helpers
    module Brca
      module Providers
        module Kgc
          # Processing methods for Non lynch genes
          module KgcTp53GenesHelper
            include KgcConstants
            include KgcHelper

            def process_tp53_entries(raw_genotype, clinicomm, genotype, genotypes)
              if raw_genotype == 'No mutation detected'
                add_negative_test_for(%w[BRCA1 BRCA2 TP53], genotypes, genotype,
                                      NEGATIVE_TEST_LOG)
              elsif raw_genotype.scan(BRCA_GENES_REGEX).count.positive?
                mutatedgene = raw_genotype.scan(BRCA_GENES_REGEX).flatten

                process_tp53_genes(raw_genotype, clinicomm, genotype, genotypes,
                                   mutatedgene)
              elsif /no mutation|No mutation detected|Normal result/i.match(raw_genotype)
                tp53genes = TP53_GENES
                @logger.debug 'Found no mutation'
                add_negative_test_for(tp53genes.flatten.uniq, genotypes, genotype,
                                      NEGATIVE_TEST_LOG)
              end
            end

            def process_tp53_genes(raw_genotype, clinicomm, genotype, genotypes,
                                   mutatedgene)
              if raw_genotype.scan(CDNA_REGEX).count.positive? && raw_genotype !~ EXON_REGEX
                process_tp53_cdna_change(raw_genotype, mutatedgene, clinicomm,
                                         genotype, genotypes)
              elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                process_tp53_exon(raw_genotype, clinicomm, genotype, genotypes)
              elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                process_tp53_exon_and_cdna_change(raw_genotype, clinicomm, genotype,
                                                  genotypes)
              end
            end

            def process_tp53_cdna_change(raw_genotype, mutatedgene, _clinicomm, genotype,
                                         genotypes)
              mutatedcdna    = raw_genotype.scan(CDNA_REGEX).flatten
              mutatedprotein = raw_genotype.scan(PROTEIN_REGEX).flatten
              if raw_genotype.scan(CDNA_REGEX).count > 1 && mutatedgene.flatten.one?
                mutatedgene = mutatedgene.map { |gene| [gene] * 2 }
              end
              mutations = mutatedgene.flatten.zip(mutatedcdna, mutatedprotein)
              @logger.debug "Found dna mutation in #{mutatedgene} " \
                            "GENE(s) in position #{raw_genotype.scan(CDNA_REGEX)} with impact " \
                            "#{raw_genotype.scan(PROTEIN_REGEX)}"
              process_mutated_genes(mutations, genotype, genotypes)
              negativegenes = TP53_GENES - mutatedgene
              process_negative_genes(negativegenes, genotypes, genotype,
                                     NEGATIVE_TEST_LOG)
            end

            def process_tp53_exon(raw_genotype, _clinicomm, genotype, genotypes)
              @logger.debug 'Found CHROMOSOME VARIANT ' \
                            "#{EXON_REGEX.match(raw_genotype)[:deldupins]} "\
                            "in #{BRCA_GENES_REGEX.match(raw_genotype)[:brca]} " \
                            'GENE at '\
                            "position #{EXON_REGEX.match(raw_genotype)[:exno]}"
              mutatedgene = raw_genotype.scan(BRCA_GENES_REGEX).flatten
              negativegenes = TP53_GENES - mutatedgene
              process_negative_genes(negativegenes, genotypes, genotype,
                                     NEGATIVE_TEST_LOG)
              result = { gene: brca_gene_from(raw_genotype), exon: exon_from(raw_genotype),
                         variant: variant_from(raw_genotype) }
              add_result_to(genotype, genotypes, result)
            end

            def process_tp53_exon_and_cdna_change(raw_genotype, _clinicomm, genotype,
                                                  genotypes)
              mutatedgene = raw_genotype.scan(BRCA_GENES_REGEX).flatten
              # tp53genes = tp53_genes_from(clinicomm)
              negativegenes = TP53_GENES - mutatedgene
              process_negative_genes(negativegenes, genotypes, genotype,
                                     NEGATIVE_TEST_LOG)
              mutatedexongenotype = genotype.dup
              add_mutated_result_to(mutatedexongenotype, raw_genotype, genotypes)

              result = { gene: raw_genotype.scan(BRCA_GENES_REGEX)[1].join,
                         gene_location: gene_location_from(raw_genotype),
                         protein: protein_impact_from(raw_genotype) }
              add_result_to(genotype, genotypes, result)
            end
          end
        end
      end
    end
  end
end
