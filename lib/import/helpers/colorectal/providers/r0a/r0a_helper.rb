require 'import/helpers/colorectal/providers/r0a/r0a_constants'

module Import
  module Helpers
    module Colorectal
      module Providers
        module R0a
          # Processing methods used by ManchesterHandlerColorectal
          module R0aHelper
            include Import::Helpers::Colorectal::Providers::R0a::R0aConstants

            def assign_and_populate_results_for(record)
              genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
              genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                    record.raw_fields,
                                                    PASS_THROUGH_FIELDS_COLO)
              testscope_from_rawfields(genocolorectal, record)
              results = assign_gene_mutation(genocolorectal, record)
              results.each { |genotype| @persister.integrate_and_store(genotype) }
            end

            def process_grouped_non_dosage_tests(grouped_tests, genocolorectal, genotypes)
              grouped_tests.each do |gene, genetic_info|
                if selected_genes.to_s.blank?
                  @logger.debug("Nothing to do")
                  break
                elsif MOLTEST_MAP[selected_genes].include? gene
                  genocolorectal1 = genocolorectal.dup_colo
                  if CDNA_REGEX.match(genetic_info.join(','))
                    @logger.debug("IDENTIFIED #{gene}, #{CDNA_REGEX.match(genetic_info.join(','))[:cdna]} from #{genetic_info}")
                    genocolorectal1.add_gene_location(CDNA_REGEX.match(genetic_info.join(','))[:cdna])
                    if PROT_REGEX.match(genetic_info.join(','))
                      @logger.debug("IDENTIFIED #{PROT_REGEX.match(genetic_info.join(','))[:impact]} from #{genetic_info}")
                      genocolorectal1.add_protein_impact(PROT_REGEX.match(genetic_info.join(','))[:impact])
                    end
                  genocolorectal1.add_gene_colorectal(gene)
                  @logger.debug("IDENTIFIED #{gene}, POSITIVE TEST from #{genetic_info}")
                  genocolorectal1.add_status(2)
                  genotypes.append(genocolorectal1)
                  elsif genetic_info.join(',') !~ CDNA_REGEX and genetic_info.join(',') =~ /normal/i
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug("IDENTIFIED #{gene}, NORMAL TEST from #{genetic_info}")
                    genocolorectal1.add_gene_colorectal(gene)
                    genocolorectal1.add_status(1)
                    genotypes.append(genocolorectal1)
                  elsif genetic_info.join(',') !~ CDNA_REGEX and genetic_info.join(',') !~ /normal/i and genetic_info.join(',') =~ /fail/i
                    genocolorectal1 = genocolorectal.dup_colo
                    genocolorectal1.add_gene_colorectal(gene)
                    @logger.debug("Adding #{gene} to FAIL STATUS for #{genetic_info}")
                    genocolorectal1.add_status(9)
                    genotypes.append(genocolorectal1)
                  end
                end
              end
            end

            def process_grouped_dosage_tests(grouped_tests, genocolorectal, genotypes)
              if selected_genes.to_s.blank?
                @logger.debug("Nothing to do")
                return
              end
              grouped_tests.compact.each do |gene, genetic_info|
                if MOLTEST_MAP_DOSAGE[selected_genes].include? gene
                  genocolorectal_dup = genocolorectal.dup_colo
                  if genetic_info.join(',') !~ COLORECTAL_GENES_REGEX
                    add_gene_and_status_to(genocolorectal_dup, gene, 1)
                    @logger.debug("IDENTIFIED #{gene} from #{MOLTEST_MAP_DOSAGE[selected_genes]}, NORMAL TEST from #{genetic_info}")
                  elsif genetic_info.join(',') =~ COLORECTAL_GENES_REGEX && genetic_info.join(',') !~ EXON_REGEX
                    genocolorectal_dup.add_gene_colorectal(gene)
                    genocolorectal_dup.add_status(1)
                    @logger.debug("IDENTIFIED #{gene} from #{MOLTEST_MAP_DOSAGE[selected_genes]}, NORMAL TEST from #{genetic_info}")
                  elsif genetic_info.join(',') =~ COLORECTAL_GENES_REGEX && genetic_info.join(',') =~ EXON_REGEX
                    genocolorectal_dup.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(genetic_info.join(','))[:colorectal])
                    genocolorectal_dup.add_variant_type(EXON_REGEX.match(genetic_info.join(','))[:insdeldup])
                    genocolorectal_dup.add_status(2)
                  end
                else 
                  @logger.debug("Nothing to be done for #{gene} as it is not in #{selected_genes}")
                end
              end
            end

            def add_gene_and_status_to(genocolorectal_dup, gene, status)
              genocolorectal_dup.add_gene_colorectal(gene)
              genocolorectal_dup.add_status(status)
            end

            def selected_genes
              (@non_dosage_record_map[:moleculartestingtype].uniq & MOLTEST_MAP.keys).join()
            end

            def add_test_scope_to(genocolorectal, moltesttypes, genera, exons)
              stringed_moltesttypes = moltesttypes.flatten.join(',')
              stringed_exons = exons.flatten.join(',')

              if stringed_moltesttypes =~ /predictive|confirm/i
                genocolorectal.add_test_scope(:targeted_mutation)
              elsif genera.include?('G') || genera.include?('F')
                genocolorectal.add_test_scope(:full_screen)
              elsif screen_and_mlh1_msh2_6_test? && twelve_tests_or_more?(moltesttypes)
                genocolorectal.add_test_scope(:full_screen)
              elsif screen_and_mlh1_msh2_6_test? && !twelve_tests_or_more?(moltesttypes) &&
                ngs?(stringed_exons)
                genocolorectal.add_test_scope(:full_screen)
              elsif screen_and_mlh1_msh2_6_test && !twelve_tests_or_more?(moltesttypes) &&
                !ngs?(stringed_exons)
                genocolorectal.add_test_scope(:targeted_mutation)
              elsif moltesttypes.include?('VARIANT TESTING REPORT')
                genocolorectal.add_test_scope(:targeted_mutation)
              elsif stringed_moltesttypes =~ /dosage/i
                genocolorectal.add_test_scope(:full_screen)
              elsif moltesttypes.include?('HNPCC MSH2 c.942+3A>T MUTATION TESTING REPORT')
                genocolorectal.add_test_scope(:full_screen)
              end
            end

            def grouped_tests_from(tests)
              grouped_tests = Hash.new { |h, k| h[k] = [] }
              tests.each do |test_array|
                gene = test_array.first
                test_array[1..-1].each { |test_value| grouped_tests[gene] << test_value }
              end

              grouped_tests.transform_values!(&:uniq)
            end

            def tests_from_non_dosage_record(genes)
              return if genes.nil?

              genes.zip(@non_dosage_record_map[:genotype],
                        @non_dosage_record_map[:genotype2],
                        @non_dosage_record_map[:moleculartestingtype]).uniq
            end

            def tests_from_dosage_record(genes)
              return if genes.nil?

              tests = genes.zip(@dosage_record_map[:genotype],
                                @dosage_record_map[:genotype2],
                                @dosage_record_map[:moleculartestingtype]).uniq
            end

            def process_non_dosage_test_exons(genes)
              @non_dosage_record_map[:exon].each do |exons|
                if exons =~ COLORECTAL_GENES_REGEX
                  genes.append(COLORECTAL_GENES_REGEX.match(exons)[:colorectal])
                else
                  genes.append('No Gene')
                end
              end
            end

            def process_dosage_test_exons(genes)
              @dosage_record_map[:exon].map do |exons|
                require 'pry'; binding.pry
                if exons.scan(COLORECTAL_GENES_REGEX).count.positive? && mlpa?(exons)
                  exons.scan(COLORECTAL_GENES_REGEX).flatten.each { |gene| genes.append(gene) }
                else
                  genes.append('No Gene')
                end
              end
            end

            def relevant_consultant?(raw_record)
              raw_record['consultantcode'].to_s.upcase != "DR SANDI DEANS"
            end

            def mlh1_msh2_6_test?(moltesttype)
              moltesttype.include?('MLH1/MSH2/MSH6 GENETIC TESTING REPORT')
            end

            def ngs?(stringed_exons)
              stringed_exon =~ /ngs/i.freeze
            end

            def screen?(stringed_moltesttypes)
              stringed_moltesttypes =~ /screen/i.freeze
            end

            def control_sample?(raw_record)
              raw_record["genocomm"] =~ /control|ctrl/i
            end

            def screen_and_mlh1_msh2_6_test?
              screen? && mlh1_msh2_6_test?
            end

            def twelve_tests_or_more?(moltesttypes)
              moltesttypes.size >= 12
            end

            def cdna_from(genetic_info)
              CDNA_REGEX.match(genetic_info.join(','))[:cdna]
            end

            def protein_from(genetic_info)
              PROT_REGEX.match(genetic_info.join(','))[:impact]
            end

            def non_dosage_test?
              (MOLTEST_MAP.keys & @non_dosage_record_map[:moleculartestingtype].uniq).size == 1
            end

            def dosage_test?
              (MOLTEST_MAP_DOSAGE.keys & @dosage_record_map[:moleculartestingtype].uniq).size == 1
            end

            def colorectal_gene_match?(genetic_info)
              genetic_info.join(',') =~ COLORECTAL_GENES_REGEX
            end

            def cdna_match?(genetic_info)
              genetic_info.join(',') =~ CDNA_REGEX
            end

            def exon_match?(genetic_info)
              genetic_info.join(',') =~ EXON_REGEX
            end

            def normal?(genetic_info)
              genetic_info.join(',') =~ /normal/i
            end
 
            def fail?(genetic_info)
              genetic_info.join(',') =~ /fail/i
            end

            def  mlpa?(exeon)
              exon =~ /mlpa/i
            end

            def process_genocolorectal(genocolorectal_dup, gene, status, logging, genotypes)
              @logger.debug(logging)
              genocolorectal_dup.add_gene_colorectal(gene)
              genocolorectal_dup.add_status(status)
              genotypes.append(genocolorectal_dup)
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
