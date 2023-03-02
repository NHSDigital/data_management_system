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

            TEST_STATUS_MAP = { '1: Clearly not pathogenic' => :negative,
                                '2: likely not pathogenic' => :negative,
                                '2: likely not pathogenic variant' => :negative,
                                'Class 2 Likely Neutral' => :negative,
                                'Class 2 likely neutral variant' => :negative,
                                '3: variant of unknown significance (VUS)' => :positive,
                                '4: likely pathogenic' => :positive,
                                '4:likely pathogenic' => :positive,
                                '4: Likely Pathogenic' => :positive,
                                '5: clearly pathogenic' => :positive,
                                'Mutation identified' => :positive }.freeze

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

            CDNA_REGEX = /c\.(?<cdna>.?[0-9]+[^\s|^, ]+)/i

            EXON_REGEX = /ex(?<ons>[a-z]+)?\s?(?<exons>[0-9]+(?<otherexons>-[0-9]+)?)\s
                          (?<vartype>del|dup)|(?<vartype>del[a-z]+|dup[a-z]+)(?<of>\sof)?\s
                          exon(?<s>s)?\s(?<exons>[0-9]+(?<otherexons>-[0-9]+)?)/xi

            PROTEIN_REGEX = /p\..(?<impact>.+)\)/i
          end
        end
      end
    end
  end
end
