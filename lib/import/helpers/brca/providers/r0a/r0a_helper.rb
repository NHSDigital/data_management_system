module Import
  module Helpers
    module Brca
      module Providers
        module R0a
          module R0aHelper
            include Import::Helpers::Brca::Providers::R0a::R0aConstants

            def split_multiplegenes_nondosage_map
              @non_dosage_record_map[:exon].each.with_index do |exon, index|
                next unless exon.scan(BRCA_GENES_REGEX).size.positive?

                if exon.scan(BRCA_GENES_REGEX).uniq.size > 1
                  @non_dosage_record_map[:exon][index] =
                    @non_dosage_record_map[:exon][index].scan(BRCA_GENES_REGEX).uniq
                  @non_dosage_record_map[:exon][index].flatten
                  @non_dosage_record_map[:genotype][index] =
                    if @non_dosage_record_map[:genotype][index] == 'BRCA1 Normal, BRCA2 Normal'
                      @non_dosage_record_map[:genotype][index] = ['NGS Normal'] * 2
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index].flatten
                    elsif @non_dosage_record_map[:genotype][index].scan(/Normal, /i).size.positive?
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index] = ['NGS Normal'] * 2
                    elsif @non_dosage_record_map[:genotype][index].scan(/,.+Normal/i).size.positive?
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index] = ['NGS Normal'] * 2
                    elsif @non_dosage_record_map[:genotype][index] == 'Normal'
                      @non_dosage_record_map[:genotype][index] =
                        ['Normal'] * exon.scan(BRCA_GENES_REGEX).uniq.size
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index].flatten
                    else
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index]
                    end
                  @non_dosage_record_map[:genotype2][index] =
                    if !@non_dosage_record_map[:genotype2][index].nil? &&
                       @non_dosage_record_map[:genotype2][index].scan(/coverage at 100X/).size.positive?
                      @non_dosage_record_map[:genotype2][index] = ['NGS Normal'] * 2
                      @non_dosage_record_map[:genotype2][index] =
                        @non_dosage_record_map[:genotype2][index].flatten
                    elsif !@non_dosage_record_map[:genotype2][index].nil? &&
                          @non_dosage_record_map[:genotype2][index].empty?
                      @non_dosage_record_map[:genotype2][index] = ['MLPA Normal'] * 2
                      @non_dosage_record_map[:genotype2][index] =
                        @non_dosage_record_map[:genotype2][index].flatten
                    elsif @non_dosage_record_map[:genotype2][index].nil? &&
                          @non_dosage_record_map[:genotype][index].is_a?(String) &&
                          @non_dosage_record_map[:genotype][index].scan(/MSH2/).size.positive?
                      @non_dosage_record_map[:genotype2][index] =
                        [''] * exon.scan(BRCA_GENES_REGEX).size
                      @non_dosage_record_map[:genotype2][index] =
                        @non_dosage_record_map[:genotype2][index].flatten
                    elsif @non_dosage_record_map[:genotype2][index] == 'Normal' ||
                          @non_dosage_record_map[:genotype2][index].nil? ||
                          @non_dosage_record_map[:genotype2][index] == 'Fail'
                      @non_dosage_record_map[:genotype2][index] =
                        ['Normal'] * exon.scan(BRCA_GENES_REGEX).uniq.size
                      @non_dosage_record_map[:genotype2][index] =
                        @non_dosage_record_map[:genotype2][index].flatten

                    end
                end
              end

              @non_dosage_record_map[:exon] = @non_dosage_record_map[:exon].flatten
              @non_dosage_record_map[:genotype] = @non_dosage_record_map[:genotype].flatten
              @non_dosage_record_map[:genotype2] = @non_dosage_record_map[:genotype2].flatten
            end

            def split_multiplegenes_dosage_map
              @dosage_record_map[:exon].each.with_index do |exon, index|
                if exon.scan(BRCA_GENES_REGEX).size > 1
                  @dosage_record_map[:exon][index] =
                    @dosage_record_map[:exon][index].scan(BRCA_GENES_REGEX).flatten.each do |gene|
                      gene.concat('_MLPA')
                    end
                  @dosage_record_map[:genotype][index] =
                    case @dosage_record_map[:genotype][index]
                    when 'Normal'
                      @dosage_record_map[:genotype][index] =
                        ['Normal'] * exon.scan(BRCA_GENES_REGEX).size
                      @dosage_record_map[:genotype][index] =
                        @dosage_record_map[:genotype][index].flatten
                    when 'BRCA1 Normal, BRCA2 Normal'
                      @dosage_record_map[:genotype][index] = ['NGS Normal'] * 2
                      @dosage_record_map[:genotype][index] =
                        @dosage_record_map[:genotype][index].flatten
                    else
                      @dosage_record_map[:genotype][index] =
                        @dosage_record_map[:genotype][index]
                    end
                  @dosage_record_map[:genotype2][index] =
                    if !@dosage_record_map[:genotype2][index].nil? &&
                       @dosage_record_map[:genotype2][index].empty?
                      @dosage_record_map[:genotype2][index] = ['MLPA Normal'] * 2
                      @dosage_record_map[:genotype2][index] =
                        @dosage_record_map[:genotype2][index].flatten
                    elsif !@dosage_record_map[:genotype2][index].nil? &&
                          @dosage_record_map[:genotype2][index].scan(/100% coverage at 100X/).size.positive?
                      @dosage_record_map[:genotype2][index] = ['NGS Normal'] * 2
                      @dosage_record_map[:genotype2][index] =
                        @dosage_record_map[:genotype2][index].flatten
                    end
                end
              end
              @dosage_record_map[:exon] = @dosage_record_map[:exon].flatten
              @dosage_record_map[:genotype] = @dosage_record_map[:genotype].flatten
              @dosage_record_map[:genotype2] = @dosage_record_map[:genotype2].flatten
            end

            def assign_and_populate_results_for(record)
              genotype = Import::Brca::Core::GenotypeBrca.new(record)
              genotype.add_passthrough_fields(record.mapped_fields,
                                              record.raw_fields,
                                              PASS_THROUGH_FIELDS_COLO)
              add_organisationcode_testresult(genotype)
              add_servicereportidentifier(genotype, record)
              testscope_from_rawfields(genotype, record)
              results = assign_gene_mutation(genotype, record)
              # @persister.integrate_and_store(genotype)
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
                # #binding.pry
              elsif dosage_test?
                # binding.pry
                process_dosage_test_exons(genes)
                tests = tests_from_dosage_record(genes)
                grouped_tests = grouped_tests_from(tests)
                process_grouped_dosage_tests(grouped_tests, genotype, genotypes)
                # #binding.pry
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

            # TODO: Boyscout
            def add_test_scope_to(genotype, moltesttypes, genera, exons)
              # # #binding.pry
              stringed_moltesttypes = moltesttypes.flatten.join(',')
              stringed_exons = exons.flatten.join(',')
              if stringed_moltesttypes =~ /^100,000 GENOMES/i || stringed_moltesttypes =~ /dosage/i
                genotype.add_test_scope(:full_screen)
              elsif stringed_moltesttypes =~ /predictive|confirm/i
                genotype.add_test_scope(:targeted_mutation)
              elsif stringed_moltesttypes =~ /^Ashkenazi/i
                genotype.add_test_scope(:aj_screen)
              elsif stringed_moltesttypes =~ /^Polish/i
                genotype.add_test_scope(:polish_screen)
              elsif genera.include?('G') || genera.include?('F') || genera.include?('H')
                genotype.add_test_scope(:full_screen)
              elsif ngs?(stringed_exons) || screen?(stringed_moltesttypes)
                genotype.add_test_scope(:full_screen)
              elsif mutation_analysis?(stringed_moltesttypes) || non_brca?(stringed_moltesttypes)
                if seven_tests_or_less?(moltesttypes)
                  genotype.add_test_scope(:targeted_mutation)
                elsif twelve_tests_or_more?(moltesttypes)
                  genotype.add_test_scope(:full_screen)
                end
              elsif moltesttypes.include?('BRCA1/BRCA2 GENETIC TESTING REPORT')
                genotype.add_test_scope(:full_screen)
              end
            end

            def process_grouped_non_dosage_tests(grouped_tests, genotype, genotypes)
              if (@non_dosage_record_map[:moleculartestingtype].uniq & DO_NOT_IMPORT).empty?
                grouped_tests.each do |gene, genetic_info|
                  # next unless MOLTEST_MAP[selected_genes].include? gene
                  if gene == 'No Gene'
                    @logger.debug("Nothing to do for #{gene} and #{genetic_info}")
                  elsif cdna_match?(genetic_info)
                    process_cdna(gene, genetic_info, genotype, genotypes)
                  elsif genetic_info.join(',').match(EXON_LOCATION_REGEX) &&
                        exon_match?(genetic_info)
                    process_brca_gene_and_exon_match(genotype, gene, genetic_info, genotypes)
                  elsif !cdna_match?(genetic_info) &&
                        !exon_match?(genetic_info) &&
                        normal?(genetic_info)
                    process_non_cdna_normal(gene, genetic_info, genotype, genotypes)
                  elsif !cdna_match?(genetic_info) &&
                        !exon_match?(genetic_info) &&
                        !normal?(genetic_info) &&
                        fail?(genetic_info)
                    process_non_cdna_fail(gene, genetic_info, genotype, genotypes)
                    # else # #binding.pry
                  end
                end
              else
                @logger.debug('Nothing to do')
              end
            end

            def process_cdna(gene, genetic_info, genotype, genotypes)
              genotype_dup = genotype.dup
              process_non_brca_genes(genotype_dup, gene, genetic_info, genotypes,
                                     genotype)
            end

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

            def process_non_brca_genes(genotype_dup, gene, genetic_info, genotypes,
                                       genotype)
              @logger.debug("IDENTIFIED #{gene}, #{cdna_from(genetic_info)} from #{genetic_info}")
              mutations = genetic_info.join(',').scan(CDNA_REGEX).flatten.compact.map do |s|
                s.gsub(/\s+/, '')
              end.uniq
              proteins = genetic_info.join(',').scan(PROT_REGEX).flatten.compact.map do |s|
                s.gsub(/\s+/, '')
              end.uniq
              longest_protein = proteins.max_by(&:length)
              if !genetic_info.join(',').scan(BRCA_GENES_REGEX).flatten.join.empty? &&
                 genetic_info.join(',').scan(BRCA_GENES_REGEX).flatten.join != gene
                genotype_dup.add_gene(gene.upcase)
                genotype_dup.add_status(1)
                genotypes.append(genotype_dup)
              else
                if mutations.size > 1
                  if mutations.size == 2
                    mutation_duplicate1 = mutations[0].upcase
                    mutation_duplicate2 = mutations[1].upcase
                    longest_mutation = mutations.max_by(&:length)
                    if mutation_duplicate1.include?(mutation_duplicate2) ||
                       mutation_duplicate2.include?(mutation_duplicate1)
                      if genetic_info.join(',').match(longest_mutation)
                        process_overlapping_variants(genotype, gene,
                                                     CDNA_REGEX.match(genetic_info.join(','))[:cdna],
                                                     genotypes, longest_protein, genetic_info)
                      else
                        process_overlapping_variants(genotype, gene, mutations.min_by(&:length),
                                                     genotypes, longest_protein, genetic_info)
                      end
                    elsif mutations.size > 1
                      process_multiple_variants(mutations, gene, genotype, genotypes)
                    end
                    genotypes
                  end
                elsif mutations.join.split(',').size == 1
                  process_single_mutation(genotype_dup, genetic_info, gene, genotypes)
                  genotypes
                elsif mutations.join.split(',').size > 1
                  variants = []
                  malformed_mutations = genetic_info.compact
                  malformed_mutations.split(',') do |mutation|
                    if mutation.gsub('het', '').match(CDNA_REGEX)
                      variants.append(mutation.gsub('het', '').sub(/\s+/, '').match(CDNA_REGEX)[:cdna])
                      # elsif mutation.gsub('het', '').match(CDNA_REGEX)
                      #   variants.append(mutation.match(CDNA_REGEX)[:cdna])
                    end
                  end
                  process_multiple_variants(variants, gene, genotype, genotypes)

                end
                @logger.debug("IDENTIFIED #{gene}, POSITIVE TEST from #{genetic_info}")
              end
            end

            # TODO: Boyscout
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
                if gene == 'No Gene'
                  @logger.debug("Nothing to do for #{gene} and #{genetic_info}")
                elsif !cdna_match?(genetic_info) &&
                      !exon_match?(genetic_info) &&
                      normal?(genetic_info)
                  # genotype_dup = genotype.dup
                  process_non_cdna_normal(gene, genetic_info, genotype, genotypes)
                elsif cdna_match?(genetic_info)
                  process_cdna(gene, genetic_info, genotype, genotypes)
                  @logger.debug("IDENTIFIED #{gene}, #{cdna_from(genetic_info)} from #{genetic_info}")
                elsif genetic_info.join(',').match(EXON_LOCATION_REGEX) && exon_match?(genetic_info)
                  process_brca_gene_and_exon_match(genotype, gene, genetic_info, genotypes)
                elsif !genetic_info.join(',').match(EXON_LOCATION_REGEX) && exon_match?(genetic_info)
                  case genetic_info.join(',')
                  when /normal/i, /evidence/i
                    process_non_cdna_normal(gene, genetic_info, genotype, genotypes)
                  when /control/i
                    @logger.debug("IDENTIFIED FALSE POSITIVE #{gene} #{genetic_info}, skipping entry")
                  end
                  # elsif genetic_info.join(',').match(/evidence/i)
                  #   process_non_cdna_normal(gene, genetic_info, genotype, genotypes)
                end
              elsif brca_gene_match?(genetic_info) && !exon_match?(genetic_info)
                if genetic_info.join(',').match(BRCA_GENES_REGEX)[:brca] == gene
                  genotype_dup = genotype.dup
                  add_gene_and_status_to(genotype_dup, gene, 1, genotypes)
                else
                  @logger.debug("IDENTIFIED FALSE POSITIVE #{gene} #{genetic_info}, skipping entry")
                end
              elsif brca_gene_match?(genetic_info) && exon_match?(genetic_info)
                if genetic_info.join(',').match(BRCA_GENES_REGEX)[:brca] == gene
                  process_brca_gene_and_exon_match(genotype, gene, genetic_info, genotypes)
                else
                  @logger.debug("IDENTIFIED FALSE POSITIVE #{gene} #{genetic_info}, skipping entry")
                end
              elsif !cdna_match?(genetic_info) &&
                    !exon_match?(genetic_info) &&
                    !normal?(genetic_info) &&
                    fail?(genetic_info)
                process_non_cdna_fail(gene, genetic_info, genotype, genotypes)
              else
                @logger.debug('Nothing to do')
              end
            end

            def process_brca_gene_and_exon_match(genotype, gene, genetic_info, genotypes)
              genotype_dup = genotype.dup
              brca_gene    = brca_genes_from(genetic_info)[:brca].upcase unless
                                   [nil, 0].include?(brca_genes_from(genetic_info))
              brca_gene = gene if brca_gene.nil?
              genotype_dup.add_gene(brca_gene)
              genotype_dup.add_variant_type(exon_from(genetic_info))
              if EXON_LOCATION_REGEX.match(genetic_info.join(','))
                exon_locations = exon_locations_from(genetic_info)
                if exon_locations.one?
                  genotype_dup.add_exon_location(exon_locations.flatten.first)
                elsif exon_locations.size == 2
                  genotype_dup.add_exon_location(exon_locations.flatten.compact.join('-'))
                end
              end
              genotype_dup.add_status(2)
              genotypes.append(genotype_dup)
              @logger.debug("IDENTIFIED #{brca_gene} for exonic variant " \
                            "#{EXON_REGEX.match(genetic_info.join(','))} from #{genetic_info}")
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

            def tests_from_non_dosage_record(genes)
              return if genes.nil?

              genes.zip(@non_dosage_record_map[:genotype],
                        @non_dosage_record_map[:genotype2]).uniq
            end

            def tests_from_dosage_record(genes)
              return if genes.nil?

              genes.zip(@dosage_record_map[:genotype],
                        @dosage_record_map[:genotype2]).uniq
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

            def process_multiple_variants(variantlist, gene, genotype, genotypes)
              variantlist.uniq.each do |mutation|
                duplicated_geno = genotype.dup
                duplicated_geno.add_gene(gene)
                duplicated_geno.add_gene_location(mutation)
                duplicated_geno.add_status(2)
                genotypes.append(duplicated_geno)
              end
            end

            def process_overlapping_variants(genotype, gene, variant, genotypes,
                                             longest_protein, genetic_info)
              duplicated_geno = genotype.dup
              duplicated_geno.add_gene(gene)
              duplicated_geno.add_gene_location(variant)
              process_longest_protein(longest_protein, genetic_info, duplicated_geno)
              duplicated_geno.add_status(2)
              genotypes.append(duplicated_geno)
            end

            def process_single_mutation(genotype_dup, genetic_info, gene, genotypes)
              genotype_dup.add_gene_location(cdna_from(genetic_info))
              genotype_dup.add_gene(gene.upcase)
              genotype_dup.add_status(2)
              genotypes.append(genotype_dup)
              process_single_protein(genetic_info, genotype_dup)
            end

            def process_single_protein(genetic_info, genotype_dup)
              return unless PROT_REGEX.match(genetic_info.join(','))

              # if PROT_REGEX.match(genetic_info.join(','))
              @logger.debug("IDENTIFIED #{protien_from(genetic_info)} from #{genetic_info}")
              genotype_dup.add_protein_impact(protien_from(genetic_info))
              # end
            end

            def process_longest_protein(longest_protein, genetic_info, duplicated_geno)
              return unless !longest_protein.nil? && genetic_info.join(',').match(longest_protein)

              # if !longest_protein.nil? && genetic_info.join(',').match(longest_protein)
              duplicated_geno.add_protein_impact(PROT_REGEX.match(genetic_info.join(','))[:impact])
              # end
            end

            def process_dosage_test_exons(genes)
              @dosage_record_map[:exon].map do |exons|
                if exons.scan(BRCA_GENES_REGEX).count.positive? # && mlpa?(exons)
                  exons.scan(BRCA_GENES_REGEX).flatten.each { |gene| genes.append(gene) }
                else
                  genes.append('No Gene')
                end
              end
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

            def non_dosage_test?
              @non_dosage_record_map[:moleculartestingtype].uniq.join.scan(/dosage/i).size.zero?
            end

            def dosage_test?
              @dosage_record_map[:moleculartestingtype].uniq.join.scan(/dosage/i).size.positive?
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
              genetic_info.join(',') =~ /normal|wild type|No pathogenic variant identified|No evidence/i
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
