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
                                   'brca ashkenazi mutations' => :aj_screen,
                                   'breast and ovarian cancer 7-gene panel (r208)' => :full_screen,
                                   'breast and ovarian cancer reanalysis' => :full_screen,
                                   'breast and ovarian cancer targeted testing' => :targeted_mutation,
                                   'default' => :full_screen,
                                   'ovarian cancer 9 gene panel reanalysis' => :full_screen,
                                   'ovarian cancer 9-gene panel (r207)' => :full_screen,
                                   'ovarian cancer targeted testing' => :targeted_mutation,
                                   'ovarian cancer targeted testing profile' => :targeted_mutation,
                                   'prostate cancer 2-gene panel (r444)' => :full_screen,
                                   'prostate cancer 8-gene panel (r430)' => :full_screen,
                                   'prostate cancer targeted testing' => :targeted_mutation }.freeze

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
                               '?single exon deletion',
                               'pathogenic cnv'].freeze

            ABNORMAL_STATUS = ['benign',
                               'likely benign'].freeze

            NEGATIVE_STATUS = ['absent',
                               'no variant detected',
                               'no mutation detected',
                               'normal'].freeze

            UNKNOWN_STATUS = ['gaps present',
                              'variant - supplementary',
                              'no gaps',
                              'completed'].freeze

            GENO_DEPEND_STATUS = ['variant -  not reported',
                                  'variant - not reported',
                                  'variant not reported'].freeze

            FAILED_TEST = /Fail*+/i
            BRCA_REGEX = /(?<brca>BRCA1|BRCA2|PALB2|ATM|CHEK2|TP53|MLH1|CDH1|BC1|BC2|
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
            ORG_CODE_MAP = {
              'royal cornwall hospital trust' => 'REF12',
              'exeter clinical genetics centre' => 'RH802',
              'peninsula clinical genetics service' => 'RH802',
              'royal devon & exeter hospital nhs trust' => 'RH802',
              'peninsula clinical genetics service (truro)' => 'RH855',
              'royal devon & exeter hospital (oncology)' => 'RH8AA',
              'peninsula clinical genetics service (plymouth)' => 'RH8D2',
              'molecular genetics department' => 'RNZ02',
              'wessex clinical genetics service' => 'RNZ02'
            }.freeze

            ROW_LEVEL = [
              'brca ashkenazi mutations',
              'brca mainstreaming',
              'brca mlpa only',
              'brca unaffected full screen',
              'breast cancer full screen',
              'breast cancer full screen (htsf lab)',
              'breast cancer full screen data only',
              'breast cancer predictives',
              'palb2',
              'palb2 data only',
              'palb2 mlpa only',
              'palb2 targetted testing',
              'breast and ovarian cancer targeted testing',
              'ovarian cancer targeted testing',
              'ovarian cancer targeted testing profile',
              'prostate cancer 2-gene panel (r444)',
              'prostate cancer targeted testing'
            ].freeze

            PANEL_LEVEL = {
              'breast and ovarian cancer 7-gene panel (r208)' => %w[ATM BRCA1 BRCA2 CHEK2 PALB2 RAD51C RAD51D],
              'breast and ovarian cancer reanalysis' => %w[ATM BRCA1 BRCA2 CHEK2 PALB2 RAD51C RAD51D],
              'default' => %w[ATM BRCA1 BRCA2 CHEK2 PALB2 RAD51C RAD51D],
              'ovarian cancer 9 gene panel reanalysis' => %w[BRCA1 BRCA2 BRIP1 MLH1 MSH2 MSH6 PALB2 RAD51C RAD51D],
              'ovarian cancer 9-gene panel (r207)' => %w[BRCA1 BRCA2 BRIP1 MLH1 MSH2 MSH6 PALB2 RAD51C RAD51D],
              'prostate cancer 8-gene panel (r430)' => %w[ATM BRCA1 BRCA2 CHEK2 MLH1 MSH2 MSH6 PALB2]
            }.freeze

            HYBRID_LEVEL = {
              'brca mainstreaming - 3 gene panel (r208)' => [3186],
              'breast and ovarian cancer 3-gene panel (r208)' => [3186],
              'ovarian cancer 8-gene panel - data only' => [3615, 3616],
              'ovarian cancer 8-gene panel (r207)' => [3615, 3616]
            }.freeze

            STATUS_PANEL_VARPATHCLASS = {
              'likely pathogenic' => 4,
              'pathogenic' => 5,
              'like pathogenic' => 4,
              'pathogenic mutation detected' => 5,
              'benign' => 1,
              'likely benign' => 2,
              'variant' => 3,
              'pathogenic cnv' => 5
            }.freeze
            # rubocop:enable Lint/MixedRegexpCaptureTypes
          end
        end
      end
    end
  end
end
