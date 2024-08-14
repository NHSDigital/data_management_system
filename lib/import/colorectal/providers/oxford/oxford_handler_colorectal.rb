module Import
  module Colorectal
    module Providers
      module Oxford
        # Process Oxford-specific record details into generalized internal genotype format
        class OxfordHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rth::Constants

          def process_fields(record)
            @file_name = @batch.original_filename

            return if @files_not_to_process.include? @file_name

            if @files_to_process.include?(@file_name) || colorectal_file?
              @files_to_process << @file_name unless @files_to_process.include?(@file_name)
              prepare_genotypes(record)
            else
              @files_not_to_process << @file_name
            end
          end

          def prepare_genotypes(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS)
            assign_method(genocolorectal, record)
            assign_test_scope(genocolorectal, record)
            assign_test_type(genocolorectal, record)
            assign_genomic_change(genocolorectal, record)
            assign_servicereportidentifier(genocolorectal, record)
            assign_variantpathclass(genocolorectal, record)
            add_organisationcode_testresult(genocolorectal)
            res = process_records(genocolorectal, record)
            res.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def colorectal_file?
            file_name = @batch.original_filename
            file_path = File.dirname(file_name)
            file_path_array = file_name.split('/')
            pseudo_file = file_path_array[file_path_array.length - 1]
            pseudo_filename = pseudo_file.sub(/.xls[x]?.pseudo/, '')
            directory = Rails.root.join("private/pseudonymised_data/#{file_path}").to_s
            csv_files = Dir.glob("#{directory}/*#{pseudo_filename}*_pretty.csv")

            raise "Pretty CSV file not able to map for #{pseudo_file}" if csv_files.empty?

            csv = CSV.read(csv_files[0], headers: true)
            brca1_count, apc_count, mlh1_count = get_csv_counts(csv)

            mlh1_count + apc_count > brca1_count
          end

          def get_csv_counts(csv)
            gene_tally  = csv['mapped:gene'].tally
            brca1_count = gene_tally['7'].to_i
            apc_count = gene_tally['358'].to_i
            mlh1_count = gene_tally['2744'].to_i
            [brca1_count, apc_count, mlh1_count]
          end

          def add_organisationcode_testresult(genocolorectal)
            genocolorectal.attribute_map['organisationcode_testresult'] = '698C0'
          end

          def assign_method(genocolorectal, record)
            Maybe(record.raw_fields['karyotypingmethod']).each do |raw_method|
              method = TEST_METHOD_MAP[raw_method]
              if method
                genocolorectal.add_method(method)
              else
                @logger.warn "Unknown method: #{raw_method}; possibly need to update map"
              end
            end
          end

          def assign_test_type(genocolorectal, record)
            Maybe(record.raw_fields['moleculartestingtype']).each do |ttype|
              if ttype.downcase != 'diagnostic' && ttype.downcase != 'confirmatory'
                @logger.warn "Oxford provided test type: #{ttype}; expected" \
                             'diagnostic only'
              end
              genocolorectal.add_molecular_testing_type_strict(ttype)
            end
          end

          def assign_variantpathclass(genocolorectal, record)
            return if record.mapped_fields['variantpathclass'].nil?

            varpathclass = record.mapped_fields['variantpathclass']&.downcase
            varpath = varpathclass.to_i
            if varpath.positive? && varpath <= 5
              # we have right varpath to be assigned
            else
              varpath = VAR_PATH_CLASS_MAP[varpathclass]
            end
            genocolorectal.add_variant_class(varpath) if varpath.present?
          end

          def assign_servicereportidentifier(genocolorectal, record)
            if record.raw_fields['investigationid']
              genocolorectal.attribute_map['servicereportidentifier'] =
                record.raw_fields['investigationid']
            else
              @logger.debug 'Servicereportidentifier missing for this record'
            end
          end

          def assign_test_scope(genocolorectal, record)
            Maybe(record.raw_fields['scope / limitations of test']).each do |ttype|
              if ashkenazi?(ttype)
                genocolorectal.add_test_scope(:aj_screen)
              elsif polish?(ttype)
                genocolorectal.add_test_scope(:polish_screen)
              elsif targeted?(ttype)
                genocolorectal.add_test_scope(:targeted_mutation)
              elsif full_screen?(ttype)
                genocolorectal.add_test_scope(:full_screen)
              else
                genocolorectal.add_test_scope(:no_genetictestscope)
              end
            end
          end

          def ashkenazi?(scopecolumn)
            scopecolumn.match(/ashkenazi/i)
          end

          def polish?(scopecolumn)
            scopecolumn.match(/polish/i)
          end

          def targeted?(scopecolumn)
            scopecolumn.match(/targeted|Familial/i)
          end

          def full_screen?(scopecolumn)
            FULL_SCREEN_REGEX.match(scopecolumn)
          end

          def process_cdna_change(record, genocolorectal, genotypes)
            cdna             = record.raw_fields['codingdnasequencechange']
            cdna_match       = CDNA_REGEX.match(cdna)
            chromosome_match = CHROMOSOME_VARIANT_REGEX.match(cdna)
            if cdna_match
              process_cdna_match(genocolorectal, genotypes, cdna_match)
            elsif chromosome_match
              process_chromosome_variant(genocolorectal, genotypes, chromosome_match)
            else
              genocolorectal.add_status(1)
              genotypes.append(genocolorectal)
              @logger.debug 'FAILED cdna change parse'
            end
          end

          def process_cdna_match(genocolorectal, genotypes, cdna_match)
            genocolorectal.add_gene_location(cdna_match[:cdna])
            genocolorectal.add_status(2)
            genotypes.append(genocolorectal)
            @logger.debug "SUCCESSFUL cdna change parse for: #{cdna_match[:cdna]}"
          end

          def process_chromosome_variant(genocolorectal, genotypes, chromosome_match)
            genocolorectal.add_variant_type(chromosome_match[:chromvar])
            genocolorectal.add_status(2)
            genotypes.append(genocolorectal)
            @logger.debug 'SUCCESSFUL chromosomal variant parse for: ' \
                          "#{chromosome_match[:chromvar]}"
          end

          def process_protein_impact(record, genocolorectal, genotypes)
            protein = record.raw_fields['proteinimpact']
            if PROTEIN_REGEX.match(protein)
              genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
              genotypes.append(genocolorectal)
              @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug 'FAILED protein change parse'
            end
          end

          def process_gene(record, genocolorectal, genotypes)
            gene = record.raw_fields['gene'] unless record.raw_fields['gene'].nil?
            if COLORECTAL_GENES_REGEX.match(gene.upcase)
              genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
              genotypes.append(genocolorectal)
              @logger.debug "SUCCESSFUL gene parse for: #{gene}"
            else
              @logger.debug 'Failed gene parse'
            end
          end

          def process_records(genocolorectal, record)
            genotypes = []
            if COLORECTAL_GENES_REGEX.match(record.raw_fields['gene'].upcase)
              process_gene(record, genocolorectal, genotypes)
              process_cdna_change(record, genocolorectal, genotypes)
              process_protein_impact(record, genocolorectal, genotypes)
            end
            genotypes
          end

          def assign_genomic_change(genocolorectal, record)
            Maybe(record.raw_fields['genomicchange']).each do |raw_change|
              if GENOMICCHANGE_REGEX.match(raw_change)
                genocolorectal.add_genome_build($LAST_MATCH_INFO[:genome_build].to_i)
                genocolorectal.add_parsed_genomic_change($LAST_MATCH_INFO[:chromosome],
                                                         $LAST_MATCH_INFO[:effect])
              elsif /Normal/i.match(raw_change)
                genocolorectal.add_status(1)
              else
                @logger.warn "Could not process, so adding raw genomic change: #{raw_change}"
              end
            end
          end
        end
      end
    end
  end
end
