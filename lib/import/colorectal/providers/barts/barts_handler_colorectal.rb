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
            add_genetictestscope(genocolorectal, record)
            genocolorectal.add_status(2)
            @persister.integrate_and_store(genocolorectal)
          end

          def add_genetictestscope(genocolorectal, record)
            testscope = record.raw_fields['testscope']&.downcase&.strip
            scope = case testscope
                    when 'predictive'
                      :targeted_mutation
                    when 'diagnostic'
                      :full_screen
                    else
                      :no_genetictestscope
                    end
            genocolorectal.add_test_scope(scope)
          end
        end
      end
    end
  end
end
