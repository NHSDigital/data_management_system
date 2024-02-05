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
            @report = record.raw_fields['report']
            @moleculartestingtype = record.raw_fields['moleculartestingtype']&.downcase
            @indicationcategory = record.raw_fields['indicationcategory']&.downcase
            @genes_hash = YAML.safe_load(File.open(Rails.root.join(GENES_FILEPATH)))
            @status_hash = YAML.safe_load(File.open(Rails.root.join(STATUS_FILEPATH)))
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

          # rubocop:disable Metrics/AbcSize
          def populate_genotype(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS,
                                                  FIELD_NAME_MAPPINGS)
            add_scope(genocolorectal, record)
            add_molecular_testingtype(genocolorectal, record)
            res = process_variants_from_record(genocolorectal, record)
            
            # add_positive_teststatus(genocolorectal, record)
 #            failed_teststatus(genocolorectal, record)
 #            add_benign_varclass(genocolorectal, record)
 #            add_organisationcode_testresult(genocolorectal)
 #            if genocolorectal.attribute_map['genetictestscope'].nil?
 #              genocolorectal.add_test_scope(:no_genetictestscope)
 #            end
 #            res = add_gene_from_report(genocolorectal, record) # Added by Francesco
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end
          # rubocop:enable Metrics/AbcSize

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
            genocolorectal.add_gene_colorectal(@genes_panel[0])
            genocolorectal.add_status(@teststatus)
            genotypes << genocolorectal
          end
          
          def process_fullscreen_records(genocolorectal, record, genotypes)
            case @teststatus
            when 1, 4, 9
              process_normal_fs(genocolorectal, record, genotypes)
            when 2,10
              process_abnormal_fs(genocolorectal, record, genotypes)
            end
          end
          
          def process_normal_fs(genocolorectal, record, genotypes)
            @genes_panel&.each do |gene|
               genocolorectal_new = genocolorectal.dup_colo
               genocolorectal_new.add_gene_colorectal(gene)
               genocolorectal_new.add_status(@teststatus)
               genotypes << genocolorectal_new
            end
            genotypes
          end
          
          def process_abnormal_fs(genocolorectal, record, genotypes)
            find_report_variant
            if @genes_panel.size == 1
              pos_genes = @genes_panel
            else
              pos_genes = get_genes_from_report(@report_variant)
            end
           
            negative_genes = @genes_panel - pos_genes
            process_negative_genes(negative_genes, genocolorectal, genotypes)
            
            if pos_genes.nil?
               binding.pry #not able to locate gene with earlier regex
            elsif pos_genes.size > 1
              process_multi_gene_abnormal(pos_genes, genocolorectal, genotypes)
            elsif pos_genes.size == 1
              process_single_pos_gene(pos_genes, genocolorectal, genotypes, @report_variant)
            end
          
          end
          
          def process_negative_genes(negative_genes, genocolorectal, genotypes)
            negative_genes&.each do |gene|
               genocolorectal_new = genocolorectal.dup_colo
               genocolorectal_new.add_gene_colorectal(gene)
               genocolorectal_new.add_status(@teststatus)
               genotypes << genocolorectal_new
            end
            genotypes
          end
          
          def find_report_variant
            report = @report.split(/Scanning|Screening/i).first 
            case report
            when VARIANT_REPORT_REGEX
              @report_variant = $LAST_MATCH_INFO[:report]
            when EXONIC_REPORT_REGEX
              @report_variant = $LAST_MATCH_INFO[:report]
            when PATHOGENIC_REPORT_REGEX
              @report_variant = $LAST_MATCH_INFO[:report]
            when TARG_GENE_REGEX
              @report_variant = $LAST_MATCH_INFO[:report]
            else
              binding.pry
            end
          end
          
          def process_single_pos_gene(pos_genes, genocolorectal, genotypes, report_variants)
            genocolorectal_dup = genocolorectal.dup_colo
            process_cdna_variant(genocolorectal_dup, report_variants)
            process_exonic_variant(genocolorectal_dup, report_variants)
            process_protein_impact(genocolorectal_dup, report_variants)
            var_class = get_varclass
            genocolorectal_dup.add_variant_class(var_class)
            genocolorectal_dup.add_gene_colorectal(pos_genes[0])
            genotypes << genocolorectal_dup
            genotypes
          end
          
          def process_multi_gene_abnormal(pos_genes, genocolorectal, genotypes)
            mutations = @report_variant.scan(CDNA_REGEX).flatten.uniq
            if mutations.size == pos_genes.size
              process_multivariant_zip(genocolorectal, genotypes, pos_genes, mutations)
            else
              process_multivariant_split(pos_genes, genocolorectal, genotypes)
            end
          end
          
          def process_multivariant_zip(genocolorectal, genotypes, pos_genes, mutations)
            proteins = @report_variant.scan(PROTEIN_REGEX).flatten.uniq
            variants = pos_genes.zip(mutations, proteins)
            variants.each do |gene, mutation, protein|
              genocolorectal_dup = genocolorectal.dup_colo
              genocolorectal_dup.add_gene_colorectal(gene)
              genocolorectal_dup.add_gene_location(mutation)
              genocolorectal_dup.add_protein_impact(protein)
              # genocolorectal_dup.add_variant_class(@variant_class)
              genotypes.append(genocolorectal_dup)
            end
          end

          
          def process_multivariant_split(pos_genes, genocolorectal, genotypes)
            failed_genes = @report_variant.scan(GENE_FAIL_REGEX).flatten.uniq
            pos_genes -= failed_genes
            failed_genes.each do |gene|
              genocolorectal_dup = genocolorectal.dup_colo
              genocolorectal_dup.add_status(9)
              genocolorectal_dup.add_gene_colorectal(gene)
              genotypes.append(genocolorectal_dup)
            end
            
            location = find_gene_location
            report_var = @report_variant
            split_report_arr = []
            
            if pos_genes.size == 2
              case location 
              when 'first'
                report_vars = @report_variant.split(pos_genes[-1])
                report_vars[1].prepend(pos_genes[-1])
              when 'end'
                report_vars = @report_variant.split(pos_genes[0])
                report_vars[0] += pos_genes[0]
              end
              split_report_arr = report_vars
            else
              @report_variant = @report_variant.split(/MLPA analysis/i).first 
              location = find_gene_location 
              report_var = @report_variant
              case location 
              when 'first'
                pos_genes.reverse_each do |gene|
                  report_vars = report_var.split(gene)
                  split_report_arr << report_vars.last.prepend(gene)
                  report_var = report_vars.first
                end
              when 'end'
                pos_genes.each do |gene|
                  report_vars = report_var.split(gene)
                  split_report_arr << report_vars.first+gene
                  report_var = report_vars.last
                end
              end
            end
             
            split_report_arr.each do |rep|
              gene = rep.scan(COLORECTAL_GENES_REGEX).flatten.uniq[0]
              next unless gene.present? || pos_genes.include?(gene)
              pos_genes -= [gene]
              genocolorectal_dup = genocolorectal.dup_colo
              genocolorectal_dup.add_status(1)
              process_cdna_variant(genocolorectal_dup, rep)
              process_exonic_variant(genocolorectal_dup, rep)
              process_protein_impact(genocolorectal_dup, rep)
              genocolorectal_dup.add_gene_colorectal(gene)
              genotypes.append(genocolorectal_dup)
            end
          end
          
          def find_gene_location
            case @report_variant
            when GENE_FIRST_VARIANT_REGEX
              'first'
            when VARIANT_FIRST_GENE_REGEX
              'end'
            end
          end
          
          def process_multi_pos_genes(pos_genes, genocolorectal, genotypes, report_variant)
           
          end
          
          def process_negative_genes(negative_genes, genocolorectal, genotypes)
            negative_genes&.each do |gene|
              genocolorectal_dup = genocolorectal.dup_colo
              genocolorectal_dup.add_gene_colorectal(gene)
              genocolorectal_dup.add_status(1)
              genotypes << genocolorectal_dup
            end
          end
          
          def allocate_genes(record)
            @genes_panel = get_genes_from_report(@report)
            
            return unless @genes_panel.nil?
              
            GENES_PANEL.each do |panel, genes|
              @genes_panel = genes if @genes_hash[panel].include?(@geno)
            end
            # binding.pry if @genes_panel.nil?
          end
          
          def find_test_status(record)
            if @geno == 'NGS MSH2 seq variant'
              #get from report
            else
              STATUS_PANEL.each do |category, status|
                @teststatus = status if @status_hash[category].include?(@geno)
              end
            end
          end
          
          def get_genes_from_report(report)
            genes = report&.scan(COLORECTAL_GENES_REGEX)&.flatten&.uniq
            if genes.present?
              genes -= ['Met'] if @report&.scan(/p\.\(?\w*Met/).size.positive?
              genes -= ['met'] if @report&.scan(/endometrial/).size.positive?
            end
            genes
          end
          
          def get_gene_from_genotype(record)
            GENES_PANEL.each do |panel, genes|
              genes_panel = genes if @genes_hash[panel].include?(@geno)
            end
            genes_panel
          end
          
          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '699C0'
          end

          def get_varclass
            binding.pry if /fap\sdiagn\smutyh\shet/i.match(@geno)
            if /C4\/5/i.match(@geno)
              
              binding.pry 
              
              if @report.exclude?('likely pathogenic to uncertain significance') && @report.match(PATHOGENIC_REGEX)
                 @var_class = $LAST_MATCH_INFO[:pathogenic]
              else
                 @var_class = 7
              end
             
            elsif /class\s2/i.match(@geno) ||
              ['fap diagn poss benign','fap p.glu1317gln'].include?(@geno)
              @var_class = 2
            elsif /class\s3|c3/i.match(@geno) ||
                 ['conf mlpa +ve (apc)', 'fap diagn unknown'].include?(@geno)
              @var_class = 3
            elsif /class\s4|c4/i.match(@geno) ||
              ['fap diagn poss path', 'two mutations'].include?(@geno)
               @var_class = 4
            elsif /class\s5|c5/i.match(@geno) ||
              VARIANT_CLASS_5.include?(@geno)
               @var_class = 5
             else
              binding.pry if /class/i.match(@report) && @report.exclude?('likely pathogenic to uncertain significance')
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
            else
              binding.pry
            end
          end
          
          def add_molecular_testingtype(genocolorectal, record)
            genotype = record.raw_fields['genotype'].downcase.strip
            mtype = record.raw_fields['moleculartestingtype'].downcase.strip
            genocolorectal.add_molecular_testing_type_strict(:diagnostic) if mtype.match(/r2(09|10|11)+/i)
            genocolorectal.add_molecular_testing_type_strict(:diagnostic) if genotype.match(/conf/i)
            genocolorectal.add_molecular_testing_type_strict(:predictive) if genotype.match(/(pred|unaff)/i)
            genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[mtype])  unless mtype.nil?
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
            return unless variant.scan(EXON_VARIANT_REGEX).size.positive?

            genotype.add_exon_location($LAST_MATCH_INFO[:exons])
            genotype.add_variant_type($LAST_MATCH_INFO[:variant])
            genotype.add_status(@teststatus)
            @logger.debug "SUCCESSFUL exon variant parse for: #{variant}"
          end

          def process_cdna_variant(genotype, variant)
            return unless variant.scan(CDNA_REGEX).size.positive?

            genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
            genotype.add_status(@teststatus)
            @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
          end

          def process_protein_impact(genotype, variant)
            if variant.scan(PROTEIN_REGEX).size.positive?
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              genotype.add_status(@teststatus)
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

