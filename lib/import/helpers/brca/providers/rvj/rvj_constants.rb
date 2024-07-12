module Import
  module Helpers
    module Brca
      module Providers
        module Rvj
          # Constants used by Bristol BRCA Handler
          module RvjConstants
            PASS_THROUGH_FIELDS = %w[age consultantcode
                                     servicereportidentifier
                                     providercode
                                     authoriseddate
                                     requesteddate
                                     practitionercode
                                     geneticaberrationtype].freeze
            CDNA_REGEX = /c\.(?<cdna>[0-9]+[^\s|^, ]+)/
            PROTEIN_REGEX = /p.\(?(?<impact>.*)\)?/

            TESTSTATUS_MAP = { 'Benign' => 10,
                               'Likely Benign' => 10,
                               'Deleterious' => :positive,
                               'Likely Deleterious' => :positive,
                               'Likely Pathogenic' => :positive,
                               'Pathogenic' => :positive,
                               'Unknown' => :positive }.freeze

            VARPATH_MAP = { 'Benign' => 1,
                            'Likely Benign' => 2,
                            'Deleterious' => 5,
                            'Likely Deleterious' => 4,
                            'Likely Pathogenic' => 4,
                            'Pathogenic' => 5,
                            'Unknown' => 3 }.freeze
          end
        end
      end
    end
  end
end
