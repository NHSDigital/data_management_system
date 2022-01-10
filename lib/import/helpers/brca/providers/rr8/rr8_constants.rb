module Import
  module Helpers
    module Brca
      module Providers
        module Rr8
          # Constants used by LondonKgcHandlerColorectal
          module Rr8Constants

            DEPRECATED_BRCA_NAMES_MAP = { 'BR1'    => 'BRCA1',
                                          'B1'     => 'BRCA1',
                                          'BRCA 1' => 'BRCA1',
                                          'BR2'    => 'BRCA2',
                                          'B2'     => 'BRCA2',
                                          'BRCA 2' => 'BRCA2' }.freeze

            DEPRECATED_BRCA_NAMES_REGEX = /B1|BR1|BRCA\s1|B2|BR2|BRCA\s2/i.freeze

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

            PASS_THROUGH_FIELDS = %w[age consultantcode
                                     providercode
                                     receiveddate
                                     authoriseddate
                                     requesteddate
                                     servicereportidentifier
                                     organisationcode_testresult
                                     specimentype].freeze

                                     FIELD_NAME_MAPPINGS = { 'consultantcode'  => 'practitionercode',
                                                             'instigated_date' => 'requesteddate' }.freeze

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

            BRCA_REGEX = /(?<brca>BRCA1|BRCA2|PALB2)/i.freeze

            AJNEGATIVE_REGEX = /(?:predictive )?aj(?: pre-screen(?: conf)?)?\s
                                neg(?: 3seq)?/ix.freeze

            AJPOSITIVE_REGEX = /(?:predictive )?aj(?: B(?:1|2))?(?: pre-screen(?: conf)?)?\s
                                  pos(?: 3seq)?/ix.freeze

            PREDICTIVE_VALID_REGEX = /predictive\sb(?:rca)?(?<brca>1|2)\s(?<method>seq|ngs|mlpa)\s
                                     (?<status>pos|neg)/ix.freeze

            CONFIRMATION_REGEX = /confirmation\sb(?:rca)?(?<brca>1|2)\s
                                 (?<method>seq|ngs|mlpa)\s(?<status>pos|neg)/ix.freeze

            VARIANT_CLASS_REGEX = /(?<brca>b(?:rca)?(1|2))\sclass\s(?<class>[1-5]a?)\s
                                  (uv|new)(?:\sunaffected patient)?/ix.freeze

            VARIANTSEQ_REGEX = /(?<method>ngs\s)?(?<brca>b(?:rca)?1|2)\sseq\svariant(?:\s-\sclass\s
                                (?<variantclass>[1-5]))?/ix.freeze

            TRUNCATING_VARIANT_REGEX = /(ngs\s)?b(?:rca)?(1|2)\struncating.frameshift/ix.freeze

            SCREENING_FAILED_REGEX = /^(?:(?<method>ngs)\s)?screening\sfailed$/i.freeze

            WORD_REPORT_NORMAL_REGEX = /^word\sreport\s-\s(ab)?normal$/i.freeze

            CLASS_M_REGEX = /B(1|2) Class M/i.freeze

            DOUBLE_NORMAL_MLPA_FAIL = /^normal\s(#{BRCA_REGEX}|#{DEPRECATED_BRCA_NAMES_REGEX})\s
                                       and\s(#{BRCA_REGEX}|#{DEPRECATED_BRCA_NAMES_REGEX}),\s
                                       MLPA\sfail$/ix.freeze

            SEQUENCE_ANALYSIS_SCREENING_MLPA   = /screened\sfor\s#{BRCA_REGEX}\sand\s#{BRCA_REGEX}\s
                                                  mutations\sby\ssequence\sanalysis/ix.freeze

            MLPA_FAIL_REGEX = /mlpa\sanalysis\sof\s#{BRCA_REGEX}\sfailed/ix.freeze

            GENE_LOCATION = '(?<location>c\.[^ \.]+) ?(?<protein>\(p\.[^)]*\))?'.freeze

            PREDICTIVE_REPORT_REGEX_NEGATIVE  = /.*(?:familial)?(?<variantclass>(?:\slikely)\s
                                                pathogenic)?\s(?<brca>BRCA1|BRCA2|PALB2)\s
                                                (?:mutation|sequence\svariant)\s?\s
                                                (?<location>c\.[^\s\.]+)\s(?<protein>\(p\..*\))?\s?
                                                is\sabsent.*/ix.freeze

            PREDICTIVE_REPORT_REGEX_POSITIVE  = /.*patient\sis\s(?<zygosity>hetero|homo)zygous\sfor
                                                \sthe\s?
                                                (?<family>\sfamilial)?(?<variantclass>(?:\slikely)?
                                                (?:\spathogenic)?)\s(?<brca>BRCA1|BRCA2|PALB2)\s
                                                (?:mutation|sequence\svariant)\s?\s
                                                (?<location>c\.[^\s\.]+).*/ix.freeze

            PREDICTIVE_REPORT_NEGATIVE_INHERITED_REGEX = /has\s(?<status>not\s)?inherited\sthe\s
                                                (?<family>familial\s)?
                                                (?<brca>BRCA1|BRCA2)\s(?:mutation|sequence\svariant)
                                                \s?\s(?<location>c\.[^\s\.]+)\s
                                                (?<protein>\(p\..*\))?/ix.freeze

            PREDICTIVE_MLPA_POSITIVE = /(MLPA|Sequence)\sanalysis\sindicates\sthat\sthis\spatient\sis\s
                                        (?<zygosity>hetero|homo)zygous\sfor\sthe\s
                                        (?<variantclass>(?:likely\s)?pathogenic)?\s
                                        (?<brca>BRCA1|BRCA2|PALB2)\s
                                        ((?<mutationtype>deletion|duplication)
                                        (\sof\sexon(s)?\s(?<exons>[0-9]+(-[0-9])?))?|exon(s)?\s
                                        (?<exons>[0-9]+(-[0-9])?)\s
                                        (?<mutationtype>deletion|duplication))/ix.freeze

            PREDICTIVE_MLPA_NEGATIVE = /mlpa.*the(?<family>\sfamilial)?(?<variantclass>\s
                                        (?:likely\s)?pathogenic)?\s(?<brca>BRCA1|BRCA2|PALB2)\s
                                        (?<mutationtype>deletion|duplication)\sof\sexons?\s
                                        (?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?)\sis\s
                                        absent|mlpa.*does\snot\shave\sthe
                                        (?<family>\sfamilial)?(?<variantclass>\s
                                        (?:likely\s)?pathogenic)?\s(?<brca>BRCA1|BRCA2|PALB2)\s
                                        (?<mutationtype>deletion|duplication)/ix.freeze

            PREDICTIVE_INHERITED_EXON = /has\s(?<status>not\s)?inherited\sthe\s
                                        (?<family>familial\s)?(?<variantclass>\s(?:likely\s)?
                                        pathogenic\s)?(?<brca>BRCA1|BRCA2|PALB2)\s
                                        (?<mutationtype>deletion|duplication)\sof\sexons?\s
                                        (?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?)/ix.freeze

            PREDICTIVE_POSITIVE_EXON = /.*patient\sis\s(?<zygosity>hetero|homo)zygous\sfor\sthe\s
                                       (?<family>familial\s)?
                                       (?<variantclass>(?:likely\s)?pathogenic\s)?
                                       (?<brca>BRCA1|BRCA2|PALB2)\s
                                       (?<mutationtype>deletion|duplication)\sof\sexon(s)?\s
                                       (?<exons>[0-9]+(-[0-9]+)?)/ix.freeze


            EXON_LOCATION = /(?<variantclass>\s(?:likely\s)?
                             pathogenic\s)?(?<brca>BRCA1|BRCA2|PALB2)\s
                             (?<mutationtype>deletion|duplication)\s(of|involving|including)?\s
                             exons?\s
                             (?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?)|
                             (?<variantclass>\s(?:likely\s)?
                             pathogenic\s)?
                             (?<mutationtype>deletion|duplication)\s(of|involving|including)?\s
                             (?<brca>BRCA1|BRCA2|PALB2)\sexons?\s
                             (?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?)/ix.freeze

            PROMOTER_EXON_LOCATION = /(?<variantclass>\s(?:likely\s)?
                                      pathogenic\s)?(?<brca>BRCA1|BRCA2|PALB2)?\s?
                                      (?<mutationtype>deletion|duplication)\s([a-zA-Z0-9_ ]*)?\s
                                      the\spromoter\s(region\s)?to\sexons?\s
                                      (?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?)
                                      (\sof\s(?<brca>BRCA1|BRCA2|PALB2))?/ix.freeze

            EXON_LOCATION_EXCEPTIONS = /(?<mutationtype>deletion|duplication).+
                                        exons?\s(?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?)|
                                        exons?\s(?<exons>\d+[a-z0-9]*(?:-\d+[a-z0-9]*)?).+
                                        (?<mutationtype>deletion|duplication)/ix.freeze

            CDNA_VARIANT_CLASS_REGEX  =   /.*patient\sis\s(?<zygosity>hetero|homo)zygous\sfor
                                          \sthe\s?
                                          (?<family>\sfamilial)?(?<variantclass>(?:\slikely)?
                                          (?:\spathogenic)?)\s(?<brca>BRCA1|BRCA2|PALB2)\s
                                          (?:mutation|sequence\svariant|variant)\s?\s
                                          (?<location>c\.[^\s\.]+)
                                          \s?(p\.\(?(?<impact>\w+\d+\w+)\))?.*|
                                          .*patient\sis\s(?<zygosity>hetero|homo)zygous\sfor
                                           \sthe\s?
                                           (?<family>\sfamilial)?(?<variantclass>(?:\slikely)?
                                           (?:\spathogenic)?)\s
                                           (?:mutation|sequence\svariant|variant)?\s
                                           (?<location>c\.[^\s\.]+)\s?
                                           (\(?p\.\(?(?<impact>\w+\d+\w+)\))?
                                           \s(in\s|involving\s)?(?<brca>BRCA1|BRCA2|PALB2)?/ix.freeze

            DOUBLE_NORMAL_LIST = %w[b1 b2 normal unaffected].freeze

            DOUBLE_NORMAL_EXCLUDEABLE = ([' '] + %w[/ NGS MLPA seq and - patient]).map(&:downcase)

            PROTEIN_REGEX = /\(?p\.\(?(?<impact>.\w+\d+\w+|\=)\)?/i.freeze

            CDNA_REGEX = /c\.(?<location>[0-9]+.>[A-Za-z]+)|
                          c\.(?<location>[0-9]+\+[0-9]+[A-Z]+>[A-Z]+)|
                          c\.(?<location>[0-9]+\-[0-9]+[A-Z]+>[A-Z]+)|
                          c\.(?<location>[0-9]+.[0-9]+[A-Za-z]+)/ix.freeze
            
            CDNA_PROTEIN_COMBO_EXCEPTIONS = /#{CDNA_REGEX}\s#{PROTEIN_REGEX}/ix.freeze

            CDNA_MUTATION_TYPES_REGEX = /(.*patient\sis\s(?<zygosity>hetero|homo)zygous\sfor
                                         \sthe\s?|
                                         .*patient\shas\sinherited(?<zygosity>hetero|homo)zygous
                                         \sfor\sthe\s?)?(?<family>\sfamilial)?\s
                                         (?<brca>BRCA1|BRCA2|PALB2)?\s?(?<variantclass>(?:\slikely)?
                                         (?:pathogenic)?)\s?(?<brca>BRCA1|BRCA2|PALB2)?\s?
                                         (?<type>frameshift|splice\ssite|missense|
                                         nonsense|synonymous)?\s?
                                         (mutation|sequence\svariant|variant)?\s?
                                         #{CDNA_REGEX}\s?#{PROTEIN_REGEX}?/ix.freeze

            MUTATION_DETECTED_REGEX = /(?<zygosity>hetero|homo)zygous\s?
                                      (?<variantclass>(?:\slikely)?
                                      (?:pathogenic)?)\s?(?<brca>BRCA1|BRCA2|PALB2)?\s?
                                      (mutation|sequence\svariant|variant)?\s?#{CDNA_REGEX}\s?
                                      #{PROTEIN_REGEX}?\s?was\sdetected./ix.freeze

            DOUBLE_CDNA_VARIANTS_REGEX = /(?<zygosity>hetero|homo)zygous\s?for\sthe\s
                                          (?<brca>BRCA1|BRCA2|PALB2)?\s?(sequence\svariants|
                                          sequence\schanges)?\s?#{CDNA_REGEX}\s?
                                          #{PROTEIN_REGEX}?\s?in?\s?(?<brca>BRCA1|BRCA2|PALB2)?
                                          \s?(and|\,)?\s?#{CDNA_REGEX}\s?
                                          #{PROTEIN_REGEX}?/ix.freeze
          end
        end
      end
    end
  end
end
