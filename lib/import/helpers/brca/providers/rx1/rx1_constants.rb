module Import
  module Helpers
    module Brca
      module Providers
        module Rx1
          module Rx1Constants
            TEST_TYPE_MAP = { 'Carrier Screen' => '',
                              'Confirmation' => :diagnostic,
                              'Confirmation Of Familial Mutation' => :diagnostic,
                              'Confirmation of previous result' => :diagnostic,
                              'Diagnostic' => :diagnostic,
                              'Extract and Store' => '',
                              'Family Studies' => '',
                              'Indirect' => :predictive,
                              'Informativeness' => '',
                              'Mutation Screen' => '',
                              'Other' => '',
                              'Predictive' => :predictive,
                              'Store' => '',
                              'Variant Update' => '' }.freeze

            # Disabling rubocop Layout/LineLength check because fixing it would disrupt alignment
            # rubocop:disable Layout/LineLength
            TEST_SCOPE_MAP = { 'Hereditary Breast and Ovarian Cancer (BRCA1/BRCA2)' => :full_screen,
                               'BRCA1 + BRCA2 + PALB2'                              => :full_screen,
                               'Breast Cancer Core Panel'                           => :full_screen,
                               'Breast Cancer Full Panel'                           => :full_screen,
                               'Breast Core Panel'                                  => :full_screen,
                               'BRCA1/BRCA2 PST'                                    => :targeted_mutation,
                               'Cancer PST'                                         => :targeted_mutation,
                               'R207 Inherited Ovarian Cancer'                      => :full_screen }.freeze
            # rubocop:enable Layout/LineLength

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

            TEST_SCOPE_TTYPE_MAP = { 'Diagnostic' => :full_screen,
                                     'Indirect'   => :full_screen,
                                     'Predictive' => :targeted_mutation }.freeze

            PASS_THROUGH_FIELDS = %w[age authoriseddate
                                     receiveddate
                                     specimentype
                                     providercode
                                     consultantcode
                                     servicereportidentifier].freeze

            NEGATIVE_TEST = /Normal/i
            VARPATHCLASS_REGEX = /(?<varpathclass>[0-9](?=:))/
            # rubocop:disable Lint/MixedRegexpCaptureTypes
            CDNA_REGEX = /c\.(?<cdna>.?[0-9]+[^\s|^, ]+)/i

            EXON_REGEX = /ex([a-z ]+)?(?<exons>\d+([a-z -]+\d+)?)\s+(?<vartype>del|dup)|
                          (?<vartype>del[a-z ]+|dup[a-z ]+)exon(s)?\s(?<exons>\d+([a-z -]+\d+)?)/xi

            PROTEIN_REGEX = /p\..(?<impact>.+)\)/i
            # rubocop:enable Lint/MixedRegexpCaptureTypes
          end
        end
      end
    end
  end
end
