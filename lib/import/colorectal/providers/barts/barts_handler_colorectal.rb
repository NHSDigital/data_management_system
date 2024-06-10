module Import
  module Colorectal
    module Providers
      module Barts
        # Handler to import Lynch data for Cassie
        class BartsHandlerColorectal < Import::Germline::ProviderHandler
          PASS_THROUGH_FIELDS = %w[authoriseddate codingdnasequencechange gene sex
                                   proteinimpact variantpathclass consultantname].freeze

          def process_fields(record)
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS)
            @persister.integrate_and_store(genocolorectal)
          end

        end
      end
    end
  end
end
