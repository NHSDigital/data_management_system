module Import
  module Helpers
    module Colorectal
      module Providers
        module Rx1
          # Constants used by NottinghamColorectal
          module Constants
            TEST_TYPE_MAP_COLO = { 'confirmation' => :diagnostic,
                                   'confirmation of familial mutation' => :diagnostic,
                                   'diagnostic' => :diagnostic,
                                   'family studies' => :predictive,
                                   'predictive' => :predictive,
                                   'indirect' => :predictive }.freeze

            PASS_THROUGH_FIELDS_COLO = %w[age authoriseddate
                                          receiveddate
                                          specimentype
                                          providercode
                                          consultantcode
                                          servicereportidentifier].freeze

            NEGATIVE_TEST = /Normal/i

            TEST_STATUS_MAP = { '1: Clearly not pathogenic' => 10,
                                '2: likely not pathogenic' => 10,
                                '2: likely not pathogenic variant' => 10,
                                'Class 2 Likely Neutral' => 10,
                                'Class 2 likely neutral variant' => 10,
                                '3: variant of unknown significance (VUS)' => 2,
                                '4: likely pathogenic' => 2,
                                '4:likely pathogenic' => 2,
                                '4: Likely Pathogenic' => 2,
                                '5: clearly pathogenic' => 2,
                                'Mutation identified' => 2,
                                'VUS' => 2,
                                'Fail' => 9 }.freeze

            COLORECTAL_GENES_REGEX = /(?<colorectal>APC|
                                                  BMPR1A|
                                                  EPCAM|
                                                  MLH1|
                                                  MSH2|
                                                  MSH6|
                                                  MUTYH|
                                                  PMS2|
                                                  POLD1|
                                                  POLE|
                                                  PTEN|
                                                  SMAD4|
                                                  STK11)/xi
            VARPATHCLASS_REGEX = /(?<varpathclass>[0-9](?=:))/

            CDNA_REGEX = /c\.(?<cdna>[0-9]+[A-Za-z]+>[A-Za-z]+)|
                          c\.(?<cdna>[0-9]+.(?:[0-9]+)[A-Za-z]+>[A-Z]+)|
                          c\.(?<cdna>[0-9]+.[0-9].[0-9]+.[0-9][A-Za-z]+)|
                          c\.(?<cdna>[0-9]+[A-Za-z]+)|
                          c\.(?<cdna>[0-9]+.[0-9]+[A-Za-z]+)|
                          c\.(?<cdna>.[0-9]+[A-Za-z]+>[A-Za-z]+)|
                          c\.(?<cdna>.[\W][0-9]+[\W]+[0-9]+[a-z]+)/ix

            ADHOC_CDNA_REGEX = /c\.(?<cdna>[\W][0-9]+..[0-9]+[a-z]+)|
                                c\.(?<cdna>[\W][0-9]+[a-z]+)|
                                c\.(?<cdna>[0-9]+.[0-9]+.[0-9]+.[0-9]+[a-z]+)/xi

            SPACE_CDNA_REGEX = /c\.(?<cdna>.+\s[A-Z]>[A-Z])/i

            PROTEIN_IMPACT_REGEX = /p\.\((?<impact>.+)\)/i
          end
        end
      end
    end
  end
end
