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
              add_servicereportidentifier(genocolorectal, record)
              testscope_from_rawfields(genocolorectal, record)
              results = assign_gene_mutation(genocolorectal, record)
              results.each { |genotype| @persister.integrate_and_store(genotype) }
            end

            def assign_gene_mutation(genocolorectal, _record)
              genotypes = []
              genes = []
              if non_dosage_test?
                process_non_dosage_test_exons(genes)
                tests = tests_from_non_dosage_record(genes)
                grouped_tests = grouped_tests_from(tests)
                process_grouped_non_dosage_tests(grouped_tests, genocolorectal, genotypes)
              elsif dosage_test?
                process_dosage_test_exons(genes)
                tests = tests_from_dosage_record(genes)
                grouped_tests = grouped_tests_from(tests)
                process_grouped_dosage_tests(grouped_tests, genocolorectal, genotypes)
              end
              genotypes
            end

            def testscope_from_rawfields(genocolorectal, record)
              moltesttypes = []
              genera       = []
              exons        = []
              record.raw_fields.map do |raw_record|
                moltesttypes.append(raw_record['moleculartestingtype'])
                genera.append(raw_record['genus'])
                exons.append(raw_record['exon'])
              end

              add_test_scope_to(genocolorectal, moltesttypes, genera, exons)
            end

            # TODO: Boyscout
            def add_test_scope_to(genocolorectal, moltesttypes, genera, exons)
              stringed_moltesttypes = moltesttypes.flatten.join(',')
              stringed_exons = exons.flatten.join(',')

              if stringed_moltesttypes =~ /predictive|confirm/i
                genocolorectal.add_test_scope(:targeted_mutation)
              elsif genera.include?('G') || genera.include?('F')
                genocolorectal.add_test_scope(:full_screen)
              elsif (screen?(stringed_moltesttypes) || mlh1_msh2_6_test?(moltesttypes)) &&
                twelve_tests_or_more?(moltesttypes)
                genocolorectal.add_test_scope(:full_screen)
              elsif (screen?(stringed_moltesttypes) || mlh1_msh2_6_test?(moltesttypes)) &&
                !twelve_tests_or_more?(moltesttypes) && ngs?(stringed_exons)
                genocolorectal.add_test_scope(:full_screen)
              elsif (screen?(stringed_moltesttypes) || mlh1_msh2_6_test?(moltesttypes)) &&
                !twelve_tests_or_more?(moltesttypes) && !ngs?(stringed_exons)
                genocolorectal.add_test_scope(:targeted_mutation)
              elsif moltesttypes.include?('VARIANT TESTING REPORT')
                genocolorectal.add_test_scope(:targeted_mutation)
              elsif stringed_moltesttypes =~ /dosage/i
                genocolorectal.add_test_scope(:full_screen)
              elsif moltesttypes.include?('HNPCC MSH2 c.942+3A>T MUTATION TESTING REPORT')
                genocolorectal.add_test_scope(:full_screen)
              end
            end

            # TODO: Boyscout
            def process_grouped_non_dosage_tests(grouped_tests, genocolorectal, genotypes)
              selected_genes = (@non_dosage_record_map[:moleculartestingtype].uniq & MOLTEST_MAP.keys).join()
              if selected_genes.to_s.blank?
                @logger.debug('Nothing to do')
                return
              end
              grouped_tests.each do |gene, genetic_info|
                if MOLTEST_MAP[selected_genes].include? gene
                  genocolorectal_dup = genocolorectal.dup_colo
                  if CDNA_REGEX.match(genetic_info.join(','))
                    if COLORECTAL_GENES_REGEX.match(genetic_info.join(','))
                      if COLORECTAL_GENES_REGEX.match(genetic_info.join(','))[:colorectal] != gene
                        @logger.debug("IDENTIFIED FALSE POSITIVE FOR #{gene}, #{COLORECTAL_GENES_REGEX.match(genetic_info.join(','))[:colorectal]}, #{CDNA_REGEX.match(genetic_info.join(','))[:cdna]} from #{genetic_info}")
                      elsif COLORECTAL_GENES_REGEX.match(genetic_info.join(','))[:colorectal] == gene
                        @logger.debug("IDENTIFIED TRUE POSITIVE FOR #{gene}, #{CDNA_REGEX.match(genetic_info.join(','))[:cdna]} from #{genetic_info}")
                        genocolorectal_dup.add_gene_location(CDNA_REGEX.match(genetic_info.join(','))[:cdna])
                        if PROT_REGEX.match(genetic_info.join(','))
                          @logger.debug("IDENTIFIED #{PROT_REGEX.match(genetic_info.join(','))[:impact]} from #{genetic_info}")
                          genocolorectal_dup.add_protein_impact(PROT_REGEX.match(genetic_info.join(','))[:impact])
                        end
                        add_gene_and_status_to(genocolorectal_dup, gene, 2, genotypes)
                        @logger.debug("IDENTIFIED #{gene}, POSITIVE TEST from #{genetic_info}")
                      end
                    else
                      @logger.debug("IDENTIFIED #{gene}, #{CDNA_REGEX.match(genetic_info.join(','))[:cdna]} from #{genetic_info}")
                      genocolorectal_dup.add_gene_location(CDNA_REGEX.match(genetic_info.join(','))[:cdna])
                      if PROT_REGEX.match(genetic_info.join(','))
                        @logger.debug("IDENTIFIED #{PROT_REGEX.match(genetic_info.join(','))[:impact]} from #{genetic_info}")
                        genocolorectal_dup.add_protein_impact(PROT_REGEX.match(genetic_info.join(','))[:impact])
                      end
                      add_gene_and_status_to(genocolorectal_dup, gene, 2, genotypes)
                      @logger.debug("IDENTIFIED #{gene}, POSITIVE TEST from #{genetic_info}")
                    end
                  elsif genetic_info.join(',') !~ CDNA_REGEX && normal?(genetic_info)
                    genocolorectal_dup = genocolorectal.dup_colo
                    @logger.debug("IDENTIFIED #{gene}, NORMAL TEST from #{genetic_info}")
                    add_gene_and_status_to(genocolorectal_dup, gene, 1, genotypes)
                  elsif genetic_info.join(',') !~ CDNA_REGEX && !normal?(genetic_info) && fail?(genetic_info)
                    genocolorectal_dup = genocolorectal.dup_colo
                    add_gene_and_status_to(genocolorectal_dup, gene, 9, genotypes)
                    @logger.debug("Adding #{gene} to FAIL STATUS for #{genetic_info}")
                  end
                end
              end
            end

            # TODO: Boyscout
            def process_grouped_dosage_tests(grouped_tests, genocolorectal, genotypes)
              selected_genes = (@dosage_record_map[:moleculartestingtype].uniq & MOLTEST_MAP_DOSAGE.keys).join()
              if selected_genes.to_s.blank?
                @logger.debug('Nothing to do')
                return
              end
              grouped_tests.compact.select do |gene, genetic_info|
                if MOLTEST_MAP_DOSAGE[selected_genes].include? gene
                  if genetic_info.join(',') !~ COLORECTAL_GENES_REGEX
                    genocolorectal_dup = genocolorectal.dup_colo
                    add_gene_and_status_to(genocolorectal_dup, gene, 1, genotypes)
                    @logger.debug("IDENTIFIED #{gene} from #{MOLTEST_MAP_DOSAGE[selected_genes]}, NORMAL TEST from #{genetic_info}")
                  elsif genetic_info.join(',') =~ COLORECTAL_GENES_REGEX && genetic_info.join(',') !~ EXON_REGEX
                    genocolorectal_dup = genocolorectal.dup_colo
                    add_gene_and_status_to(genocolorectal_dup, gene, 1, genotypes)
                    @logger.debug("IDENTIFIED #{gene} from #{MOLTEST_MAP_DOSAGE[selected_genes]}, NORMAL TEST from #{genetic_info}")
                  elsif genetic_info.join(',') =~ COLORECTAL_GENES_REGEX && genetic_info.join(',') =~ EXON_REGEX
                    genocolorectal_dup = genocolorectal.dup_colo
                    genocolorectal_dup.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(genetic_info.join(','))[:colorectal])
                    genocolorectal_dup.add_variant_type(EXON_REGEX.match(genetic_info.join(','))[:insdeldup])
                    if EXON_LOCATION_REGEX.match(genetic_info.join(','))
                      if genetic_info.join(',').scan(EXON_LOCATION_REGEX).size == 1
                        genocolorectal_dup.add_exon_location(genetic_info.join(',').scan(EXON_LOCATION_REGEX).flatten[0])
                      elsif genetic_info.join(',').scan(EXON_LOCATION_REGEX).size == 2
                        genocolorectal_dup.add_exon_location(genetic_info.join(',').scan(EXON_LOCATION_REGEX).flatten.compact.join('-'))
                      end
                    end
                    genocolorectal_dup.add_status(2)
                    genotypes.append(genocolorectal_dup)
                  end
                else
                  @logger.debug("Nothing to be done for #{gene} as it is not in #{selected_genes}")
                end
              end
            end

            def add_servicereportidentifier(genocolorectal, record)
              servicereportidentifiers = []
              record.raw_fields.each do |records|
                servicereportidentifiers << records['servicereportidentifier']
              end
              servicereportidentifier = servicereportidentifiers.flatten.uniq.join()
              genocolorectal.attribute_map['servicereportidentifier'] = servicereportidentifier
            end

            def add_gene_and_status_to(genocolorectal_dup, gene, status, genotypes)
              genocolorectal_dup.add_gene_colorectal(gene)
              genocolorectal_dup.add_status(status)
              genotypes.append(genocolorectal_dup)
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
                        @non_dosage_record_map[:genotype2]).uniq
            end

            def tests_from_dosage_record(genes)
              return if genes.nil?

              genes.zip(@dosage_record_map[:genotype],
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
                if exons.scan(COLORECTAL_GENES_REGEX).count.positive? && mlpa?(exons)
                  exons.scan(COLORECTAL_GENES_REGEX).flatten.each { |gene| genes.append(gene) }
                else
                  genes.append('No Gene')
                end
              end
            end

            def relevant_consultant?(raw_record)
              raw_record['consultantname'].to_s.upcase != "DR SANDI DEANS"
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
              raw_record["genocomm"] =~ /control|ctrl/i
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

            def  mlpa?(exon)
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
