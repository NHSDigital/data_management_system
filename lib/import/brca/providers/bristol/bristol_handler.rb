module Import
  module Brca
    module Providers
      module Bristol
        # Process Bristol-specific record details into generalized internal genotype format
        class BristolHandler < Import::Germline::ProviderHandler
          include Import::Helpers::Brca::Providers::Rvj::RvjConstants

          def process_fields(record)
            genotype = Import::Brca::Core::GenotypeBrca.new(record)
            genotype.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            PASS_THROUGH_FIELDS)
            add_organisationcode_testresult(genotype)
            genotype.add_test_scope(:full_screen)
            genotype.add_received_date(record.raw_fields['received date'])
            genotype.add_method('ngs')
            res = process_gene(genotype, record)
            res&.each { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def add_organisationcode_testresult(genotype)
            genotype.attribute_map['organisationcode_testresult'] = '698V0'
          end

          def process_negative_record(genotype, negative_gene, genotypes)
            duplicated_genotype = genotype.dup
            duplicated_genotype.add_gene(negative_gene.join)
            duplicated_genotype.add_status(1)
            genotypes.append(duplicated_genotype)
          end

          def process_positive_record(genotype, positive_gene, record, genotypes)
            process_cdna_change(genotype, record)
            add_protein_impact(genotype, record)
            genotype.add_variant_class(record.mapped_fields['variantpathclass'])
            process_genomic_change(genotype, record)
            process_test_status(genotype, record)
            genotype.add_gene(positive_gene)
            genotypes.append(genotype)
          end

          def process_gene(genotype, record)
            return if record.raw_fields['gene'].nil?

            positive_raw_gene = record.raw_fields['gene']
            genotypes = []
            negative_gene = %w[BRCA1 BRCA2] - [positive_raw_gene]
            process_negative_record(genotype, negative_gene, genotypes)
            process_positive_record(genotype, positive_raw_gene, record, genotypes)
          end

          def process_test_status(genotype, record)
            return if record.raw_fields['variantpathclass'].nil?

            varpathclass_field = record.raw_fields['variantpathclass']
            genotype.add_status(TESTSTATUS_MAP[varpathclass_field]) if TESTSTATUS_MAP[varpathclass_field].present?
          end

          def process_cdna_change(genotype, record)
            case record.mapped_fields['codingdnasequencechange']
            when CDNA_REGEX
              genotype.add_gene_location($LAST_MATCH_INFO[:cdna])
              @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
            else
              @logger.debug 'UNSUCCESSFUL cdna change parse'
            end
          end

          # rubocop:disable Style/GuardClause
          def add_protein_impact(genotype, record)
            return if record.mapped_fields['proteinimpact'].nil?

            proteinfield = record.mapped_fields['proteinimpact']
            if proteinfield.scan(PROTEIN_REGEX).presence
              genotype.add_protein_impact(proteinfield.match(PROTEIN_REGEX)[:impact])
            end
          end
          # rubocop:enable Style/GuardClause

          def process_genomic_change(genotype, record)
            gchange = record.raw_fields['genomicchange']
            return if gchange.nil?

            case gchange
            when /(?<chr_num>\d+):(?<g_num>\d+)/
              genotype.add_parsed_genomic_change($LAST_MATCH_INFO[:chr_num],
                                                 $LAST_MATCH_INFO[:g_num])
            else
              @logger.warn "Could not process genomic change, adding raw: #{gchange}"
              genotype.add_raw_genomic_change(gchange)
            end
          end
        end
      end
    end
  end
end
