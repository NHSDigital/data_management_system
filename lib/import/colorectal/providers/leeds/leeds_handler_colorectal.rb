module Import
  module Colorectal
    module Providers
      module Leeds
        # rubocop:disable Metrics/ClassLength
        # Leeds importer for colorectal
        class LeedsHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rr8::Constants

          def initialize(batch)
            @genes_hash = YAML.safe_load(File.open(Rails.root.join(GENES_FILEPATH)))
            @status_hash = YAML.safe_load(File.open(Rails.root.join(STATUS_FILEPATH)))
            super
          end

          def process_fields(record)
            populate_variables(record)
            return unless should_process

            populate_genotype(record)
          end

          def populate_variables(record)
            @geno = record.raw_fields['genotype']&.downcase
            @report = cleanup_report(record.raw_fields['report'])
            @moleculartestingtype = record.raw_fields['moleculartestingtype']&.downcase
            @indicationcategory = record.raw_fields['indicationcategory']&.downcase
            @genes_panel = []
          end

          def should_process
            filename = File.basename(@batch.original_filename)
            return true if filename.match?(/MMR/i)
            return true if filename.match?(/other|familial/i) &&
                           @indicationcategory == 'cancer' &&
                           @moleculartestingtype == 'familial' &&
                           (@geno&.match?(/APC|EPCAM|LYNCH|MUTYH|PMS2/i) ||
                           @report&.match?(MMR_GENE_REGEX))

            false
          end

          def populate_genotype(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS,
                                                  FIELD_NAME_MAPPINGS)
            add_scope(genocolorectal, record)
            add_molecular_testingtype(genocolorectal, record)
            add_varclass
            add_organisationcode_testresult(genocolorectal)
            res = process_variants_from_record(genocolorectal, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def process_variants_from_record(genocolorectal, record)
            genotypes = []
            allocate_genes
            find_test_status(record)
            if genocolorectal.full_screen?
              process_fullscreen_records(genocolorectal, record, genotypes)
            elsif genocolorectal.targeted? || genocolorectal.no_scope?
              process_targeted_records(genocolorectal, record, genotypes)
            end
            genotypes
          end

          def process_targeted_records(genocolorectal, record, genotypes)
            case @teststatus
            when 1, 4, 9
              process_normal_targ(genocolorectal, record, genotypes)
            when 2, 10
              process_abnormal_targ(genocolorectal, record, genotypes)
            end
          end

          def process_normal_targ(genocolorectal, _record, genotypes)
            genocolorectal.add_gene_colorectal(@genes_panel[0])
            genocolorectal.add_status(@teststatus)
            genotypes << genocolorectal
          end

          def process_abnormal_targ(genocolorectal, _record, genotypes)
            # Extract targeted genes
            @targ_genes = extract_targeted_genes

            # Extract sentences from report
            sentences_arr = @report&.split(/\.\s+/) || []

            process_sentence_arr(sentences_arr, genocolorectal, genotypes)

            # Process remaining genes in target genes
            return if @targ_genes.blank?

            genocolorectal_dup = prepare_genotype(genocolorectal, @targ_genes[0], @report)
            process_cdna_variant(genocolorectal_dup, @report)
            genotypes << genocolorectal_dup
          end

          def extract_targeted_genes
            return @genes_panel unless @genes_panel.size > 1

            GENES_PANEL.each do |panel, genes|
              @genes_panel = genes if @genes_hash[panel].include?(@geno)
            end
            @genes_panel
          end

          def process_sentence_arr(sentences_arr, genocolorectal, genotypes)
            # Process each sentence
            sentences_arr.each do |sentence|
              gene = sentence.scan(COLORECTAL_GENES_REGEX).flatten.uniq[0]

              next unless gene.present? && @targ_genes.include?(gene)

              case sentence
              when ABSENT_REGEX
                @targ_genes -= [gene]
                process_negative_genes([gene], genocolorectal, genotypes)
              when CDNA_REGEX, EXON_VARIANT_REGEX
                @targ_genes -= [gene]
                process_mutated_genes(genocolorectal, gene, sentence, genotypes)
              end
            end
          end

          def process_mutated_genes(genocolorectal, gene, sentence, genotypes)
            cdna_vars = get_cdna_mutations(sentence)
            if cdna_vars.size > 1
              cdna_vars.each do |cdna_mutation|
                genocolorectal_dup = prepare_genotype(genocolorectal, gene, sentence)
                genocolorectal_dup.add_gene_location(cdna_mutation)
                genotypes << genocolorectal_dup
              end
            else
              genocolorectal_dup = prepare_genotype(genocolorectal, gene, sentence)
              process_cdna_variant(genocolorectal_dup, sentence)
              genotypes << genocolorectal_dup
            end
          end

          def prepare_genotype(genocolorectal, gene, text)
            genocolorectal_dup = genocolorectal.dup_colo
            genocolorectal_dup.add_gene_colorectal(gene)
            genocolorectal_dup.add_status(@teststatus)
            process_exonic_variant(genocolorectal_dup, text)
            process_protein_impact(genocolorectal_dup, text)
            genocolorectal_dup.add_variant_class(@var_class) if @genes_panel.size == 1 && @var_class
            genocolorectal_dup
          end

          def process_fullscreen_records(genocolorectal, record, genotypes)
            case @teststatus
            when 1, 4, 9
              process_normal_fs(genocolorectal, record, genotypes)
            when 2, 10
              process_abnormal_fs(genocolorectal, record, genotypes)
            end
          end

          def process_normal_fs(genocolorectal, _record, genotypes)
            @genes_panel&.each do |gene|
              genocolorectal_new = genocolorectal.dup_colo
              genocolorectal_new.add_gene_colorectal(gene)
              genocolorectal_new.add_status(@teststatus)
              genotypes << genocolorectal_new
            end
            genotypes
          end

          def process_abnormal_fs(genocolorectal, _record, genotypes)
            find_report_variant
            pos_genes = if @genes_panel&.size == 1
                          @genes_panel
                        else
                          get_genes_from_report(@report_variant)
                        end

            negative_genes = @genes_panel - pos_genes
            process_negative_genes(negative_genes, genocolorectal, genotypes)

            if pos_genes.size > 1
              process_multi_gene_abnormal(pos_genes, genocolorectal, genotypes)
            elsif pos_genes.size == 1
              process_single_pos_gene(pos_genes, genocolorectal, genotypes, @report_variant)
            end
          end

          def find_report_variant
            report = @report&.split(/Scanning|Screening/i)&.first
            @report_variant = case report
                              when VARIANT_REPORT_REGEX
                                report.scan(VARIANT_REPORT_REGEX).join('.')
                              when EXONIC_REPORT_REGEX
                                report.scan(EXONIC_REPORT_REGEX).join('.')
                              when PATHOGENIC_REPORT_REGEX
                                report.scan(PATHOGENIC_REPORT_REGEX).join('.')
                              when TARG_GENE_REGEX
                                report.scan(TARG_GENE_REGEX).join('.')
                              else
                                report
                              end
          end

          def process_single_pos_gene(pos_genes, genocolorectal, genotypes, report_variants)
            cdna_vars = get_cdna_mutations(report_variants)
            if cdna_vars.size > 1
              proteins = report_variants.scan(PROTEIN_REGEX).flatten.uniq
              cdna_vars.zip(proteins).each do |cdna_mutation, protein|
                add_variant_genotype(genocolorectal, pos_genes[0],
                                     cdna_mutation, protein, report_variants, genotypes)
              end
            else
              process_abnormal_gene(report_variants, genocolorectal, genotypes,
                                    pos_genes[0], @var_class)
            end
            genotypes
          end

          def add_variant_genotype(genocolorectal, gene, cdna, protein, report_variants, genotypes)
            genocolorectal_dup = genocolorectal.dup_colo
            genocolorectal_dup.add_gene_colorectal(gene)
            genocolorectal_dup.add_gene_location(cdna)
            genocolorectal_dup.add_protein_impact(protein)
            process_exonic_variant(genocolorectal_dup, report_variants)
            genocolorectal_dup.add_variant_class(@var_class)
            genocolorectal_dup.add_status(@teststatus)
            genotypes << genocolorectal_dup
          end

          def sentences_array
            @report_variant.split(/\.\s+|and/)
          end

          def gene_path_hash
            results = [PATHOGENIC_GENES_REGEX, GENE_PATH_REGEX].flat_map do |regexp|
              sentences_array.map do |sentence|
                sentence.match regexp
              end
            end.flatten
            gene_path_hash = {}
            results.each do |res|
              gene_path_hash.merge!(res[:assocgene] => res[:pathogenic]&.strip) if res
            end
            gene_path_hash.each_value do |v|
              v.gsub!('uncertain clinical significance', 'uncertain significance')
            end
            gene_path_hash
          end

          def process_multi_gene_abnormal(pos_genes, genocolorectal, genotypes)
            sentences_array.each do |rep|
              genes_found = rep.scan(COLORECTAL_GENES_REGEX).flatten.uniq
              gene = (genes_found & pos_genes)[0]
              next unless gene.present? && pos_genes.include?(gene)
              next unless rep.scan(CDNA_REGEX).size.positive? ||
                          rep.scan(EXON_VARIANT_REGEX).size.positive?

              pos_genes -= [gene]
              varclass = gene_path_hash[gene] || @var_class
              process_abnormal_gene(rep, genocolorectal, genotypes, gene, varclass)
            end

            return if pos_genes.blank?

            process_negative_genes(pos_genes, genocolorectal, genotypes)
          end

          def process_abnormal_gene(rep, genocolorectal, genotypes, gene, varclass)
            genocolorectal_dup = genocolorectal.dup_colo
            process_cdna_variant(genocolorectal_dup, rep)
            process_exonic_variant(genocolorectal_dup, rep)
            process_protein_impact(genocolorectal_dup, rep)
            genocolorectal_dup.add_gene_colorectal(gene)
            genocolorectal_dup.add_variant_class(varclass)
            @teststatus = 10 if NON_PATH_VARCLASS.include? varclass
            genocolorectal_dup.add_status(@teststatus)
            genotypes.append(genocolorectal_dup)
          end

          def process_negative_genes(negative_genes, genocolorectal, genotypes)
            negative_genes&.each do |gene|
              genocolorectal_dup = genocolorectal.dup_colo
              genocolorectal_dup.add_gene_colorectal(gene)
              genocolorectal_dup.add_status(1)
              genotypes << genocolorectal_dup
            end
          end

          def allocate_genes
            @genes_panel = get_genes_from_report(@report)

            return if @genes_panel.present?

            GENES_PANEL.each do |panel, genes|
              @genes_panel = genes if @genes_hash[panel].include?(@geno)
            end
          end

          def find_test_status(_record)
            @teststatus = nil
            if @geno == 'ngs msh2 seq variant'
              @teststatus = @report.include?('likely to be benign') ? 10 : 2
            else
              STATUS_PANEL.each do |category, status|
                @teststatus = status if @status_hash[category].include?(@geno)
              end
            end
            # exceptional cases for 'mlh1 only -ve' genotype
            exceptinal_teststatus if @geno == 'mlh1 only -ve'
            @teststatus
          end

          def exceptinal_teststatus
            if @report.match(/insufficient\sDNA|DNA\sprovided\sis\sof\sinsufficient/i)
              @teststatus = 9
            elsif @report.include?('The variant c.1409+47T>C was detected in intron 12')
              @teststatus = 10
            elsif @report.include?('sequence variant c.1595G>A')
              @teststatus = 2
            end
          end

          def cleanup_report(report)
            raw_report = report
            EXCLUDE_STATEMENTS.each { |st| raw_report&.sub!(st, '') }
            raw_report
          end

          def get_genes_from_report(report)
            genes = report&.scan(COLORECTAL_GENES_REGEX)&.flatten&.uniq
            if genes.present?
              genes -= ['Met'] if @report.scan(/p\.\(?\w*Met/).size.positive?
              genes -= ['met'] if @report.scan('endometrial').size.positive?
            end
            genes || []
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '699C0'
          end

          def add_varclass
            @var_class = nil
            class5 = ->(id) { VARIANT_CLASS_5.include? id }
            class7 = ->(id) { VARIANT_CLASS_7.include? id }
            @var_class = case @geno
                         when class7
                           var_class_from_report
                         when /class\s?2/i, 'fap diagn poss benign', 'fap p.glu1317gln'
                           2
                         when /class\s?3|c\s?3/i, 'conf mlpa +ve (apc)', 'fap diagn unknown'
                           3
                         when /class\s?4|c\s?4/i, 'fap diagn poss path', 'two mutations'
                           4
                         when /class\s?5|c\s?5/i, class5
                           5
                         end
          end

          def var_class_from_report
            report_cleaned = @report.gsub('No further pathogenic changes were detected', '')
            if report_cleaned.match(PATHOGENIC_REGEX)
              $LAST_MATCH_INFO[:pathogenic].strip
            else
              7
            end
          end

          def add_scope(genocolorectal, record)
            genotype = record.raw_fields['genotype'].downcase.strip
            mtype = record.raw_fields['moleculartestingtype'].downcase.strip
            if genotype.match(/pms2\s-\smlpa\spred\snegative\sc5/i) ||
               genotype.match(/pms2\s-\sconf\smlpa\spositive\sc5/i)
              genocolorectal.add_test_scope(:targeted_mutation)
            elsif mtype.present?
              genocolorectal.add_test_scope(TEST_SCOPE_MAP_COLO[mtype])
            end
          end

          def add_molecular_testingtype(genocolorectal, record)
            genotype = record.raw_fields['genotype'].downcase.strip
            mtype = record.raw_fields['moleculartestingtype'].downcase.strip
            if genotype.match(/(pred|unaff)/i)
              genocolorectal.add_molecular_testing_type_strict(:predictive)
            elsif genotype.match(/conf/i) || mtype.match(/r2(09|10|11)+/i)
              genocolorectal.add_molecular_testing_type_strict(:diagnostic)
            else
              genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[mtype])
            end
          end

          def process_scope(geno, genocolorectal, record)
            scope = Maybe(record.raw_fields['reason']).
                    or_else(Maybe(record.mapped_fields['genetictestscope']).or_else(''))
            # ------------ Set the test scope ---------------------
            if (geno.downcase.include? 'ashkenazi') || (geno.include? 'AJ')
              genocolorectal.add_test_scope(:aj_screen)
            else
              stripped_scope = TEST_SCOPE_MAP_COLO[scope.downcase.strip]
              genocolorectal.add_test_scope(stripped_scope) if stripped_scope
            end
          end

          def process_exonic_variant(genotype, variant)
            return unless variant&.scan(EXON_VARIANT_REGEX)&.size&.positive?

            genotype.add_exon_location($LAST_MATCH_INFO[:exons])
            genotype.add_variant_type($LAST_MATCH_INFO[:variant])
            @logger.debug "SUCCESSFUL exon variant parse for: #{variant}"
          end

          def process_cdna_variant(genotype, variant)
            return unless variant&.scan(CDNA_REGEX)&.size&.positive?

            genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
          end

          def get_cdna_mutations(variant)
            return [] unless variant.scan(CDNA_REGEX).size.positive?

            variant.scan(CDNA_REGEX).flatten.compact_blank.uniq
          end

          def process_protein_impact(genotype, variant)
            if variant&.scan(PROTEIN_REGEX)&.size&.positive?
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL protein parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug "FAILED protein parse for: #{variant}"
            end
          end
          # def finalize
          #             @extractor.summary
          #             super
          #           end
        end
        # rubocop:enable Metrics/ClassLength
      end
    end
  end
end
