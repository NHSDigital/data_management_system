module Import
  module Helpers
    module Colorectal
      module Providers
        module R0a
          # Processing methods used by ManchesterHandlerColorectal
          module R0aHelper
            include Import::Helpers::Colorectal::Providers::R0a::R0aConstants

            def add_organisationcode_testresult(genocolorectal)
              genocolorectal.attribute_map['organisationcode_testresult'] = '69820'
            end

            def add_servicereportidentifier(genocolorectal, record)
              servicereportidentifiers = []
              record.raw_fields.each do |records|
                servicereportidentifiers << records['servicereportidentifier']
              end
              servicereportidentifier = servicereportidentifiers.flatten.uniq.join
              genocolorectal.attribute_map['servicereportidentifier'] = servicereportidentifier
            end

            def rejected_moltesttype?(raw_record)
              DO_NOT_IMPORT.include? raw_record['moleculartestingtype']&.upcase
            end

            def rejected_consultant?(raw_record)
              ['DR SANDI DEANS', 'DR EQA'].include? raw_record['consultantname'].to_s.upcase
            end

            def control_sample?(raw_record)
              raw_record['genocomm'] =~ /\s(control|ctrl|tumour|NC)\s/i
            end

            def rejected_providercode?(raw_record)
              raw_record['providercode'] =~ /GenQA/i
            end

            def rejected_genotype?(raw_record)
              %w[NC nc].include? raw_record['genotype']
            end

            def rejected_exon?(raw_record)
              raw_record['exon'] =~ /normal\scontrol|QF\sPCR|PowerPlex\s16/i
            end

            def positive_cdna?(genotype_string)
              return false if genotype_string.nil?

              genotype_string.scan(CDNA_REGEX).size.positive?
            end

            def positive_exonvariant?(genotype_string)
              return false if genotype_string.nil?

              genotype_string.scan(EXON_LOCATION_REGEX).size.positive? &&
                EXON_REGEX.match(genotype_string)
            end

            def process_cdna_change(genocolorectal, group_genotype_str)
              case group_genotype_str
              when CDNA_REGEX
                genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
                @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
                genocolorectal.add_status(:positive)
              else
                @logger.debug "FAILED cdna change parse for: #{group_genotype_str}"
              end
            end

            def process_protein_impact(genocolorectal, group_genotype_str)
              case group_genotype_str
              when PROT_REGEX
                genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
                genocolorectal.add_status(:positive)
                @logger.debug "SUCCESSFUL protein change parse for: #{$LAST_MATCH_INFO[:impact]}"
              else
                @logger.debug "FAILED protein change parse for: #{group_genotype_str}"
              end
            end

            def process_exons(genocolorectal, group_genotype_str)
              exon_locations = group_genotype_str.scan(EXON_LOCATION_REGEX)
              return if exon_locations.empty?

              genocolorectal.add_exon_location(exon_locations.flatten.compact.join('-'))
              genocolorectal.add_variant_type($LAST_MATCH_INFO[:mutationtype])
              @logger.debug "SUCCESSFUL exon extraction for: #{group_genotype_str}"
            end

            def mark_genes_normal(genocolorectal, genocolorectals)
              @genes.each do |gene|
                genocolorectal_dup = genocolorectal.dup_colo
                genocolorectal_dup.add_status(1)
                genocolorectal_dup.add_gene_colorectal(gene)
                genocolorectals << genocolorectal_dup
              end
            end

            def process_relevant_genes(relevant_genes, genocolorectal, genocolorectals, genotype)
              relevant_genes.each do |gene|
                genocolorectal_dup = genocolorectal.dup_colo
                process_cdna_change(genocolorectal_dup, genotype)
                process_protein_impact(genocolorectal_dup, genotype)
                process_exons(genocolorectal_dup, genotype)
                genocolorectal_dup.add_status(get_status(genotype))
                genocolorectal_dup.add_gene_colorectal(gene)
                genocolorectals << genocolorectal_dup
              end
            end

            def deduplicate_genocolorectals(genocolorectals)
              genocolorectals.each do |obj1|
                genocolorectals.each do |obj2|
                  if obj1 != obj2 && same_genocolorectal_object(obj1, obj2)
                    genocolorectals -= [obj1]
                  end
                end
              end
              genocolorectals
            end

            def same_genocolorectal_object(obj1, obj2)
              result = true
              obj1_cdna = obj1.attribute_map['codingdnasequencechange'].to_s
              if obj1_cdna.include? obj2.attribute_map['codingdnasequencechange'].to_s
                %w[gene teststatus genetictestscope exonintroncodonnumber].each do |attribute|
                  unless obj1.attribute_map[attribute] == obj2.attribute_map[attribute]
                    result = false
                    break
                  end
                end
              else
                result = false
              end
              result
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
