module Import
  module Helpers
    module Brca
      module Providers
        module R0a
          # Helper methods for R0A germline extractor
          module R0aNondosageHelper
            include Import::Helpers::Brca::Providers::R0a::R0aConstants

            def non_dosage_test?
              @non_dosage_record_map[:moleculartestingtype].uniq.join.scan(/dosage/i).size.zero?
            end

            def process_grouped_non_dosage_tests(grouped_tests, genotype, genotypes)
              if (@non_dosage_record_map[:moleculartestingtype].uniq & DO_NOT_IMPORT).empty?
                grouped_tests.each do |gene, genetic_info|
                  if gene == 'No Gene'
                    @logger.debug("Nothing to do for #{gene} and #{genetic_info}")
                  elsif cdna_match?(genetic_info)
                    process_non_dosage_cdna(gene, genetic_info, genotype, genotypes)
                  elsif genetic_info.join(',').match(EXON_LOCATION_REGEX) &&
                        exon_match?(genetic_info)
                    process_brca_gene_and_exon_match(genotype, gene, genetic_info, genotypes)
                  elsif !cdna_match?(genetic_info) && !exon_match?(genetic_info) &&
                        normal?(genetic_info)
                    process_non_cdna_normal(gene, genetic_info, genotype, genotypes)
                  elsif !cdna_match?(genetic_info) && !exon_match?(genetic_info) &&
                        !normal?(genetic_info) && fail?(genetic_info)
                    process_non_cdna_fail(gene, genetic_info, genotype, genotypes)
                  end
                end
              else
                @logger.debug('Nothing to do')
              end
            end

            def process_non_dosage_cdna(gene, genetic_info, genotype, genotypes)
              genotype_dup = genotype.dup
              process_non_brca_genes(genotype_dup, gene, genetic_info, genotypes,
                                     genotype)
            end

            def tests_from_non_dosage_record(genes)
              return if genes.nil?

              genes.zip(@non_dosage_record_map[:genotype],
                        @non_dosage_record_map[:genotype2]).uniq
            end

            def process_non_dosage_test_exons(genes)
              @non_dosage_record_map[:exon].each do |exons|
                if exons =~ BRCA_GENES_REGEX
                  genes.append(BRCA_GENES_REGEX.match(exons.upcase)[:brca])
                else
                  genes.append('No Gene')
                end
              end
            end
          end
        end
      end
    end
  end
end
