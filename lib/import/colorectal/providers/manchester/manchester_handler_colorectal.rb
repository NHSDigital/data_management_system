module Import
  module Colorectal
    module Providers
      module Manchester
        # Manchester R0A importer
        class ManchesterHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::R0a::R0aConstants
          include Import::Helpers::Colorectal::Providers::R0a::R0aHelper

          def initialize(batch)
            @failed_genocolorectal_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          def process_fields(record)
            @logger.debug('STARTING PARSING')
            do_not_import(record)
            return if record.raw_fields.empty?

            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            add_organisationcode_testresult(genocolorectal)
            add_servicereportidentifier(genocolorectal, record)
            @raw_fields = record.raw_fields
            fix_genes(record)
            assign_testscope_group(genocolorectal)
            genocolorectals = []
            assign_gene(genocolorectal, record, genocolorectals)
            genocolorectals.each { |genotype| @persister.integrate_and_store(genotype) }
            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            @logger.debug('DONE TEST')
          end

          def fix_genes(_record)
            @raw_fields.each do |rec|
              rec['genotype']&.gsub!('MHS2', 'MSH2')
              rec['genotype']&.gsub!('MLA1', 'MLH1')
              rec['genotype']&.gsub!('MHS6', 'MSH6')
              rec['genotype2']&.gsub!('MHS2', 'MSH2')
              rec['genotype2']&.gsub!('MLA1', 'MLH1')
              rec['genotype2']&.gsub!('MHS6', 'MSH6')
              rec['exon']&.gsub!('MHS2', 'MSH2')
              rec['exon']&.gsub!('MLA1', 'MLH1')
              rec['exon']&.gsub!('MHS6', 'MSH6')
            end
          end

          def assign_testscope_group(genocolorectal)
            group_moleculartesting = @raw_fields.pluck('moleculartestingtype').uniq
            group_genus = @raw_fields.pluck('genus').uniq
            group_exon = @raw_fields.pluck('exon').uniq
            records_size = @raw_fields.size
            fs_molecular_regex = Regexp.union(DOSAGE_HNPCC_GENTIC_TESTING_REGEX,
                                              GENOMICS_LAB_REPORT, INHERIT_GENETIC_REPORT)
            # Duplicate body for targeted cannot be combined due to prioroty of filtering the
            # records using if-elseif mode
            if group_moleculartesting.grep(/predictive|confirm/i).length.positive?
              genocolorectal.add_test_scope(:targeted_mutation)
            elsif group_genus.grep(/F|G/).length.positive? ||
                  ((group_moleculartesting.grep(SCREEN_GENTIC_TESTING_REGEX).length.positive? ||
                    group_moleculartesting.compact_blank.empty?) &&
                  (records_size > 12 ||
                  (records_size <= 12 && group_exon.grep(/NGS/).length.positive?))) ||
                  group_moleculartesting.grep(fs_molecular_regex).length.positive?
              genocolorectal.add_test_scope(:full_screen)
            elsif (records_size <= 12 &&
                  (group_moleculartesting.grep(SCREEN_GENTIC_TESTING_REGEX).length.positive? ||
                   group_moleculartesting.compact_blank.empty?) &&
                   group_exon.grep(/NGS/).empty?) ||
                  group_moleculartesting.grep(/VARIANT\sTESTING\sREPORT/i).length.positive?
              genocolorectal.add_test_scope(:targeted_mutation)
            else
              genocolorectal.add_test_scope(:no_genetictestscope)
            end
          end

          def assign_gene(genocolorectal, record, genocolorectals)
            group_moleculartesting = @raw_fields.pluck('moleculartestingtype').uniq.join.upcase
            valid_genes = MOLTEST_GENE_MAP[group_moleculartesting] || %w[MLH1 MSH2 MSH6 EPCAM APC
                                                                         MUTYH CDH1]
            genes_found = extract_genes_from_raw_fields
            @genes = genes_found.flatten.intersection(valid_genes)
            process_records(record, genocolorectal, genocolorectals)
          end

          def process_records(_record, genocolorectal, genocolorectals)
            variant_recs = get_status_records(@raw_fields, Regexp.union(CDNA_REGEX, EXON_REGEX))
            normal_recs = get_status_records(@raw_fields - variant_recs, NORMAL_STATUS)
            failed_recs = get_status_records(@raw_fields - normal_recs, FAIL_STATUS)

            process_status_recs(variant_recs, Regexp.union(CDNA_REGEX, EXON_REGEX),
                                genocolorectal, genocolorectals)
            process_status_recs(normal_recs, NORMAL_STATUS, genocolorectal, genocolorectals)
            process_status_recs(failed_recs, FAIL_STATUS, genocolorectal, genocolorectals)

            # Left over records
            remaining_raw_records = @raw_fields.reject { |h| failed_recs.include?(h) }
            remaining_raw_records.each do |rec|
              genotype_column = rec['genotype'].blank? ? 'genotype2' : 'genotype'
              process_genotypes(rec, genotype_column, genocolorectal, genocolorectals)
            end

            return if @genes.empty? || !genocolorectal.full_screen?

            # mark left genes as normal
            mark_genes_normal(genocolorectal, genocolorectals)
          end

          def process_genotypes(rec, genotype_column, genocolorectal, genocolorectals)
            genes_present = rec[genotype_column].scan(COLORECTAL_GENES_REGEX).flatten.uniq
            genotype_arr = get_gene_seprated_array(genes_present, rec, genotype_column)
            genotype_arr.each do |genotype|
              genes_genotype = genotype.scan(COLORECTAL_GENES_REGEX).flatten.uniq
              genes_exon = rec['exon'].scan(COLORECTAL_GENES_REGEX).flatten.uniq
              genes_to_process = genes_genotype.size.positive? ? genes_genotype : genes_exon
              relevant_genes = genes_to_process & @genes
              process_relevant_genes(relevant_genes, genocolorectal, genocolorectals, genotype)
            end
          end

          def get_status(genotype)
            if positive_cdna?(genotype) || positive_exonvariant?(genotype) ||
               genotype.match?(/del|het/i) || genotype == 'Shift'
              2
            elsif genotype.match?(NORMAL_STATUS)
              1
            elsif genotype.match?(FAIL_STATUS)
              9
            else
              4
            end
          end

          def extract_genes_from_raw_fields
            genes_found = []
            @raw_fields.each do |raw_record|
              moltesttype = raw_record['moleculartestingtype']
              genotype = raw_record['genotype']
              exon = raw_record['exon']
              genotype2 = raw_record['genotype2']
              next if MSH6_DOSAGE_MTYPE.include?(moltesttype) && !exon.scan(/MLPA/i).size.positive?
              next if moltesttype.match?(/dosage/i) && !exon.match?(/MLPA|P003/i)

              genes_found << find_genes_genotype(exon, moltesttype, genotype, genotype2)
            end
            genes_found.flatten.uniq
          end

          def find_genes_genotype(exon, moltesttype, genotype, genotype2)
            exon_genes = exon&.scan(COLORECTAL_GENES_REGEX).to_a
            genotype_genes = genotype&.scan(COLORECTAL_GENES_REGEX).to_a
            genotype2_genes = genotype2&.scan(COLORECTAL_GENES_REGEX).to_a
            if exon.match?('NGS')
              genotype == 'No pathogenic variant identified' ? exon_genes : genotype_genes
            elsif exon.match?(/P003/i) && moltesttype.match?(/dosage/i)
              %w[MLH1 MSH2] + [genotype_genes + genotype2_genes]
            elsif exon == 'MLH1_MSH2_MSH6_NGS-POOL' &&
                  genotype == 'No pathogenic variant identified'
              %w[MLH1 MSH2 MSH6]
            elsif exon_genes.size == 1
              exon_genes
            else # find genes in genotype or genotype2
              [genotype_genes + genotype2_genes + exon_genes]
            end
          end

          def get_genotype_column(rec, status)
            rec['genotype']&.match?(status) ? 'genotype' : 'genotype2'
          end

          def get_status_records(recs, status)
            recs.select do |rec|
              rec['genotype']&.match?(status) || rec['genotype2']&.match?(status)
            end
          end

          def process_status_recs(status_recs, status, genocolorectal, genocolorectals)
            status_recs&.each do |status_rec|
              genotype_column = get_genotype_column(status_rec, status)
              process_genotypes(status_rec, genotype_column, genocolorectal, genocolorectals)
            end
          end

          def get_gene_seprated_array(genes_present, rec, genotype_column)
            genotype_arr = []
            raw_genotype = rec[genotype_column]
            begin
              if genes_present.size > 1
                genes_present.reverse_each do |gene|
                  raw_genotype_split = raw_genotype.split(gene)
                  genotype_arr << (gene + raw_genotype_split[-1])
                  raw_genotype = raw_genotype_split[0]
                end
              else
                genotype_arr = [raw_genotype]
              end
            rescue StandardError
              # will try to seperate differently via seperator
              # rare record cases (rep same gene) which can't be seperated by gene
              seperator = raw_genotype.match(/,|;|AND/i) ? $LAST_MATCH_INFO[0] : nil
              genotype_arr = seperator.present? ? raw_genotype.split(seperator) : [raw_genotype]
            end
            genotype_arr
          end

          def do_not_import(record)
            record.raw_fields.reject! do |raw_record|
              control_sample?(raw_record) ||
                rejected_consultant?(raw_record) ||
                rejected_moltesttype?(raw_record) ||
                rejected_providercode?(raw_record) ||
                rejected_genotype?(raw_record) ||
                rejected_exon?(raw_record)
            end
          end
        end
      end
    end
  end
end
