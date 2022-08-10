module Import
  module Helpers
    module Brca
      module Providers
        module Rnz
          module RnzConstants
            TEST_SCOPE_MAPPING = { 'breast cancer full screen' => :full_screen,
                                   'breast cancer full screen data only' => :full_screen,
                                   'brca mainstreaming' => :full_screen,
                                   'brca mainstreaming - 3 gene panel (r208)' => :full_screen,
                                   'breast cancer predictives' => :targeted_mutation,
                                   'brca mlpa only' => :no_genetictestscope,
                                   'brca unaffected full screen' => :full_screen,
                                   'breast and ovarian cancer 3-gene panel (r208)' => :full_screen,
                                   'breast cancer full screen (htsf lab)' => :full_screen,
                                   'ovarian cancer 8-gene panel - data only' => :full_screen,
                                   'ovarian cancer 8-gene panel (r207)' => :full_screen,
                                   'palb2' => :full_screen,
                                   'palb2 data only' => :full_screen,
                                   'palb2 mlpa only' => :no_genetictestscope,
                                   'palb2 targetted testing' => :targeted_mutation,
                                   'brca ashkenazi mutations' => :aj_screen }.freeze

            TEST_TYPE_MAPPING = { 'brca mainstreaming - 3 gene panel (r208)' => :diagnostic,
                                  'brca mainstreaming' => :diagnostic,
                                  'brca unaffected full screen' => :predictive }.freeze

            PASS_THROUGH_FIELDS = %w[age consultantcode
                                     servicereportidentifier
                                     providercode
                                     authoriseddate
                                     specimentype
                                     requesteddate].freeze

            POSITIVE_STATUS = ['single exon deletion',
                               'deletion',
                               'duplication',
                               'likely pathogenic',
                               'like pathogenic',
                               'pathogenic',
                               'pathogenic mutation detected',
                               '?single exon deletion'].freeze

            NEGATIVE_STATUS = ['benign',
                               'likely benign',
                               'absent',
                               'no variant detected',
                               'no mutation detected'].freeze

            UNKNOWN_STATUS = ['gaps present',
                              'completed'].freeze

            GENO_DEPEND_STATUS = ['normal',
                                  'variant',
                                  'variant -  not reported',
                                  'variant - not reported',
                                  'variant not reported'].freeze

            FAILED_TEST = /Fail*+/i
            BRCA_REGEX = /(?<brca>BRCA1|BRCA2|PALB2|ATM|CHEK2|TP53|MLH1|CDH1|
                                  MSH2|MSH6|PMS2|STK11|PTEN|BRIP1|NBN|RAD51C|RAD51D)/ix

            CONFIRM_SEQ_NGS = /Confirmation\sSequencing|NGS\sResults/ix
            # rubocop:disable Lint/MixedRegexpCaptureTypes
            CDNA_REGEX = /c\.\[?(?<cdna>
                                ([0-9]+[+>_-][0-9][+>_-][0-9]+[+>_-][0-9][ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9][+>_-][0-9]+[+>_-][0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9]+[ACGTdelinsup][+>_-][ACGTdelinsup])|
                                ([0-9]+[ACGTdelinsup]+[+>_-][ACGTdelinsup])|
                                ([0-9]+[+>_-][0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9]+[+>_-][0-9]+[0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[?+>_-]+[0-9]+[?+>_-]+[ACGTdelinsup]+)|
                                ([0-9]+[ACGTdelinsup]+)
                                )\]?/ix

            PROTEIN_REGEX = /p\.\((?<impact>.+)\)|
                            \(p\.(?<impact>[A-Za-z]+.+)\)|
                            p\.(?<impact>[A-Za-z]+.+)/ix

            EXON_VARIANT_REGEX = /(?<ex>(?<zygosity>het|homo)[a-z ]+)?
                                  (?<mutationtype>del|dup)\s?
                                  ([a-z 0-9]+ (exon|exons)\s
                                  (?<exons>[0-9]+([a-z -]+[0-9]+)?))|
                                  (?<ex>(?<zygosity>het|homo)[a-z ]+)?
                                  (?<ex>(?<nm>exon|exons)\s(?<exons>[0-9]+([a-z -]+[0-9]+)?))
                                  ([a-z ]+
                                  (?<mutationtype>del|dup))?/ix
            # rubocop:enable Lint/MixedRegexpCaptureTypes
          end
        end
      end
    end
  end
end
