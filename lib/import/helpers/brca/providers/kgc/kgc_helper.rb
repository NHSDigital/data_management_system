require_relative 'kgc_constants'

module Import
  module Helpers
    module Brca
      module Providers
        module Kgc
          # Processing methods used in all results/genes
          module KgcHelper
            include KgcConstants

            def process_mutated_genes(mutations, genotype, genotypes)
              mutations.each do |gene, cdna, protein|
                mutatedgenotype = genotype.dup
                @logger.debug 'SUCCESSFUL gene parse for positive test for: '\
                              "#{gene}, #{cdna}, #{protein}"
                result_details = { gene: gene, gene_location: cdna, protein: protein }
                add_result_to(mutatedgenotype, genotypes, result_details)
              end
            end

            def add_result_to(genotype, genotypes, result_details)
              attributes = %i[exon gene gene_location protein variant]
              exon, gene, gene_location, protein, variant = result_details.values_at(*attributes)

              genotype.add_gene(gene) if gene
              genotype.add_gene_location(gene_location) if gene_location
              genotype.add_exon_location(exon)          if exon
              genotype.add_variant_type(variant)        if variant
              genotype.add_protein_impact(protein)      if protein
              genotypes.append(genotype)
            end

            def add_mutated_result_to(mutatedexongenotype, raw_genotype, genotypes)
              mutated_result = { gene: raw_genotype.scan(BRCA_GENES_REGEX)[0].join,
                                 exon: exon_from(raw_genotype),
                                 variant: variant_from(raw_genotype) }

              add_result_to(mutatedexongenotype, genotypes, mutated_result)
            end

            def add_negative_test_for(negativegenes, genotypes, genotype, log_message)
              negativegenes.each do |negativegene|
                dup_genotype = genotype.dup
                @logger.debug "#{log_message}: #{negativegene}"
                dup_genotype.add_status(1)
                dup_genotype.add_gene(negativegene)
                dup_genotype.add_protein_impact(nil)
                dup_genotype.add_gene_location(nil)
                genotypes.append(dup_genotype)
              end
            end

            def process_negative_genes(negativegenes, genotypes, genotype, logging)
              return unless negativegenes.any?

              @logger.debug "#{logging}: #{negativegenes.flatten}"
              add_negative_test_for(negativegenes, genotypes, genotype,
                                    logging)
            end

            def variant_from(raw_genotype)
              EXON_REGEX.match(raw_genotype)[:deldupins]
            end

            def exon_from(raw_genotype)
              EXON_REGEX.match(raw_genotype)[:exno]
            end

            def brca_gene_from(raw_genotype)
              BRCA_GENES_REGEX.match(raw_genotype)[:brca]
            end

            def gene_location_from(raw_genotype)
              CDNA_REGEX.match(raw_genotype)[:dna]
            end

            def protein_impact_from(raw_genotype)
              PROTEIN_REGEX.match(raw_genotype)[:impact]
            end

            # def tp53_genes_from(clinicomm)
            #   tp53genes = []
            #   clinicomm.scan(BRCA_TP53).each do |gene|
            #     tp53genes.append(TP53_GENES[gene])
            #   end
            #   binding.pry
            #   tp53genes
            # end
          end
        end
      end
    end
  end
end
