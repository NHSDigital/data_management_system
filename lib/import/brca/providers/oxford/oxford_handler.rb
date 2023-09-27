module Import
  module Brca
    module Providers
      module Oxford
        # Process Oxford-specific record details into generalized internal genotype format
        class OxfordHandler < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rth::Constants

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            assign_test_scope(genotype, record)
            variantpathclass = extract_variantpathclass(genotype, record)
            assign_test_type(genotype, record)
            process_variants(genotype, record, variantpathclass)
            process_protein_impact(genotype, record)
            assign_genomic_change(genotype, record)
            assign_servicereportidentifier(genotype, record)
            add_organisationcode_testresult(genotype)
            res = process_gene(genotype, record)
            res&.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '698C0'
          end

          def assign_test_type(genotype, record)
            return if record.raw_fields['moleculartestingtype'].nil?

            if record.raw_fields['moleculartestingtype'] == 'pre-symptomatic'
              genotype.add_molecular_testing_type('predictive')
            else
              genotype.add_molecular_testing_type('diagnostic')
            end
          end

          def assign_servicereportidentifier(genotype, record)
            if record.raw_fields['investigationid']
              genotype.attribute_map['servicereportidentifier'] =
                record.raw_fields['investigationid']
            else
              @logger.debug 'Servicereportidentifier missing for this record'
            end
          end

          def assign_test_scope(genotype, record)
            if ashkenazi?(record)
              genotype.add_test_scope(:aj_screen)
            elsif polish?(record)
              genotype.add_test_scope(:polish_screen)
            elsif targeted?(record)
              genotype.add_test_scope(:targeted_mutation)
            elsif full_screen?(record)
              genotype.add_test_scope(:full_screen)
            elsif null_testscope?(record)
              targeted_scope_from_nullscope(genotype, record)
            else
              genotype.add_test_scope(:no_genetictestscope)
            end
          end

          def process_variants(genotype, record, variantpathclass)
            return if record.mapped_fields['codingdnasequencechange'].nil?

            if CDNA_REGEX.match(record.mapped_fields['codingdnasequencechange'])
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              non_pathogenic_variant?(genotype, variantpathclass)
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            elsif EXON_REGEX.match(record.mapped_fields['codingdnasequencechange'])
              # genotype.add_variant_type($LAST_MATCH_INFO[:variant])
              # genotype.add_exon_location($LAST_MATCH_INFO[:location])
              # genotype.add_status(2)
              add_exonic_variant(record, genotype, variantpathclass)
            elsif normal?(record)
              genotype.add_status(1)
            elsif RECORD_EXEMPTIONS.include? record.mapped_fields['codingdnasequencechange']
              extract_exemptions_from_record(genotype, record, variantpathclass)
            else
              @logger.debug 'FAILED cdna change parse'
            end
          end

          def non_pathogenic_variant?(genotype, variantpathclass)
            if [1, 2].include?(variantpathclass)
              genotype.add_status(10)
            else
              genotype.add_status(2)
            end
          end

          def process_protein_impact(genotype, record)
            case record.raw_fields['proteinimpact']
            when PROTEIN_REGEX
              genotype.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug 'FAILED protein change parse'
            end
          end

          def process_gene(genotype, record)
            genotypes = []
            gene      = record.mapped_fields['gene'].to_i
            synonym   = record.raw_fields['sinonym'].to_s
            if [7, 8, 79, 865, 3186, 2744, 2804, 3394, 62, 76,
                590, 3615, 3616, 20, 18].include? gene
              add_oxford_gene(gene, genotype, genotypes)
            elsif BRCA_REGEX.match(synonym)
              add_oxford_gene(BRCA_REGEX.match(synonym)[:brca], genotype, genotypes)
            else
              @logger.debug 'FAILED gene parse'
            end
            genotypes
          end

          def assign_genomic_change(genotype, record)
            Maybe(record.raw_fields['genomicchange']).each do |raw_change|
              if GENOMICCHANGE_REGEX.match(raw_change)
                genotype.add_genome_build($LAST_MATCH_INFO[:genome_build].to_i)
                genotype.add_parsed_genomic_change($LAST_MATCH_INFO[:chromosome],
                                                   $LAST_MATCH_INFO[:effect])
              elsif /Normal/i.match(raw_change)
                genotype.add_status(1)
              else
                @logger.warn "Could not process, so adding raw genomic change: #{raw_change}"
              end
            end
          end

          def normal?(record)
            return false if record.mapped_fields['codingdnasequencechange'].nil?

            record.mapped_fields['codingdnasequencechange'].scan(%r{N/A|normal}i).size.positive?
          end

          def full_screen?(record)
            return false if record.raw_fields['scope / limitations of test'].nil?

            geneticscope = record.raw_fields['scope / limitations of test']
            geneticscope.scan(/panel|scree(n|m)|brca|hcs|panel/i).size.positive?
          end

          def targeted?(record)
            return false if record.raw_fields['scope / limitations of test'].nil?

            geneticscope = record.raw_fields['scope / limitations of test']
            geneticscope.scan(/targeted|proband/i).size.positive?
          end

          def ashkenazi?(record)
            return false if record.raw_fields['scope / limitations of test'].nil?

            geneticscope = record.raw_fields['scope / limitations of test']
            geneticscope.scan(/ashkenazi/i).size.positive?
          end

          def polish?(record)
            return false if record.raw_fields['scope / limitations of test'].nil?

            geneticscope = record.raw_fields['scope / limitations of test']
            geneticscope.scan(/polish/i).size.positive?
          end

          def null_testscope?(record)
            geneticscope = record.raw_fields['scope / limitations of test']
            geneticscope.nil?
          end

          def add_exonic_variant(record, genotype, variantpathclass)
            return if record.raw_fields['scope / limitations of test'].nil?

            exon_info = record.mapped_fields['codingdnasequencechange']
            genotype.add_variant_type(EXON_REGEX.match(exon_info)[:variant])
            genotype.add_exon_location(EXON_REGEX.match(exon_info)[:location])
            non_pathogenic_variant?(genotype, variantpathclass)
          end

          def targeted_scope_from_nullscope(genotype, record)
            return if record.raw_fields['moleculartestingtype'].nil?

            testtype = record.raw_fields['moleculartestingtype']
            if testtype.scan(/symptomatic/i).size.positive?
              genotype.add_test_scope(:targeted_mutation)
            elsif testtype.scan(/diagnostic/i).size.positive?
              genotype.add_test_scope(:full_screen)
            end
          end

          def extract_exemptions_from_record(genotype, record, variantpathclass)
            return if record.mapped_fields['codingdnasequencechange'].nil?

            exemptions = record.mapped_fields['codingdnasequencechange']
            if exemptions.scan('c.').size.positive?
              genotype.add_gene_location(exemptions.gsub(/[\[\]+=]+/, ''))
              non_pathogenic_variant?(genotype, variantpathclass)
            elsif exemptions.scan(/(?<delinsdup>del|ins|dup)/i).size.positive?
              genotype.add_variant_type($LAST_MATCH_INFO[:delinsdup])
              if exemptions.scan(/(?<exno>[0-9]+-[0-9]+)/i).size.positive?
                genotype.add_exon_location($LAST_MATCH_INFO[:exno])
              end
              non_pathogenic_variant?(genotype, variantpathclass)
            end
            genotype
          end

          def add_oxford_gene(genevalue, genotype, genotypes)
            genotype.add_gene(genevalue)
            @logger.debug "SUCCESSFUL gene parse for:#{genevalue}"
            genotypes << genotype
          end

          def extract_variantpathclass(genotype, record)
            return if record.mapped_fields['variantpathclass'].nil?

            varpathclass = record.mapped_fields['variantpathclass']&.downcase
            varpath = varpathclass.to_i
            if varpath.positive? && varpath <= 5
              # we have right varpath to be assigned
            else
              varpath = VAR_PATH_CLASS_MAP[varpathclass]
            end
            genotype.add_variant_class(varpath)
          end
        end
      end
    end
  end
end
