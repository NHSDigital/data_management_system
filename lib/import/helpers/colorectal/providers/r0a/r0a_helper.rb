module Import
  module Helpers
    module Colorectal
      module Providers
        module R0a
          # Processing methods used by ManchesterHandlerColorectal
          module R0aHelper
            include Import::Helpers::Colorectal::Providers::R0a::R0aConstants

            def split_multiplegenes_nondosage_map(_non_dosage_map)
              @non_dosage_record_map[:exon].each.with_index do |exon, index|
                if exon.scan(COLORECTAL_GENES_REGEX).size > 1
                  @non_dosage_record_map[:exon][index] =
                    @non_dosage_record_map[:exon][index].scan(COLORECTAL_GENES_REGEX)
                  @non_dosage_record_map[:genotype][index] =
                    if @non_dosage_record_map[:genotype][index] == 'MLH1 Normal, MSH2 Normal, MSH6 Normal'
                      @non_dosage_record_map[:genotype][index] = ['NGS Normal'] * 3
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index].flatten
                    elsif @non_dosage_record_map[:genotype][index].scan(/Normal, /i).size.positive?
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index].split(',').map do |genotypes|
                          genotypes.gsub(/.+Normal/, 'Normal')
                        end
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index].flatten
                    elsif @non_dosage_record_map[:genotype][index] == 'Normal'
                      @non_dosage_record_map[:genotype][index] =
                        ['Normal'] * exon.scan(COLORECTAL_GENES_REGEX).size
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index].flatten
                    elsif @non_dosage_record_map[:genotype][index].scan(/MSH2/) &&
                          @non_dosage_record_map[:genotype][index].scan(/MLH1/).empty? &&
                          @non_dosage_record_map[:genotype][index].scan(/MSH6/).empty?
                      @non_dosage_record_map[:genotype][index] =
                        [@non_dosage_record_map[:genotype][index]].unshift(['Normal'])
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index].flatten
                    elsif @non_dosage_record_map[:genotype][index].scan(/MLH1/) &&
                          @non_dosage_record_map[:genotype][index].scan(/MSH2/).empty? &&
                          @non_dosage_record_map[:genotype][index].scan(/MSH6/).empty?
                      @non_dosage_record_map[:genotype][index] =
                        [@non_dosage_record_map[:genotype][index]].push(['Normal'])
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index].flatten
                    elsif @non_dosage_record_map[:genotype][index].scan(/MSH2/) &&
                          @non_dosage_record_map[:genotype][index].scan(/MLH1/) &&
                          @non_dosage_record_map[:genotype][index].scan(/MSH6/).empty?
                      @non_dosage_record_map[:genotype][index] =
                        @non_dosage_record_map[:genotype][index].split(',').map(&:lstrip)
                    else @non_dosage_record_map[:genotype][index] =
                           @non_dosage_record_map[:genotype][index]
                    end
                  @non_dosage_record_map[:genotype2][index] =
                    if !@non_dosage_record_map[:genotype2][index].nil? &&
                       @non_dosage_record_map[:genotype2][index].scan(/100% coverage at 100X/).size.positive?
                      @non_dosage_record_map[:genotype2][index] = ['NGS Normal'] * 3
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
                        [''] * exon.scan(COLORECTAL_GENES_REGEX).size
                      @non_dosage_record_map[:genotype2][index] =
                        @non_dosage_record_map[:genotype2][index].flatten
                    end
                end
              end
              @non_dosage_record_map[:exon] = @non_dosage_record_map[:exon].flatten
              @non_dosage_record_map[:genotype] = @non_dosage_record_map[:genotype].flatten
              @non_dosage_record_map[:genotype2] = @non_dosage_record_map[:genotype2].flatten
            end

            def split_multiplegenes_dosage_map(_dosage_map)
              @dosage_record_map[:exon].each.with_index do |exon, index|
                if exon.scan(COLORECTAL_GENES_REGEX).size > 1
                  @dosage_record_map[:exon][index] =
                    @dosage_record_map[:exon][index].scan(COLORECTAL_GENES_REGEX).flatten.each do |gene|
                      gene.concat('_MLPA')
                    end
                  @dosage_record_map[:genotype][index] =
                    if @dosage_record_map[:genotype][index] == 'Normal'
                      @dosage_record_map[:genotype][index] =
                        ['Normal'] * exon.scan(COLORECTAL_GENES_REGEX).size
                      @dosage_record_map[:genotype][index] =
                        @dosage_record_map[:genotype][index].flatten
                    elsif @dosage_record_map[:genotype][index].scan(/MSH2/) &&
                          @dosage_record_map[:genotype][index].scan(/MLH1/).empty?
                      @dosage_record_map[:genotype][index] =
                        [@dosage_record_map[:genotype][index]].unshift(['Normal'])
                      @dosage_record_map[:genotype][index] =
                        @dosage_record_map[:genotype][index].flatten
                    elsif @dosage_record_map[:genotype][index].scan(/MLH1/) &&
                          @dosage_record_map[:genotype][index].scan(/MSH2/).empty?
                      @dosage_record_map[:genotype][index] =
                        [@dosage_record_map[:genotype][index]].push(['Normal'])
                      @dosage_record_map[:genotype][index] =
                        @dosage_record_map[:genotype][index].flatten
                    elsif @dosage_record_map[:genotype][index] == 'MLH1 Normal, MSH2 Normal, MSH6 Normal'
                      @dosage_record_map[:genotype][index] = ['NGS Normal'] * 3
                      @dosage_record_map[:genotype][index] =
                        @dosage_record_map[:genotype][index].flatten
                    end
                  @dosage_record_map[:genotype2][index] =
                    if !@dosage_record_map[:genotype2][index].nil? &&
                       @dosage_record_map[:genotype2][index].empty?
                      @dosage_record_map[:genotype2][index] = ['MLPA Normal'] * 2
                      @dosage_record_map[:genotype2][index] =
                        @dosage_record_map[:genotype2][index].flatten
                    elsif !@dosage_record_map[:genotype2][index].nil? &&
                          @dosage_record_map[:genotype2][index].scan(/100% coverage at 100X/).size.positive?
                      @dosage_record_map[:genotype2][index] = ['NGS Normal'] * 3
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
              genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
              genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                    record.raw_fields,
                                                    PASS_THROUGH_FIELDS_COLO)
              add_organisationcode_testresult(genocolorectal)
              add_servicereportidentifier(genocolorectal, record)
              testscope_from_rawfields(genocolorectal, record)
              results = assign_gene_mutation(genocolorectal, record)
              results.each { |genotype| @persister.integrate_and_store(genotype) }
            end

            def add_organisationcode_testresult(genocolorectal)
              genocolorectal.attribute_map['organisationcode_testresult'] = '69820'
            end

            def assign_gene_mutation(genocolorectal, _record)
              genotypes = []
              genes     = []
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
              return if genocolorectal.attribute_map['genetictestscope'].present?

              genocolorectal.add_test_scope(:no_genetictestscope)
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

            def process_grouped_non_dosage_tests(grouped_tests, genocolorectal, genotypes)
              selected_genes = (@non_dosage_record_map[:moleculartestingtype].uniq &
                                MOLTEST_MAP.keys).join
              return @logger.debug('Nothing to do') if selected_genes.to_s.blank?

              grouped_tests.each do |gene, genetic_info|
                next unless MOLTEST_MAP[selected_genes].include? gene

                if cdna_match?(genetic_info)
                  process_non_dosage_cdna(gene, genetic_info, genocolorectal, genotypes)
                elsif genetic_info.join(',').match(EXON_LOCATION_REGEX) &&
                      exon_match?(genetic_info)
                  process_colorectal_gene_and_exon_match(genocolorectal, genetic_info, genotypes)
                elsif !cdna_match?(genetic_info) &&
                      !exon_match?(genetic_info) &&
                      normal?(genetic_info)
                  process_non_cdna_normal(gene, genetic_info, genocolorectal, genotypes)
                elsif !cdna_match?(genetic_info) &&
                      !exon_match?(genetic_info) &&
                      !normal?(genetic_info) &&
                      fail?(genetic_info)
                  process_non_cdna_fail(gene, genetic_info, genocolorectal, genotypes)
                  # else binding.pry
                end
              end
            end

            def process_non_dosage_cdna(gene, genetic_info, genocolorectal, genotypes)
              genocolorectal_dup = genocolorectal.dup_colo
              colorectal_genes   = colorectal_genes_from(genetic_info)
              if colorectal_genes
                process_colorectal_genes(colorectal_genes, genocolorectal_dup, gene, genetic_info,
                                         genotypes)
              else
                process_non_colorectal_genes(genocolorectal_dup, gene, genetic_info, genotypes,
                                             genocolorectal)
              end
            end

            def process_non_cdna_normal(gene, genetic_info, genocolorectal, genotypes)
              genocolorectal_dup = genocolorectal.dup_colo
              @logger.debug("IDENTIFIED #{gene}, NORMAL TEST from #{genetic_info}")
              add_gene_and_status_to(genocolorectal_dup, gene, 1, genotypes)
            end

            def process_non_cdna_fail(gene, genetic_info, genocolorectal, genotypes)
              genocolorectal_dup = genocolorectal.dup_colo
              add_gene_and_status_to(genocolorectal_dup, gene, 9, genotypes)
              @logger.debug("Adding #{gene} to FAIL STATUS for #{genetic_info}")
            end

            def process_false_positive(colorectal_genes, gene, genetic_info)
              @logger.debug("IDENTIFIED FALSE POSITIVE FOR #{gene}, " \
                            "#{colorectal_genes[:colorectal]}, #{cdna_from(genetic_info)} " \
                            "from #{genetic_info}")
            end

            def process_colorectal_genes(colorectal_genes, genocolorectal_dup, gene, genetic_info,
                                         genotypes)
              if colorectal_genes[:colorectal] != gene
                process_false_positive(colorectal_genes, gene, genetic_info)
                process_non_cdna_normal(gene, genetic_info, genocolorectal_dup, genotypes)
              elsif colorectal_genes[:colorectal] == gene
                @logger.debug("IDENTIFIED TRUE POSITIVE FOR #{gene}, " \
                              "#{cdna_from(genetic_info)} from #{genetic_info}")
                genocolorectal_dup.add_gene_location(cdna_from(genetic_info))
                if PROT_REGEX.match(genetic_info.join(','))
                  @logger.debug("IDENTIFIED #{protien_from(genetic_info)} from #{genetic_info}")
                  genocolorectal_dup.add_protein_impact(protien_from(genetic_info))
                end
                add_gene_and_status_to(genocolorectal_dup, gene, 2, genotypes)
                @logger.debug("IDENTIFIED #{gene}, POSITIVE TEST from #{genetic_info}")
              end
            end

            def process_non_colorectal_genes(genocolorectal_dup, gene, genetic_info, genotypes,
                                             genocolorectal)
              @logger.debug("IDENTIFIED #{gene}, #{cdna_from(genetic_info)} from #{genetic_info}")
              mutations = genetic_info.join(',').scan(CDNA_REGEX).flatten.compact.map do |s|
                s.gsub(/\s+/, '')
              end.uniq
              if mutations.size > 1
                if mutations.size == 2
                  mutation_duplicate1 = mutations[0]
                  mutation_duplicate2 = mutations[1]
                  longest_mutation = mutations.max_by(&:length)
                  if mutation_duplicate1.include?(mutation_duplicate2) || mutation_duplicate2.include?(mutation_duplicate1)
                    # Possibly refactor this
                    genetic_info.each.with_index do |info, index|
                      if info.match(longest_mutation)
                        duplicated_geno = genocolorectal.dup_colo
                        duplicated_geno.add_gene_colorectal(gene)
                        duplicated_geno.add_gene_location(CDNA_REGEX.match(genetic_info[index])[:cdna])
                        if PROT_REGEX.match(genetic_info[index])
                          duplicated_geno.add_protein_impact(PROT_REGEX.match(genetic_info[index])[:impact])
                        end
                        duplicated_geno.add_status(2)
                        genotypes.append(duplicated_geno)
                      end
                    end
                  # Possibly refactor this
                  elsif mutations.size > 1 && genetic_info.join(',').scan(PROT_REGEX).blank?
                    mutations.each do |mutation|
                      duplicated_geno = genocolorectal.dup_colo
                      duplicated_geno.add_gene_colorectal(gene)
                      duplicated_geno.add_gene_location(mutation)
                      duplicated_geno.add_status(2)
                      genotypes.append(duplicated_geno)
                    end
                  # Possibly refactor this
                  elsif mutations.size > 1 && genetic_info.join(',').scan(PROT_REGEX).size.positive?
                    variants = mutations.zip(genetic_info.join(',').scan(PROT_REGEX).flatten)
                    variants.each do |cdna, protein|
                      duplicated_geno = genocolorectal.dup_colo
                      duplicated_geno.add_gene_colorectal(gene)
                      duplicated_geno.add_gene_location(cdna)
                      duplicated_geno.add_protein_impact(protein)
                      duplicated_geno.add_status(2)
                      genotypes.append(duplicated_geno)
                    end
                  end
                  genotypes
                end
              elsif mutations.size == 1
                genocolorectal_dup.add_gene_location(cdna_from(genetic_info))
                genocolorectal_dup.add_gene_colorectal(gene)
                genocolorectal_dup.add_status(2)
                genotypes.append(genocolorectal_dup)
                if PROT_REGEX.match(genetic_info.join(','))
                  @logger.debug("IDENTIFIED #{protien_from(genetic_info)} from #{genetic_info}")
                  genocolorectal_dup.add_protein_impact(protien_from(genetic_info))
                end
                genotypes
              end
              # add_gene_and_status_to(genocolorectal_dup, gene, 2, genotypes)
              @logger.debug("IDENTIFIED #{gene}, POSITIVE TEST from #{genetic_info}")
            end

            # TODO: Boyscout
            def process_grouped_dosage_tests(grouped_tests, genocolorectal, genotypes)
              selected_genes = (@dosage_record_map[:moleculartestingtype].uniq &
                                MOLTEST_MAP_DOSAGE.keys).join
              return @logger.debug('Nothing to do') if selected_genes.to_s.blank?

              grouped_tests.compact.select do |gene, genetic_info|
                dosage_genes = MOLTEST_MAP_DOSAGE[selected_genes]
                if dosage_genes.include? gene
                  process_dosage_gene(gene, genetic_info, genocolorectal, genotypes, dosage_genes)
                else
                  @logger.debug("Nothing to be done for #{gene} as it is not in #{selected_genes}")
                end
              end
            end

            def process_dosage_gene(gene, genetic_info, genocolorectal, genotypes, dosage_genes)
              if !colorectal_gene_match?(genetic_info)
                genocolorectal_dup = genocolorectal.dup_colo
                add_gene_and_status_to(genocolorectal_dup, gene, 1, genotypes)
                @logger.debug("IDENTIFIED #{gene} from #{dosage_genes}, " \
                              "NORMAL TEST from #{genetic_info}")
              elsif colorectal_gene_match?(genetic_info) && !exon_match?(genetic_info)
                genocolorectal_dup = genocolorectal.dup_colo
                add_gene_and_status_to(genocolorectal_dup, gene, 1, genotypes)
                @logger.debug("IDENTIFIED #{gene} from #{dosage_genes}, " \
                              "NORMAL TEST from #{genetic_info}")
              elsif colorectal_gene_match?(genetic_info) && exon_match?(genetic_info)
                process_colorectal_gene_and_exon_match(genocolorectal, genetic_info, genotypes)
              end
            end

            def process_colorectal_gene_and_exon_match(genocolorectal, genetic_info, genotypes)
              genocolorectal_dup = genocolorectal.dup_colo
              colorectal_gene    = colorectal_genes_from(genetic_info)[:colorectal] unless
                                   [nil, 0].include?(colorectal_genes_from(genetic_info))
              genocolorectal_dup.add_gene_colorectal(colorectal_gene)
              genocolorectal_dup.add_variant_type(exon_from(genetic_info))
              if EXON_LOCATION_REGEX.match(genetic_info.join(','))
                exon_locations = exon_locations_from(genetic_info)
                if exon_locations.one?
                  genocolorectal_dup.add_exon_location(exon_locations.flatten.first)
                elsif exon_locations.size == 2
                  genocolorectal_dup.add_exon_location(exon_locations.flatten.compact.join('-'))
                end
              end
              genocolorectal_dup.add_status(2)
              genotypes.append(genocolorectal_dup)
              @logger.debug("IDENTIFIED #{colorectal_gene} for exonic variant " \
                            "#{EXON_REGEX.match(genetic_info.join(','))} from #{genetic_info}")
            end

            def add_servicereportidentifier(genocolorectal, record)
              servicereportidentifiers = []
              record.raw_fields.each do |records|
                servicereportidentifiers << records['servicereportidentifier']
              end
              servicereportidentifier = servicereportidentifiers.flatten.uniq.join
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

            def colorectal_genes_from(genetic_info)
              COLORECTAL_GENES_REGEX.match(genetic_info.join(','))
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
