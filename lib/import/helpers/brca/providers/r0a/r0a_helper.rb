module Import
  module Helpers
    module Brca
      module Providers
        module R0a
          # Helper methods for R0A germline extractor
          module R0aHelper
            include Import::Helpers::Brca::Providers::R0a::R0aConstants
            include Import::Helpers::Brca::Providers::R0a::R0aNondosageHelper
            include Import::Helpers::Brca::Providers::R0a::R0aDosageHelper

            def assign_and_populate_results_for(record)
              genotype = Import::Brca::Core::GenotypeBrca.new(record)
              genotype.add_passthrough_fields(record.mapped_fields,
                                              record.raw_fields,
                                              PASS_THROUGH_FIELDS_COLO)
              add_organisationcode_testresult(genotype)
              add_servicereportidentifier(genotype, record)
              testscope_from_rawfields(genotype, record)
              results = assign_gene_mutation(genotype, record)
              results.each { |result| @persister.integrate_and_store(result) }
            end

            def add_organisationcode_testresult(genotype)
              genotype.attribute_map['organisationcode_testresult'] = '69820'
            end

            def assign_gene_mutation(genotype, _record)
              genotypes = []
              genes     = []
              if non_dosage_test?
                process_non_dosage_test_exons(genes)
                tests = tests_from_non_dosage_record(genes)
                grouped_tests = grouped_tests_from(tests)
                process_grouped_non_dosage_tests(grouped_tests, genotype, genotypes)
              elsif dosage_test?
                process_dosage_test_exons(genes)
                tests = tests_from_dosage_record(genes)
                grouped_tests = grouped_tests_from(tests)
                process_grouped_dosage_tests(grouped_tests, genotype, genotypes)
              end
              genotypes
            end

            def testscope_from_rawfields(genotype, record)
              moltesttypes = []
              genera       = []
              exons        = []
              record.raw_fields.map do |raw_record|
                moltesttypes.append(raw_record['moleculartestingtype'])
                genera.append(raw_record['genus'])
                exons.append(raw_record['exon'])
              end

              add_test_scope_to(genotype, moltesttypes, genera, exons)
            end

            # Switching rubocop off for this method as reduced method length as
            # any further breaking down would be purely arbitrary
            # The order is also important here, so duplciate branches are required
            # rubocop:disable Lint/DuplicateBranch
            # rubocop:disable Metrics/MethodLength
            def add_test_scope_to(genotype, moltesttypes, genera, exons)
              stringed_moltesttypes = moltesttypes.flatten.join(',')
              stringed_exons = exons.flatten.join(',')
              if stringed_moltesttypes =~ /^100,000 GENOMES/i
                genotype.add_test_scope(:full_screen)
              elsif stringed_moltesttypes =~ /predictive|confirm/i
                genotype.add_test_scope(:targeted_mutation)
              elsif stringed_moltesttypes =~ /^Ashkenazi/i
                genotype.add_test_scope(:aj_screen)
              elsif stringed_moltesttypes =~ /^Polish/i
                genotype.add_test_scope(:polish_screen)
              elsif (genera & %w[G F H]).any? ||
                    ngs?(stringed_exons) || screen?(stringed_moltesttypes)
                genotype.add_test_scope(:full_screen)
              elsif mutation_analysis?(stringed_moltesttypes) || non_brca?(stringed_moltesttypes)
                if seven_tests_or_less?(moltesttypes)
                  genotype.add_test_scope(:targeted_mutation)
                elsif twelve_tests_or_more?(moltesttypes)
                  genotype.add_test_scope(:full_screen)
                end
              elsif moltesttypes.include?('BRCA1/BRCA2 GENETIC TESTING REPORT')
                genotype.add_test_scope(:full_screen)
              elsif stringed_moltesttypes =~ /dosage/i
                genotype.add_test_scope(:full_screen)
              end
            end
            # rubocop:enable Lint/DuplicateBranch
            # rubocop:enable Metrics/MethodLength

            def process_non_cdna_normal(gene, genetic_info, genotype, genotypes)
              genotype_dup = genotype.dup
              @logger.debug("IDENTIFIED #{gene}, NORMAL TEST from #{genetic_info}")
              add_gene_and_status_to(genotype_dup, gene, 1, genotypes)
            end

            def process_non_cdna_fail(gene, genetic_info, genotype, genotypes)
              genotype_dup = genotype.dup
              add_gene_and_status_to(genotype_dup, gene, 9, genotypes)
              @logger.debug("Adding #{gene} to FAIL STATUS for #{genetic_info}")
            end

            def process_false_positive(brca_genes, gene, genetic_info)
              @logger.debug("IDENTIFIED FALSE POSITIVE FOR #{gene}, " \
                            "#{brca_genes[:brca]}, #{cdna_from(genetic_info)} " \
                            "from #{genetic_info}")
            end

            def process_brca_genes(brca_genes, genotype_dup, gene, genetic_info,
                                   genotypes)
              if brca_genes[:brca] != gene
                process_false_positive(brca_genes, gene, genetic_info)
                process_non_cdna_normal(gene, genetic_info, genotype_dup, genotypes)
              elsif brca_genes[:brca] == gene
                @logger.debug("IDENTIFIED TRUE POSITIVE FOR #{gene}, " \
                              "#{cdna_from(genetic_info)} from #{genetic_info}")
                genotype_dup.add_gene_location(cdna_from(genetic_info))
                if PROT_REGEX.match(genetic_info.join(','))
                  @logger.debug("IDENTIFIED #{protien_from(genetic_info)} from #{genetic_info}")
                  genotype_dup.add_protein_impact(protien_from(genetic_info))
                end
                add_gene_and_status_to(genotype_dup, gene, 2, genotypes)
                @logger.debug("IDENTIFIED #{gene}, POSITIVE TEST from #{genetic_info}")
              end
            end

            def process_non_brca_genes(genotype_dup, gene, genetic_info, genotypes, genotype)
              @logger.debug("IDENTIFIED #{gene}, #{cdna_from(genetic_info)} from #{genetic_info}")
              mutations = list_mutations(genetic_info)
              if empty_or_badlyformatted_genotype?(genetic_info, gene)
                extract_normal_badlyformatted_genotypes(genotype_dup, gene, genotypes)
              else
                if mutations.size > 1
                  multiple_mutations(mutations, gene, genetic_info, genotype, genotypes)
                elsif mutations.join.split(',').size == 1
                  single_badformat_variant(genotype_dup, genetic_info, gene, genotypes)
                  genotypes
                elsif mutations.join.split(',').size > 1
                  multiple_badformatted_variants(mutations, genotype, gene, genotypes)
                end
                @logger.debug("IDENTIFIED #{gene}, POSITIVE TEST from #{genetic_info}")
              end
            end

            def empty_or_badlyformatted_genotype?(genetic_info, gene)
              !genetic_info.join(',').scan(BRCA_GENES_REGEX).flatten.join.empty? &&
                genetic_info.join(',').scan(BRCA_GENES_REGEX).flatten.join != gene
            end

            def extract_normal_badlyformatted_genotypes(genotype_dup, gene, genotypes)
              genotype_dup.add_gene(gene.upcase)
              genotype_dup.add_status(1)
              genotypes.append(genotype_dup)
            end

            def multiple_mutations(mutations, gene, genetic_info, genotype, genotypes)
              if mutations.size == 2
                mutation_duplicate1, mutation_duplicate2 = *mutations.map(&:upcase)
                if mutation_duplicate1.include?(mutation_duplicate2) ||
                   mutation_duplicate2.include?(mutation_duplicate1)
                  duplicated_variants(genetic_info, genotype, gene, mutations, genotypes)
                else
                  different_mutations(mutations, genotype, gene, genotypes)
                end
                genotypes
              else
                mutations = mutations.split(',').flatten.map { |mutation| mutation.gsub('het', '') }
                different_mutations(mutations.uniq, genotype, gene, genotypes)
              end
            end

            def duplicated_variants(genetic_info, genotype, gene, mutations, genotypes)
              duplicated_geno = genotype.dup
              duplicated_geno.add_gene(gene)
              longest_protein = list_proteins(genetic_info).max_by(&:length)
              if genetic_info.join(',').match(mutations.max_by(&:length))
                duplicated_geno.add_gene_location(CDNA_REGEX.match(genetic_info.join(','))[:cdna])
              else
                duplicated_geno.add_gene_location(mutations.min_by(&:length))
              end
              if !longest_protein.nil? && genetic_info.join(',').match(longest_protein)
                duplicated_geno.add_protein_impact(
                  PROT_REGEX.match(genetic_info.join(','))[:impact]
                )
              end
              duplicated_geno.add_status(2)
              genotypes.append(duplicated_geno)
            end

            def different_mutations(mutations, genotype, gene, genotypes)
              mutations.each do |mutation|
                duplicated_geno = genotype.dup
                duplicated_geno.add_gene(gene)
                duplicated_geno.add_gene_location(mutation)
                duplicated_geno.add_status(2)
                genotypes.append(duplicated_geno)
              end
            end

            def single_badformat_variant(genotype_dup, genetic_info, gene, genotypes)
              genotype_dup.add_gene_location(cdna_from(genetic_info))
              genotype_dup.add_gene(gene.upcase)
              genotype_dup.add_status(2)
              genotypes.append(genotype_dup)
              if PROT_REGEX.match(genetic_info.join(','))
                @logger.debug("IDENTIFIED #{protien_from(genetic_info)} from #{genetic_info}")
                genotype_dup.add_protein_impact(protien_from(genetic_info))
                genotypes.append(genotype_dup)
              end
              genotypes
            end

            def multiple_badformatted_variants(mutations, genotype, gene, genotypes)
              variants = []
              mutations.join.gsub('het', '').split(',') do |mutation|
                if mutation.gsub('het', '').match(CDNA_REGEX)
                  variants.append(mutation.match(CDNA_REGEX)[:cdna])
                end
              end
              variants.uniq.each do |cdna, _protein|
                duplicated_geno = genotype.dup
                duplicated_geno.add_gene(gene)
                duplicated_geno.add_gene_location(cdna)
                duplicated_geno.add_status(2)
                genotypes.append(duplicated_geno)
              end
              genotypes
            end

            def process_brca_gene_and_exon_match(genotype, gene, genetic_info, genotypes)
              genotype_dup = genotype.dup
              brca_gene    = brca_genes_from(genetic_info)[:brca].upcase unless
                                   [nil, 0].include?(brca_genes_from(genetic_info))
              brca_gene = gene if brca_gene.nil?
              genotype_dup.add_gene(brca_gene)
              genotype_dup.add_variant_type(exon_from(genetic_info))
              if EXON_LOCATION_REGEX.match(genetic_info.join(','))
                extract_exon_location(genetic_info, genotype_dup)
              end
              genotype_dup.add_status(2)
              genotypes.append(genotype_dup)
              @logger.debug("IDENTIFIED #{brca_gene} for exonic variant " \
                            "#{EXON_REGEX.match(genetic_info.join(','))} from #{genetic_info}")
            end

            def extract_exon_location(genetic_info, genotype_dup)
              exon_locations = exon_locations_from(genetic_info)
              if exon_locations.flatten.compact.uniq.one?
                genotype_dup.add_exon_location(exon_locations.flatten.compact.uniq.first)
              elsif exon_locations.flatten.compact.uniq.size == 2
                genotype_dup.add_exon_location(exon_locations.flatten.compact.uniq.join('-'))
              end
            end

            def add_servicereportidentifier(genotype, record)
              servicereportidentifiers = []
              record.raw_fields.each do |records|
                servicereportidentifiers << records['servicereportidentifier']
              end
              servicereportidentifier = servicereportidentifiers.flatten.uniq.join
              genotype.attribute_map['servicereportidentifier'] = servicereportidentifier
            end

            def add_gene_and_status_to(genotype_dup, gene, status, genotypes)
              genotype_dup.add_gene(gene)
              genotype_dup.add_status(status)
              genotypes.append(genotype_dup)
            end

            def grouped_tests_from(tests)
              grouped_tests = Hash.new { |h, k| h[k] = [] }
              tests.each do |test_array|
                gene = test_array.first
                test_array[1..].each { |test_value| grouped_tests[gene] << test_value }
              end

              grouped_tests.transform_values!(&:uniq)
            end

            def relevant_consultant?(raw_record)
              raw_record['consultantname'].to_s.upcase != 'DR SANDI DEANS'
            end

            def mlh1_msh2_6_test?(moltesttypes)
              moltesttypes.include?('MLH1/MSH2/MSH6 GENETIC TESTING REPORT')
            end

            def ngs?(exons)
              exons =~ /ngs/i.freeze
            end

            def screen?(moltesttypes)
              moltesttypes =~ /screen/i.freeze
            end

            def control_sample?(raw_record)
              raw_record['genocomm'] =~ /control|ctrl/i
            end

            def twelve_tests_or_more?(moltesttypes)
              moltesttypes.size >= 12
            end

            def seven_tests_or_less?(moltesttypes)
              moltesttypes.size <= 7
            end

            def mutation_analysis?(moltesttypes)
              moltesttypes =~ /MUTATION ANALYSIS/i.freeze
            end

            def non_brca?(moltesttypes)
              !moltesttypes.scan(/brca/i).size.positive?
            end

            def brca_gene_match?(genetic_info)
              genetic_info.join(',') =~ BRCA_GENES_REGEX
            end

            def cdna_match?(genetic_info)
              genetic_info.join(',') =~ CDNA_REGEX
            end

            def exon_match?(genetic_info)
              genetic_info.join(',') =~ EXON_REGEX
            end

            def normal?(genetic_info)
              genetic_info.join(',') =~ NORMAL_REGEX
            end

            def fail?(genetic_info)
              genetic_info.join(',') =~ /fail/i
            end

            def mlpa?(exon)
              exon =~ /mlpa|P003/i
            end

            def cdna_from(genetic_info)
              CDNA_REGEX.match(genetic_info.join(','))[:cdna]
            end

            def exon_from(genetic_info)
              EXON_REGEX.match(genetic_info.join(','))[:insdeldup]
            end

            def exon_locations_from(genetic_info)
              genetic_info.join(',').scan(EXON_LOCATION_REGEX)
            end

            def protien_from(genetic_info)
              PROT_REGEX.match(genetic_info.join(','))[:impact]
            end

            def brca_genes_from(genetic_info)
              BRCA_GENES_REGEX.match(genetic_info.join(','))
            end

            def process_genotype(genotype_dup, gene, status, logging, genotypes)
              @logger.debug(logging)
              genotype_dup.add_gene(gene)
              genotype_dup.add_status(status)
              genotypes.append(genotype_dup)
            end

            def restructure_oddlynamed_nondosage_exons(dosage_nondosage)
              dosage_nondosage[:exon] = dosage_nondosage[:exon].flatten
              dosage_nondosage[:exon] =
                dosage_nondosage[:exon].map do |exons|
                  exons.gsub(/BRCA2|B2|BR2|P045|P077/, 'BRCA2')
                end
              dosage_nondosage[:exon] =
                dosage_nondosage[:exon].map do |exons|
                  exons.gsub(/BRCA1|B1|BR1|P002|P002B|P087/, 'BRCA1')
                end
              dosage_nondosage[:exon] =
                dosage_nondosage[:exon].map do |exons|
                  exons.gsub(/ATM|P041|P042/, 'ATM')
                end
              dosage_nondosage[:exon] =
                dosage_nondosage[:exon].map do |exons|
                  exons.gsub(/CHEK2|CKEK2|P190/, 'CHEK2')
                end
            end

            def list_mutations(genetic_info)
              genetic_info.join(',').scan(CDNA_REGEX).flatten.compact.map do |s|
                s.gsub(/\s+/, '')
              end.uniq
            end

            def list_proteins(genetic_info)
              genetic_info.join(',').scan(PROT_REGEX).flatten.compact.map do |s|
                s.gsub(/\s+/, '')
              end.uniq
            end

            def normal_test_logging_for(selected_genes, gene, genetic_info)
              "IDENTIFIED #{gene} from #{MOLTEST_MAP_DOSAGE[selected_genes]}, " \
                "NORMAL TEST from #{genetic_info}"
            end
          end
        end
      end
    end
  end
end
