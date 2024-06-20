module Import
  module Colorectal
    module Providers
      module NhsEngland
        # Ad hoc Lynch patient data from registries (e.g. St. Mark's Bowel registry, CAPP2 cohort, National Lynch registry), uploaded using API pseudonymisation services to obtain identifiers for CAS linkage to lab germline data and NCRAS records.
        class AdhocHandlerColorectal < Import::Germline::ProviderHandler
          PASS_THROUGH_FIELDS = ['diagnostic lab', 'authoriseddate', 'gene', 'variantpathclass'].freeze
          CDNA_REGEX = /c\.(?<cdna>[\w+>*\-]+)?/ix
          PROTEIN_REGEX = /\(?p\.\(?(?<impact>\w+)\)?/ix
          EXON_VARIANT_REGEX = /(?<variant>del|dup|ins).+ex(on)?s?\s?
                                (?<exons>[0-9]+(-[0-9]+)?)|
                                ex(on)?s?\s?(?<exons>[0-9]+(-[0-9]+)?)\s?
                                (?<variant>del|dup|ins)|
                                ex(on)?s?\s?(?<exons>[0-9]+\s?(\s?-\s?[0-9]+)?)\s?
                                (?<variant>del|dup|ins)?|
                                (?<variant>del|dup|ins)\s?(?<exons>[0-9]+(?<dgs>-[0-9]+)?)|
                                ex(on)?s?\s?(?<exons>[0-9]+(\sto\s[0-9]+)?)\s
                                (?<variant>del|dup|ins)|
                                x(?<exons>[0-9+-? ]+)+(?<variant>del|dup|ins)|
                                ex(on)?s?[\s\w,]+(?<variant>del|dup|ins)|
                                (?<variant>del|dup|ins)[\s\w]+gene/ix

          def process_fields(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS)
            assign_variant_details(genocolorectal, record)
            @persister.integrate_and_store(genocolorectal)
          end

          def assign_variant_details(genocolorectal, record)
            variant = record.raw_fields['variant']

            process_cdna_variant(genocolorectal, variant)
            process_protein_impact(genocolorectal, variant)
            process_exonic_variant(genocolorectal, variant)
          end

          def process_exonic_variant(genocolorectal, variant)
            return unless variant&.scan(EXON_VARIANT_REGEX)&.size&.positive?

            genocolorectal.add_exon_location($LAST_MATCH_INFO[:exons])
            genocolorectal.add_variant_type($LAST_MATCH_INFO[:variant])
            @logger.debug "SUCCESSFUL exon variant parse for: #{variant}"
          end

          def process_cdna_variant(genocolorectal, variant)
            return unless variant&.scan(CDNA_REGEX)&.size&.positive?

            genocolorectal.add_gene_location($LAST_MATCH_INFO[:cdna])
            @logger.debug "SUCCESSFUL cdna change parse for: #{$LAST_MATCH_INFO[:cdna]}"
          end

          def process_protein_impact(genocolorectal, variant)
            if variant&.scan(PROTEIN_REGEX)&.size&.positive?
              genocolorectal.add_protein_impact($LAST_MATCH_INFO[:impact])
              @logger.debug "SUCCESSFUL protein parse for: #{$LAST_MATCH_INFO[:impact]}"
            else
              @logger.debug "FAILED protein parse for: #{variant}"
            end
          end
        end
      end
    end
  end
end
