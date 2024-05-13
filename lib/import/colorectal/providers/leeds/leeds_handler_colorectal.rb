# require_relative 'report_extractor'
require 'pry'

module Import
  module Colorectal
    module Providers
      module Leeds
        # rubocop:disable Metrics/ClassLength
        # Leeds importer for colorectal
        class LeedsHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rr8::Constants

          def process_fields(record)
            populate_variables(record)
            return unless should_process(record)

            populate_genotype(record)
          end

          def populate_variables(record)
            @geno = record.raw_fields['genotype']&.downcase
            @report = cleanup_report(record.raw_fields['report'])
            @moleculartestingtype = record.raw_fields['moleculartestingtype']&.downcase
            @indicationcategory = record.raw_fields['indicationcategory']&.downcase
            @genes_hash = YAML.safe_load(File.open(Rails.root.join(GENES_FILEPATH)))
            @status_hash = YAML.safe_load(File.open(Rails.root.join(STATUS_FILEPATH)))
            @genes_panel = []
          end

          def should_process(_record)
            filename = @batch.original_filename.split('/').last
            return true if filename.scan(/MMR/i).size.positive?
            return true if filename.scan(/other|familial/i).size.positive? &&
                           @indicationcategory == 'cancer' &&
                           @moleculartestingtype == 'familial' &&
                           (@geno&.scan(/APC|EPCAM|LYNCH|MUTYH|PMS2/i)&.size&.positive? ||
                           @report&.scan(/APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|PMS2|POLD1|POLE|PTEN|SMAD4|STK11/i)&.size&.positive?)

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
            allocate_genes(record)
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
            if @genes_panel.size > 1
              GENES_PANEL.each do |panel, genes|
                @genes_panel = genes if @genes_hash[panel].include?(@geno)
              end
            end

            targ_genes = @genes_panel
            sentences_arr = @report&.split(/\.\s+/) || []

            sentences_arr.each do |sentence|
              gene = sentence.scan(COLORECTAL_GENES_REGEX).flatten.uniq[0]

              if sentence.match(ABSENT_REGEX)
                targ_genes -= [gene]
                process_negative_genes([gene], genocolorectal, genotypes)
              end

              next unless gene.present? && targ_genes.include?(gene)
              next unless sentence.scan(CDNA_REGEX).size.positive? ||
                          sentence.scan(EXON_VARIANT_REGEX).size.positive?

              targ_genes -= [gene]
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

            return if targ_genes.blank?

            genocolorectal_dup = prepare_genotype(genocolorectal, targ_genes[0], @report)
            process_cdna_variant(genocolorectal_dup, @report)
            genotypes << genocolorectal_dup
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
                genocolorectal_dup = genocolorectal.dup_colo
                genocolorectal_dup.add_gene_colorectal(pos_genes[0])
                genocolorectal_dup.add_gene_location(cdna_mutation)
                genocolorectal_dup.add_protein_impact(protein)
                process_exonic_variant(genocolorectal_dup, report_variants)
                genocolorectal_dup.add_variant_class(@var_class)
                genocolorectal_dup.add_status(@teststatus)
                genotypes << genocolorectal_dup
              end
            else
              genocolorectal_dup = genocolorectal.dup_colo
              process_cdna_variant(genocolorectal_dup, report_variants)
              process_exonic_variant(genocolorectal_dup, report_variants)
              process_protein_impact(genocolorectal_dup, report_variants)
              genocolorectal_dup.add_variant_class(@var_class)
              genocolorectal_dup.add_gene_colorectal(pos_genes[0])
              genocolorectal_dup.add_status(@teststatus)
              genotypes << genocolorectal_dup
            end
            genotypes
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
            gene_path_hash.map { |_k, v| v.gsub!('uncertain clinical significance', 'uncertain significance') }
            gene_path_hash
          end

          def process_multi_gene_abnormal(pos_genes, genocolorectal, genotypes)
            sentences_array.each do |rep|
              genes_found = rep.scan(COLORECTAL_GENES_REGEX).flatten.uniq
              gene = (genes_found & pos_genes)[0]
              next unless gene.present? && pos_genes.include?(gene)
              next unless rep.scan(CDNA_REGEX).size.positive? || rep.scan(EXON_VARIANT_REGEX).size.positive?

              pos_genes -= [gene]
              genocolorectal_dup = genocolorectal.dup_colo
              process_cdna_variant(genocolorectal_dup, rep)
              process_exonic_variant(genocolorectal_dup, rep)
              process_protein_impact(genocolorectal_dup, rep)
              genocolorectal_dup.add_gene_colorectal(gene)
              varclass = gene_path_hash[gene] || @var_class
              genocolorectal_dup.add_variant_class(varclass)
              @teststatus = 10 if NON_PATH_VARCLASS.include? varclass
              genocolorectal_dup.add_status(@teststatus)
              genotypes.append(genocolorectal_dup)
            end

            return if pos_genes.blank?

            process_negative_genes(pos_genes, genocolorectal, genotypes)
          end

          def process_negative_genes(negative_genes, genocolorectal, genotypes)
            negative_genes&.each do |gene|
              genocolorectal_dup = genocolorectal.dup_colo
              genocolorectal_dup.add_gene_colorectal(gene)
              genocolorectal_dup.add_status(1)
              genotypes << genocolorectal_dup
            end
          end

          def allocate_genes(_record)
            @genes_panel = get_genes_from_report(@report)

            return if @genes_panel.present?

            GENES_PANEL.each do |panel, genes|
              @genes_panel = genes if @genes_hash[panel].include?(@geno)
            end
          end

          def find_test_status(_record)
            @teststatus = nil
            if @geno == 'ngs msh2 seq variant'
              @teststatus = if @report.include?('likely to be benign')
                              10
                            else
                              2
                            end
            else
              STATUS_PANEL.each do |category, status|
                @teststatus = status if @status_hash[category].include?(@geno)
              end
            end
            # exceptional cases for 'mlh1 only -ve' genotype
            if @geno == 'mlh1 only -ve'
              if @report.include?('However, insufficient DNA has been provided')
                @teststatus = 9
              elsif @report.include?('The variant c.1409+47T>C was detected in intron 12')
                @teststatus = 10
              elsif @report.include?('sequence variant c.1595G>A')
                @teststatus = 2
              end
            end
            @teststatus
          end

          def cleanup_report(report)
            raw_report = report
            exclude_statements = [
              'Screening for mutations in MLH1, MSH2 and MSH6 is now in progress as requested.',
              'MLPA and MSH2 analysis was not requested.',
              'MLPA and MSH2 analysis were not requested.',
              'if MSH2 and MSH6 data analysis is required.',
              'No further screening for mutations in MLH1, MSH2 or MSH6 has been performed.',
              'developing further MSH2-related cancers',
              'developing MSH2-associated cancer'
            ]

            exclude_statements.each { |st| raw_report&.sub!(st, '') }
            raw_report
          end

          def get_genes_from_report(report)
            genes = report&.scan(COLORECTAL_GENES_REGEX)&.flatten&.uniq
            if genes.present?
              genes -= ['Met'] if @report&.scan(/p\.\(?\w*Met/)&.size&.positive?
              genes -= ['met'] if @report&.scan('endometrial')&.size&.positive?
            end
            genes || []
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '699C0'
          end

          def add_varclass
            @var_class = nil
            if %r{C4/5}i.match(@geno)
              @var_class = if @report.exclude?('likely pathogenic to uncertain significance') && @report.match(PATHOGENIC_REGEX)
                             $LAST_MATCH_INFO[:pathogenic]
                           else
                             7
                           end
            elsif /class\s?2/i.match(@geno) ||
                  ['fap diagn poss benign', 'fap p.glu1317gln'].include?(@geno)
              @var_class = 2
            elsif /class\s?3|c\s?3/i.match(@geno) ||
                  ['conf mlpa +ve (apc)', 'fap diagn unknown'].include?(@geno)
              @var_class = 3
            elsif /class\s?4|c\s?4/i.match(@geno) ||
                  ['fap diagn poss path', 'two mutations'].include?(@geno)
              @var_class = 4
            elsif /class\s?5|c\s?5/i.match(@geno) ||
                  VARIANT_CLASS_5.include?(@geno)
              @var_class = 5
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
            genocolorectal.add_molecular_testing_type_strict(:diagnostic) if mtype.match(/r2(09|10|11)+/i)
            genocolorectal.add_molecular_testing_type_strict(:diagnostic) if genotype.match(/conf/i)
            genocolorectal.add_molecular_testing_type_strict(:predictive) if genotype.match(/(pred|unaff)/i)
            genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[mtype]) unless mtype.nil?
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

          def add_colorectal_from_raw_genotype(genocolorectal, record)
            colo_string = record.raw_fields['genotype']
            if colo_string.scan(COLORECTAL_GENES_REGEX).size > 1
              @logger.error "Multiple genes detected in report: #{colo_string};"
            elsif COLORECTAL_GENES_REGEX.match(colo_string) &&
                  colo_string.scan(COLORECTAL_GENES_REGEX).size == 1
              genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
              # when COLORECTAL_GENES_REGEX and test_string.scan(GENE_REGEX).size > 1
              @logger.debug "SUCCESSFUL gene parse from raw_record for: #{$LAST_MATCH_INFO[:colorectal]}"
            else
              @logger.debug 'No Gene detected'
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
