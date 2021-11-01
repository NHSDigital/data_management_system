module Import
  module Helpers
    module Brca
      module Providers
        module Rr8
          # Constants used by LondonKgcHandlerColorectal
          module Rr8Constants

            PASS_THROUGH_FIELDS = %w[age consultantcode
                                     providercode
                                     receiveddate
                                     authoriseddate
                                     requesteddate
                                     servicereportidentifier
                                     organisationcode_testresult
                                     specimentype].freeze

            TEST_SCOPE_MAP = { 'diagnostic' => :full_screen,
                               'mutation screening' => :full_screen,
                               'confirmation' => :targeted_mutation,
                               'predictive' => :targeted_mutation,
                               'prenatal' => :targeted_mutation,
                               'ashkenazi pre-screen' => :aj_screen,
                               '(v2) Any gene C5 - unaffected patient' => :full_screen,
                               '(v2) Class 5 low penetrance gene' => :full_screen,
                               '(v2) Normal' => :full_screen,
                               '(v2) Normal (MLPA dosage)' => :full_screen,
                               'B1/B2 - C3 pos' => :full_screen,
                               'B1/B2 Class 3 - UNAFFECTED' => :full_screen,
                               'B1/B2 Class 3 UV' => :full_screen,
                               'B1/B2 Class 4 UV' => :full_screen,
                               'B1/B2 Class 5 UV' => :full_screen,
                               'B2 Class 4 UV' => :full_screen,
                               'BRCA - Diagnostic Class 3' => :full_screen,
                               'BRCA - Diagnostic Class 4' => :full_screen,
                               'BRCA - Diagnostic Class 5' => :full_screen,
                               'BRCA - Diagnostic Class 5 - MLPA' => :full_screen,
                               'BRCA - Diagnostic Class 5 - UNAFFECTED' => :full_screen,
                               'BRCA - Diagnostic Normal' => :full_screen,
                               'BRCA - Diagnostic Normal - UNAFFECTED' => :full_screen,
                               'BRCA MS - Diag C3' => :full_screen,
                               'BRCA MS - Diag C4/5' => :full_screen,
                               'BRCA MS Diag Normal' => :full_screen,
                               'BRCA#/PALB2 - Diag Normal' => :full_screen,
                               'BRCA/PALB2 - Diag C4/5' => :full_screen,
                               'Conf B2 C4/C5 seq pos' => :targeted_mutation,
                               'Normal B1 and B2' => :full_screen,
                               'Normal B1/B2' => :full_screen,
                               'Normal B1/B2 - UNAFFECTED' => :full_screen,
                               'Pred B1 C4/C5 MLPA neg' => :targeted_mutation,
                               'Pred B1 C4/C5 MLPA pos' => :targeted_mutation,
                               'Pred B1 C4/C5 seq neg' => :targeted_mutation,
                               'Pred B1 C4/C5 seq pos' => :targeted_mutation,
                               'Pred B2 C4/C5 MLPA pos' => :targeted_mutation,
                               'Pred B2 C4/C5 seq neg' => :targeted_mutation,
                               'Pred B2 C4/C5 seq pos' => :targeted_mutation,
                               'Pred B2 MLPA neg' => :targeted_mutation,
                               'Predictive AJ neg 3seq' => :aj_screen,
                               'Predictive AJ pos 3seq' => :aj_screen,
                               'Predictive BRCA1 MLPA neg' => :targeted_mutation,
                               'Predictive BRCA1 seq pos' => :targeted_mutation,
                               'Predictive BRCA2 seq neg' => :targeted_mutation }.freeze

            TEST_TYPE_MAP = { 'diagnostic' => :diagnostic,
                              'mutation screening' => :diagnostic,
                              'confirmation' => :diagnostic,
                              'predictive' => :predictive,
                              'prenatal' => :prenatal,
                              'ashkenazi pre-screen' => nil,
                              '(v2) Any gene C5 - unaffected patient' => :predictive,
                              '(v2) Class 5 low penetrance gene' => :diagnostic,
                              '(v2) Normal' => :diagnostic,
                              '(v2) Normal (MLPA dosage)' => :diagnostic,
                              'B1/B2 - C3 pos' => :diagnostic,
                              'B1/B2 Class 3 - UNAFFECTED' => :predictive,
                              'B1/B2 Class 3 UV' => :diagnostic,
                              'B1/B2 Class 4 UV' => :diagnostic,
                              'B1/B2 Class 5 UV' => :diagnostic,
                              'B2 Class 4 UV' => :diagnostic,
                              'BRCA - Diagnostic Class 3' => :diagnostic,
                              'BRCA - Diagnostic Class 4' => :diagnostic,
                              'BRCA - Diagnostic Class 5' => :diagnostic,
                              'BRCA - Diagnostic Class 5 - MLPA' => :diagnostic,
                              'BRCA - Diagnostic Class 5 - UNAFFECTED' => :predictive,
                              'BRCA - Diagnostic Normal' => :diagnostic,
                              'BRCA - Diagnostic Normal - UNAFFECTED' => :predictive,
                              'BRCA MS - Diag C3' => :diagnostic,
                              'BRCA MS - Diag C4/5' => :diagnostic,
                              'BRCA MS Diag Normal' => :diagnostic,
                              'BRCA#/PALB2 - Diag Normal' => :diagnostic,
                              'BRCA/PALB2 - Diag C4/5' => :diagnostic,
                              'Conf B2 C4/C5 seq pos' => :diagnostic,
                              'Normal B1 and B2' => :diagnostic,
                              'Normal B1/B2' => :diagnostic,
                              'Normal B1/B2 - UNAFFECTED' => :predictive,
                              'Pred B1 C4/C5 MLPA neg' => :predictive,
                              'Pred B1 C4/C5 MLPA pos' => :predictive,
                              'Pred B1 C4/C5 seq neg' => :predictive,
                              'Pred B1 C4/C5 seq pos' => :predictive,
                              'Pred B2 C4/C5 MLPA pos' => :predictive,
                              'Pred B2 C4/C5 seq neg' => :predictive,
                              'Pred B2 C4/C5 seq pos' => :predictive,
                              'Pred B2 MLPA neg' => :predictive,
                              'Predictive AJ neg 3seq' => :predictive,
                              'Predictive AJ pos 3seq' => :predictive,
                              'Predictive BRCA1 MLPA neg' => :predictive,
                              'Predictive BRCA1 seq pos' => :predictive,
                              'Predictive BRCA2 seq neg' => :predictive }.freeze

              # FULL_SCREEN_LIST = [ 'mutation screening',
              #                      'b2 class 5 uv',
              #                      '(v2) any gene c5 - unaffected patient',
              #                      '(v2) class 5 low penetrance gene',
              #                      '(v2) normal',
              #                      '(v2) normal (mlpa dosage)',
              #                      'b1/b2 - c3 pos',
              #                      'b1/b2 class 3 - unaffected',
              #                      'b1/b2 class 3 uv',
              #                      'b1/b2 class 4 uv',
              #                      'b1/b2 class 5 uv',
              #                      'b2 class 4 uv',
              #                      'brca ms diag normal',
              #                      'brca#/palb2 - diag normal',
              #                      'brca/palb2 - diag c4/5',
              #                      'normal b1 and b2',
              #                      'normal b1/b2',
              #                      'normal b1/b2 - unaffected',
              #                      'b1 class 5 uv - mlpa',
              #                      'diagnostic',
              #                      '(v2) any gene c5 - unaffected patient',
              #                      '(v2) class 5 low penetrance gene',
              #                      '(v2) normal',
              #                      '(v2) normal (mlpa dosage)',
              #                      'b1/b2 - c3 pos',
              #                      'b1/b2 class 3 - unaffected',
              #                      'b1/b2 class 3 uv',
              #                      'b1/b2 class 4 uv',
              #                      'b1/b2 class 5 uv',
              #                      'b2 class 4 uv',
              #                      'brca - diagnostic class 3',
              #                      'brca - diagnostic class 4',
              #                      'brca - diagnostic class 5',
              #                      'brca - diagnostic class 5 - mlpa',
              #                      'brca - diagnostic class 5 - unaffected',
              #                      'brca - diagnostic normal',
              #                      'brca - diagnostic normal - unaffected',
              #                      'brca ms - diag c3',
              #                      'brca ms - diag c4/5',
              #                      'brca ms diag normal',
              #                      'brca#/palb2 - diag normal',
              #                      'brca/palb2 - diag c4/5',
              #                      'normal b1 and b2',
              #                      'normal b1/b2',
              #                      'normal b1/b2 - unaffected',
              #                      'b1 class 5 uv',
              #                      'b2 class 5 uv - unaffected patient'].freeze

              FULL_SCREEN_LIST = ['diagnostic',
                                  'mutation screening',
                                  'diagnostic; brca',
                                  'r208.1',
                                  'r208.2' ]

            FULL_SCREEN_REGEX = /diag/i.freeze

            TARGETED_REGEX = /pred/i.freeze

            TARGETED_LIST = [ 'prenatal',
                              'confirmation',
                              'predictive',
                              'familial' ]


            AJNEGATIVE_REGEX = /(?:predictive )?aj(?: pre-screen(?: conf)?)?\s
                                neg(?: 3seq)?/ix.freeze

            AJPOSITIVE_REGEX = /(?:predictive )?aj(?: B(?:1|2))?(?: pre-screen(?: conf)?)?\s
                                  pos(?: 3seq)?/ix.freeze

            PREDICTIVE_VALID_REGEX = /predictive\sb(?:rca)?(?<brca>1|2)\s(?<method>seq|ngs|mlpa)\s
                                     (?<status>pos|neg)/ix.freeze

            PREDICTIVE_REPORT_REGEX_NEGATIVE  = /.*(?:familial)?(?<variantclass>(?:\slikely)\s
                                                pathogenic)?\sBRCA(?<brca>1|2)\s
                                                (?:mutation|sequence\svariant)\s?\s
                                                (?<location>c\.[^\s\.]+)\s(?<protein>\(p\..*\))?\s?
                                                is\sabsent.*/ix.freeze

            PREDICTIVE_REPORT_REGEX_POSITIVE  = /.*patient\sis\s(?<zygosity>hetero|homo)zygous\sfor
                                                \sthe\s?
                                                (?<family>\sfamilial)?(?<variantclass>(?:\slikely)?
                                                (?:\spathogenic)?)\sBRCA(?<brca>1|2)\s
                                                (?:mutation|sequence\svariant)\s?\s
                                                (?<location>c\.[^\s\.]+).*/ix.freeze

            PREDICTIVE_REPORT_REGEX_INHERITED = /has\s(?<status>not\s)?inherited\sthe\s
                                                (?<family>familial\s)?
                                                BRCA(?<brca>1|2)\s(?:mutation|sequence\svariant)\s?
                                                \s(?<location>c\.[^\s\.]+)\s
                                                (?<protein>\(p\..*\))?/ix.freeze

            PREDICTIVE_MLPA_NEGATIVE = /mlpa.*the(?<family>\sfamilial)?(?<variantclass>\s
                                       (?:likely\s)?pathogenic)?\sBRCA(?<brca>1|2)\s
                                       (?<mutationtype>deletion|duplication)\sof\sexons?\s
                                       (?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?)\sis\s
                                       absent/ix.freeze
            PREDICTIVE_INHERITED_EXON = /has\s(?<status>not\s)?inherited\sthe\s
                                        (?<family>familial\s)?(?<variantclass>\s(?:likely\s)?
                                        pathogenic\s)?BRCA(?<brca>1|2)\s
                                        (?<mutationtype>deletion|duplication)\sof\sexons?\s
                                        (?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?)/ix.freeze

            CONFIRMATION_REGEX = /confirmation\sb(?:rca)?(?<brca>1|2)\s
                                 (?<method>seq|ngs|mlpa)\s(?<status>pos|neg)/ix.freeze

            VARIANT_CLASS_REGEX = /b(?:rca)?(?<brca>1|2)\sclass\s(?<class>[1-5]a?)\s
                                  (uv|new)(?:\sunaffected patient)?/ix.freeze

            VARIANTSEQ_REGEX = /(?<method>ngs\s)?b(?:rca)?(?<brca>1|2)\sseq\svariant(?:\s-\sclass\s
                                (?<variantclass>[1-5]))?/ix.freeze

            SCREENING_FAILED_REGEX = /^(?:(?<method>ngs)\s)?screening\sfailed$/i.freeze

            WORD_REPORT_NORMAL_REGEX = /^word\sreport\s-\snormal$/i.freeze

            BRCA_BASE = 'br?c?a?'.freeze
            BRCA     = BRCA_BASE + '(?<brca>1|2)'.freeze


            DOUBLE_MLPA_REGEX = /^normal\s#{BRCA}\sand #{BRCA},\sMLPA\sfail$/i.freeze



          end
        end
      end
    end
  end
end
