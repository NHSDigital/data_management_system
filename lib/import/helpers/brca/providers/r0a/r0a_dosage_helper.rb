module Import
  module Helpers
    module Brca
      module Providers
        module R0a
          # Helper methods for R0A germline extractor
          module R0aDosageHelper
            include Import::Helpers::Brca::Providers::R0a::R0aConstants

            def dosage_test?
              @dosage_record_map[:moleculartestingtype].uniq.join.scan(/dosage/i).size.positive?
            end

            def process_dosage_test_exons(genes)
              @dosage_record_map[:exon].map do |exons|
                if exons.scan(BRCA_GENES_REGEX).count.positive?
                  exons.scan(BRCA_GENES_REGEX).flatten.each { |gene| genes.append(gene) }
                else
                  genes.append('No Gene')
                end
              end
            end

            def tests_from_dosage_record(genes)
              return if genes.nil?

              genes.zip(@dosage_record_map[:genotype],
                        @dosage_record_map[:genotype2]).uniq
            end

            def process_grouped_dosage_tests(grouped_tests, genotype, genotypes)
              if (@non_dosage_record_map[:moleculartestingtype].uniq & DO_NOT_IMPORT).empty?
                grouped_tests.compact.select do |gene, genetic_info|
                  process_dosage_gene(gene, genetic_info, genotype, genotypes)
                end
              else
                @logger.debug('Nothing to do')
              end
            end

            def process_dosage_gene(gene, genetic_info, genotype, genotypes)
              if !brca_gene_match?(genetic_info)
                non_brca_gene_record(gene, genetic_info, genotype, genotypes)
              elsif brca_gene_match?(genetic_info) && !exon_match?(genetic_info)
                brca_gene_record_noexon(genetic_info, gene, genotype, genotypes)
              elsif brca_gene_match?(genetic_info) && exon_match?(genetic_info)
                brca_gene_record_withexon(genetic_info, gene, genotype, genotypes)
              end
            end

            def non_brca_gene_record(gene, genetic_info, genotype, genotypes)
              if gene == 'No Gene'
                @logger.debug("Nothing to do for #{gene} and #{genetic_info}")
              elsif negative_test?(genetic_info) || no_evidence_of_mutation?(genetic_info)
                process_non_cdna_normal(gene, genetic_info, genotype, genotypes)
              elsif cdna_match?(genetic_info)
                process_non_dosage_cdna(gene, genetic_info, genotype, genotypes)
                @logger.debug("IDENTIFIED #{gene}," \
                              "#{cdna_from(genetic_info)} from #{genetic_info}")
              elsif genetic_info.join(',').match(EXON_LOCATION_REGEX) && exon_match?(genetic_info)
                process_brca_gene_and_exon_match(genotype, gene, genetic_info, genotypes)
              elsif !genetic_info.join(',').match(EXON_LOCATION_REGEX) && exon_match?(genetic_info)
                negative_test_exon_variant(gene, genetic_info, genotype, genotypes)
              elsif genetic_info.join(',').empty?
                @logger.debug("IDENTIFIED FALSE POSITIVE #{gene} #{genetic_info}, skipping entry")
              end
            end

            def negative_test_exon_variant(gene, genetic_info, genotype, genotypes)
              case genetic_info.join(',')
              when /normal/i, /evidence/i
                process_non_cdna_normal(gene, genetic_info, genotype, genotypes)
              when /control/i
                @logger.debug("IDENTIFIED FALSE POSITIVE #{gene}"\
                              " #{genetic_info}, skipping entry")
              end
              genotypes
            end

            def brca_gene_record_noexon(genetic_info, gene, genotype, genotypes)
              if genetic_info.join(',').match(BRCA_GENES_REGEX)[:brca] == gene
                genotype_dup = genotype.dup
                add_gene_and_status_to(genotype_dup, gene, 1, genotypes)
              else
                @logger.debug("IDENTIFIED FALSE POSITIVE #{gene} #{genetic_info}, skipping entry")
              end
            end

            def brca_gene_record_withexon(genetic_info, gene, genotype, genotypes)
              if genetic_info.join(',').match(BRCA_GENES_REGEX)[:brca] == gene
                process_brca_gene_and_exon_match(genotype, gene, genetic_info, genotypes)
              else
                @logger.debug("IDENTIFIED FALSE POSITIVE #{gene} #{genetic_info}, skipping entry")
              end
            end

            def negative_test?(genetic_info)
              !cdna_match?(genetic_info) && !exon_match?(genetic_info) && normal?(genetic_info)
            end

            def no_evidence_of_mutation?(genetic_info)
              genetic_info.join(',').scan(/evidence/i).size.positive?
            end
          end
        end
      end
    end
  end
end
