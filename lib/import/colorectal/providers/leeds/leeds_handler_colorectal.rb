module Import
  module Colorectal
    module Providers
      module Leeds
        # Leeds importer for colorectal
        class LeedsHandlerColorectal < Import::Germline::ProviderHandler
          include Import::Helpers::Colorectal::Providers::Rr8::Constants

          def initialize(batch)
            @negative_test = 0
            @positive_test = 0
            super
          end

          def process_fields(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS,
                                                  FIELD_NAME_MAPPINGS)
            process_scope(genocolorectal, record)
            add_positive_teststatus(genocolorectal, record)
            failed_teststatus(genocolorectal, record)
            add_benign_varclass(genocolorectal, record)
            genocolorectal.attribute_map['organisationcode_testresult'] = '699C0'

            res = add_gene_from_report(genocolorectal, record) # Added by Francesco
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def process_scope(genocolorectal, record)
            add_scope_and_type_from_genotype(genocolorectal, record)
            add_scope_type_from_moleculartesting(genocolorectal, record)
            return unless genocolorectal.attribute_map['genetictestscope'].nil?

            genocolorectal.add_test_scope(:no_genetictestscope)
          end

          def add_positive_teststatus(genocolorectal, record)
            rawgenotype = record.raw_fields['genotype']
            case rawgenotype
            when /MLPA pred negative/, /pred (other) negative/, /seq 1-12, MLPA normal/,
                /pred complex mut -ve/, /Pred seq -ve (APC)/, /MLPA conf -ve/,
                /MLPA -ve + Seq (unknown variant)/, /NGS MSH2,MLH1,MSH6 normal/,
                /No mutation identified/, /Pred seq MSH2 -ve/, /Confirmation neg/,
                /Pred MLPA EPCAM del -ve/
              genocolorectal.add_status(:negative)
              @logger.debug "NEGATIVE status for : #{record.raw_fields['genotype']}"
            else
              @logger.debug 'Cannot determine test status for : '\
                            "#{record.raw_fields['genotype']} a priori"
            end
          end

          def failed_teststatus(genocolorectal, record)
            rawgenotype = record.raw_fields['report']
            if /No results were obtained from this sample/.match(rawgenotype)
              genocolorectal.add_status(:failed)
            else
              @logger.debug 'Cannot determine test status for : '\
                            "#{record.raw_fields['report']} a priori"
            end
          end

          def add_benign_varclass(genocolorectal, record)
            rawgenotype = record.raw_fields['genotype']
            rawreport = record.raw_fields['report']
            if /Class 2/i.match(rawgenotype) ||
               /benign/.match(rawgenotype) ||
               /Evaluation of the available evidence suggests that this variant is
                likely to be benign/ix.match(rawreport)
              genocolorectal.add_variant_class(2)
            end
          end

          def add_gene_from_report(genocolorectal, record)
            genetictestscope = genocolorectal.attribute_map['genetictestscope']
            rawreport = record.raw_fields['report']
            genotypes = []
            geni = rawreport&.scan(COLORECTAL_GENES_REGEX)
            if rawreport&.scan(COLORECTAL_GENES_REGEX).nil?
              genocolorectal.add_gene_colorectal(nil)
              genocolorectal.add_protein_impact(nil)
              genocolorectal.add_gene_location(nil)
              @logger.debug "EMPTY REPORT FOR #{rawreport}"
              genotypes.append(genocolorectal)
            elsif geni.uniq.length > 1
              if PATH_TWOGENES_VARIANTS.match(rawreport)
                genocolorectal2 = genocolorectal.dup_colo
                neg_genes = geni - [[PATH_TWOGENES_VARIANTS.match(rawreport)[:genes]],
                                    [PATH_TWOGENES_VARIANTS.match(rawreport)[:genes2]]]

                process_negative_genes(neg_genes, genocolorectal, genotypes)
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                genotypes.append(genocolorectal)
                genocolorectal2.add_gene_colorectal($LAST_MATCH_INFO[:genes2])
                genocolorectal2.add_gene_location($LAST_MATCH_INFO[:cdna2])
                genotypes.append(genocolorectal2)
                genotypes
              elsif record.raw_fields['genotype'] == 'MLH1 only -ve'
                genocolorectal.add_status(1)
                genocolorectal.add_gene_colorectal('MLH1')
                genotypes << genocolorectal
              elsif record.raw_fields['genotype'] == 'MSH2 only -ve'
                genocolorectal.add_status(1)
                genocolorectal.add_gene_colorectal('MSH2')
                genotypes << genocolorectal
              elsif record.raw_fields['genotype'] == 'FAP diagn -ve' ||
                    record.raw_fields['genotype'] == 'Normal' ||
                    record.raw_fields['genotype'] == 'NGS MSH2,MLH1,MSH6 normal' ||
                    NOPATH_REGEX.match(rawreport) ||
                    ABSENT_REGEX.match(rawreport) ||
                    /No pathogenic/.match(rawreport)
                rawreport.scan(COLORECTAL_GENES_REGEX).each do |genes|
                  @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                  genocolorectal1 = genocolorectal.dup_colo
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes.join)
                  genotypes << genocolorectal1
                end
              elsif PATHVAR_EXONS_REGEX.match(rawreport)
                neg_genes = geni - [[PATHVAR_EXONS_REGEX.match(rawreport)[:genes]]]
                process_negative_genes(neg_genes, genocolorectal, genotypes)
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_exon_location($LAST_MATCH_INFO[:exons].delete(' '))
                genocolorectal.add_variant_type(rawreport)
                @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:genes]}"
                @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:exons]}"
                genotypes.append(genocolorectal)
              elsif PATHVAR_REGEX.match(rawreport)
                neg_genes = geni - [[PATHVAR_REGEX.match(rawreport)[:genes]]]
                process_negative_genes(neg_genes, genocolorectal, genotypes)
                add_details_from_last_match(genocolorectal, $LAST_MATCH_INFO)
                genotypes.append(genocolorectal)
              elsif PATHVAR_REGEX2.match(rawreport)
                neg_genes = geni - [[PATHVAR_REGEX2.match(rawreport)[:genes]]]
                process_negative_genes(neg_genes, genocolorectal, genotypes)
                add_details_from_last_match(genocolorectal, $LAST_MATCH_INFO)
                genotypes.append(genocolorectal)
              elsif EXON_ALTERNATIVE_REGEX.match(rawreport)
                neg_genes = geni - [[EXON_ALTERNATIVE_REGEX.match(rawreport)[:genes]]]
                process_negative_genes(neg_genes, genocolorectal, genotypes)
                genocolorectal.add_gene_colorectal(EXON_ALTERNATIVE_REGEX.match(rawreport)[:genes])
                genocolorectal.add_exon_location(EXON_ALTERNATIVE_REGEX.match(rawreport)[:exons])
                @logger.debug 'SUCCESSFUL gene parse for: '\
                              "#{EXON_ALTERNATIVE_REGEX.match(rawreport)[:genes]}"
                genotypes.append(genocolorectal)
              elsif PATHVAR_TWOGENES_REGEX.match(rawreport)
                genocolorectal2 = genocolorectal.dup_colo
                neg_genes = geni - [[PATHVAR_REGEX.match(rawreport)[:genes]]]
                process_negative_genes(neg_genes, genocolorectal, genotypes)
                add_details_from_last_match(genocolorectal, $LAST_MATCH_INFO)
                genotypes.append(genocolorectal)
                genocolorectal2.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal2.add_protein_impact($LAST_MATCH_INFO[:impact2])
                genocolorectal2.add_gene_location($LAST_MATCH_INFO[:cdna2])
                genotypes.append(genocolorectal2)
                @logger.debug "MULTIPLE LIST IDOUBLE GENE VARIANT #{rawreport}"
              end
              genotypes
            elsif PATHVAR_TWOGENES_REGEX.match(rawreport)
              genocolorectal1 = genocolorectal.dup_colo
              add_details_from_last_match(genocolorectal, $LAST_MATCH_INFO)
              genotypes.append(genocolorectal)
              genocolorectal1.add_gene_colorectal($LAST_MATCH_INFO[:genes])
              genocolorectal1.add_protein_impact($LAST_MATCH_INFO[:impact2])
              genocolorectal1.add_gene_location($LAST_MATCH_INFO[:cdna2])
              genotypes.append(genocolorectal1)
              @logger.debug "DOUBLE GENE #{rawreport}"
            elsif geni.uniq.length == 1
              if record.raw_fields['genotype'] == 'Pred seq -ve (APC)' ||
                 record.raw_fields['genotype'] == 'Pred seq MSH2 -ve' ||
                 record.raw_fields['genotype'] == 'MLPA conf -ve' ||
                 record.raw_fields['genotype'] == 'Seq pred negative' ||
                 record.raw_fields['genotype'] == 'pred (other) negative' ||
                 record.raw_fields['genotype'] == 'conf seq -ve' ||
                 record.raw_fields['genotype'] == 'pred complex mut -ve' ||
                 record.raw_fields['genotype'] == 'Pred MLPA EPCAM del -ve' ||
                 record.raw_fields['genotype'] == 'FAP pred -ve (APC)' ||
                 record.raw_fields['genotype'] == 'Diagnostic APC -ve' ||
                 record.raw_fields['genotype'] == 'Seq/MLPA_diagnostic_negative' ||
                 record.raw_fields['genotype'] == 'MLH1 only -ve' ||
                 record.raw_fields['genotype'] == 'No mutation identified'
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
              elsif (ABSENT_REGEX.match(rawreport) || NOPATH_REGEX.match(rawreport) ||
                    NOPATH_SINGLEGENE.match(rawreport) || /No pathogenic/.match(rawreport)) &&
                    PATHVAR_REGEX.match(rawreport)
                case genetictestscope
                when 'Full screen Colorectal Lynch or MMR'
                  add_details_from_last_match(genocolorectal, $LAST_MATCH_INFO)
                  genocolorectal.add_status(1)
                  @logger.debug "FOUND ABSENT VARIANT FOR : #{rawreport}"
                  genotypes << genocolorectal
                when 'Targeted Colorectal Lynch or MMR'
                  genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                  genocolorectal.add_protein_impact(nil)
                  genocolorectal.add_gene_location(nil)
                  genocolorectal.add_status(1)
                  @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:genes]}"
                  @logger.debug "FOUND ABSENT VARIANT FOR : #{rawreport}"
                  genotypes << genocolorectal
                end
              elsif ABSENT_REGEX.match(rawreport) ||
                    NOPATH_REGEX.match(rawreport) ||
                    NOPATH_SINGLEGENE.match(rawreport) ||
                    /No pathogenic/.match(rawreport)
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                @logger.debug 'SUCCESSFUL gene parse for:'\
                              " #{COLORECTAL_GENES_REGEX.match(rawreport)[0]}"
                @logger.debug "FOUND ABSENT VARIANT FOR : #{rawreport}"
                genotypes << genocolorectal
              elsif PATHVAR_REGEX.match(rawreport) ||
                    PATHVAR_REGEX2.match(rawreport)
                add_details_from_last_match(genocolorectal, $LAST_MATCH_INFO)
                genotypes << genocolorectal
              elsif PATHVAR_BIGINDELS.match(rawreport)
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:genes])
                genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:genes]}"
                @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
                genotypes << genocolorectal
              elsif  COLORECTAL_GENES_REGEX.match(rawreport) &&
                     EXON_LOCATION_REGEX.match(rawreport) &&
                     (NOMUT_REGEX.match(rawreport) || NO_DEL_REGEX.match(rawreport))
                case genetictestscope
                when 'Full screen Colorectal Lynch or MMR'
                  genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                  genocolorectal.add_exon_location(EXON_LOCATION_REGEX.match(rawreport)[1].
                                                   delete(' '))
                  genocolorectal.add_variant_type(rawreport)
                  genocolorectal.add_status(1)
                  genotypes.append(genocolorectal)
                when 'Targeted Colorectal Lynch or MMR'
                  genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                  genocolorectal.add_exon_location(nil)
                  genocolorectal.add_variant_type(nil)
                  genocolorectal.add_status(1)
                  genotypes.append(genocolorectal)
                end
              elsif ABSENT_REGEX.match(rawreport) && COLORECTAL_GENES_REGEX.match(rawreport)
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_status(1)
                genotypes.append(genocolorectal)
                @logger.debug "ABSENT MUTATION  #{rawreport}"
              elsif COLORECTAL_GENES_REGEX.match(rawreport) && EXON_LOCATION_REGEX.match(rawreport)
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
                genocolorectal.add_exon_location(EXON_LOCATION_REGEX.match(rawreport)[1].
                                                 delete(' '))
                genocolorectal.add_variant_type(rawreport)
                genotypes.append(genocolorectal)
              elsif /No pathogenic variant/i.match(rawreport) &&
                    COLORECTAL_GENES_REGEX.match(rawreport)
                genocolorectal.add_gene_colorectal($LAST_MATCH_INFO[:colorectal])
                genocolorectal.add_status(1)
                @logger.debug "SUCCESSFUL gene parse for: #{$LAST_MATCH_INFO[:colorectal]}"
                @logger.debug "FOUND ABSENT VARIANT FOR : #{rawreport}"
                genotypes << genocolorectal
              else
                @logger.debug "UNKNOWN SINGLE GENE GENOTYPE: #{rawreport}"
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(rawreport)[0])
              end
              genotypes
            else
              @logger.debug "UNKNOWN GENOTYPE for  #{rawreport}"
              genocolorectal.add_gene_colorectal(nil)
              genocolorectal.add_protein_impact(nil)
              genocolorectal.add_gene_location(nil)
              genotypes << genocolorectal
            end
            genotypes
          end

          def add_scope_and_type_from_genotype(genocolorectal, record)
            Maybe(record.raw_fields['genotype']).each do |typescopegeno|
              genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[typescopegeno])
              scope = TEST_SCOPE_MAP_COLO[typescopegeno]
              genocolorectal.add_test_scope(scope) if scope
            end
          end

          def add_scope_type_from_moleculartesting(genocolorectal, record)
            mtype = record.raw_fields['moleculartestingtype']&.downcase&.strip
            genocolorectal.add_molecular_testing_type_strict(TEST_TYPE_MAP_COLO[mtype]) \
                           unless mtype.nil?
            genocolorectal.add_test_scope(TEST_SCOPE_MAP_COLO[mtype]) \
                           unless mtype.nil?
          end

          def process_negative_genes(neg_genes, genocolorectal, genotypes)
            neg_genes.each do |genes|
              genocolorectal1 = genocolorectal.dup_colo
              @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
              genocolorectal1.add_status(1)
              genocolorectal1.add_gene_colorectal(genes.join)
              genocolorectal1.add_protein_impact(nil)
              genocolorectal1.add_gene_location(nil)
              genotypes.append(genocolorectal1)
            end
          end

          def add_details_from_last_match(genocolorectal, last_match_arr)
            genocolorectal.add_gene_colorectal(last_match_arr[:genes])
            genocolorectal.add_protein_impact(last_match_arr[:impact])
            genocolorectal.add_gene_location(last_match_arr[:cdna])
            @logger.debug "SUCCESSFUL gene parse for: #{last_match_arr[:genes]}"
            @logger.debug "SUCCESSFUL cdna change parse for: #{last_match_arr[:cdna]}"
            @logger.debug "SUCCESSFUL protein impact parse for: #{last_match_arr[:impact]}"
          end
        end
      end
    end
  end
end
