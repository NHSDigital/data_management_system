module Import
  module Helpers
    module Brca
      module Providers
        module Rr8
          module Constants
            STATUS_FILEPATH = 'lib/import/helpers/brca/providers/rr8/status.yml'.freeze
            GENES_FILEPATH = 'lib/import/helpers/brca/providers/rr8/genes.yml'.freeze

            TEST_TYPE_MAP = { 'confirmation' => :diagnostic,
                              'diagnostic' => :diagnostic,
                              'mutation screening' => :diagnostic,
                              'predictive' => :predictive,
                              'prenatal' => :prenatal,
                              'diagnostic; brca' => :diagnostic,
                              'r207.1' => :diagnostic,
                              'r208.1' => :diagnostic,
                              'r208.2' => :diagnostic }.freeze

            TEST_SCOPE_MAP = { 'ashkenazi pre-screen' => :aj_screen,
                               'confirmation' => :targeted_mutation,
                               'diagnostic' => :full_screen,
                               'mutation screening' => :full_screen,
                               'predictive' => :targeted_mutation,
                               'prenatal' => :targeted_mutation,
                               'diagnostic; brca' => :full_screen,
                               'r207.1' => :full_screen,
                               'r208.1' => :full_screen,
                               'r208.2' => :full_screen,
                               'familial' => :targeted_mutation }.freeze

            PASS_THROUGH_FIELDS = %w[age authoriseddate
                                     requesteddate
                                     specimentype
                                     providercode
                                     consultantcode
                                     servicereportidentifier].freeze

            TEST_STATUS_MAPPINGS = { 'normal' => 1,
                                     'abnormal' => 2,
                                     'fail' => 9,
                                     'norm_var' => 10,
                                     'not_tested' => 8,
                                     'unknown' => 4 }.freeze
            TESTED_GENES_HASH = {
              'b1 (multiple exon) mlpa+ve' => ['BRCA1'],
              'b1 (single exon) mlpa+ve' => ['BRCA1'],
              'b1 class 3 uv' => ['BRCA1'],
              'b1 class 3a uv' => ['BRCA1'],
              'b1 class 4 uv' => ['BRCA1'],
              'b1 class 5 new' => ['BRCA1'],
              'b1 class 5 uv' => ['BRCA1'],
              'b1 class 5 uv - mlpa' => ['BRCA1'],
              'b1 class 5 uv - unaffected patient' => ['BRCA1'],
              'b1 class m' => ['BRCA1'],
              'b1 mlpa+ve (mutiple exons)' => ['BRCA1'],
              'b1 mlpa+ve (single exon)' => ['BRCA1'],
              'b1 truncating/frameshift' => ['BRCA1'],
              'b1/b2 - c4 pos' => ['BRCA1'],
              'b2 class 3 uv' => ['BRCA2'],
              'b2 class 3a uv' => ['BRCA2'],
              'b2 class 3b uv' => ['BRCA2'],
              'b2 class 4 uv' => ['BRCA2'],
              'b2 class 5 new' => ['BRCA2'],
              'b2 class 5 uv' => ['BRCA2'],
              'b2 class 5 uv - mlpa' => ['BRCA2'],
              'b2 class 5 uv - unaffected patient' => ['BRCA2'],
              'b2 class m' => ['BRCA2'],
              'b2 ptt shift' => ['BRCA2'],
              'b2 truncating/frameshift' => ['BRCA2'],
              'class 3 - unaffected' => ['BRCA2'],
              'ngs b1 class m' => ['BRCA1'],
              'ngs b1 seq variant - class 3' => ['BRCA1'],
              'ngs b1 truncating/frameshift' => ['BRCA1'],
              'ngs b1(multiple exon)mlpa+ve' => ['BRCA1'],
              'ngs b1(single exon) mlpa+ve' => ['BRCA1'],
              'ngs b2 class m' => ['BRCA2'],
              'ngs b2 seq variant - class 3' => ['BRCA2'],
              'ngs b2 seq variant - class 4' => ['BRCA2'],
              'ngs b2 truncating/frameshift' => ['BRCA2'],
              'ngs b2(multiple exon)mlpa+ve' => ['BRCA2'],
              'predictive brca1 seq pos' => ['BRCA1'],
              'predictive brca1 mlpa pos' => ['BRCA1'],
              'confirmation b1 seq neg' => ['BRCA1'],
              'confirmation b2 seq neg' => ['BRCA2'],
              'pred b1 c4/c5 mlpa neg' => ['BRCA1'],
              'pred b1 c4/c5 seq neg' => ['BRCA1'],
              'pred b2 c4/c5 seq neg' => ['BRCA2'],
              'pred b2 mlpa neg' => ['BRCA2'],
              'predictive brca1 mlpa neg' => ['BRCA1'],
              'predictive brca1 seq neg' => ['BRCA1'],
              'predictive brca2 mlpa neg' => ['BRCA2'],
              'predictive brca2 seq neg' => ['BRCA2'],
              'predictive ex13 dup neg' => ['BRCA1'],
              'brca - pred b1 c4/c5 mlpa neg' => ['BRCA1'],
              'brca - pred b2 c4/c5 seq neg' => ['BRCA2'],
              'word report - normal' => []
            }.freeze

            GENES_PANEL = { 'brca_1_2' => %w[BRCA1 BRCA2],
                            'brca_1_2_palb2' => %w[BRCA1 BRCA2 PALB2],
                            'r207_panel' => %w[BRCA1 BRCA2 BRIP1 MLH1 MSH2 MSH6 PALB2 RAD51C
                                               RAD51D],
                            'r208_panel' => %w[ATM BRCA1 BRCA2 CHEK2 PALB2],
                            'norm_mlpa' => %w[BRCA1 BRCA2 STK11],
                            'normal' => %w[BRCA1 BRCA2 PALB2 TP53],
                            'low_penetrance_panel' => %w[ATM BRCA1 BRCA2 CHEK2 PALB2 PTEN STK11
                                                         TP53] }.freeze

            VARIANT_CLASS_5 = ['b2 class m',
                               'ngs b1 class m',
                               'ngs b1 truncating/frameshift',
                               'ngs b2 truncating/frameshift',
                               'b1 class m',
                               'b1 mlpa+ve (mutiple exons)',
                               'b1 mlpa+ve (single exon)',
                               'b1 truncating/frameshift'].freeze

            FIELD_NAME_MAPPINGS = { 'consultantcode'    => 'practitionercode',
                                    'ngs sample number' => 'servicereportidentifier' }.freeze

            GENES = 'APC|ATM|BAP1|BMPR1A|BRCA1|BRCA2|BRIP1|CDH1|CHEK2|
            EPCAM|FH|FLCN|GREM1|MET|MLH1|MSH2|MSH6|MUTYH|NTHL1|PALB2|
            PMS2|POLD1|POLE|PTEN|RAD51C|RAD51D|SDHB|SMAD4|STK11|TP53|VHL'.freeze

            # rubocop:disable Lint/MixedRegexpCaptureTypes
            BRCA_REGEX = /(?<gene>#{GENES})/ix

            ASSOC_GENE_REGEX = /((?<gene>(#{GENES}))[\s\w]+variant\sc\.(?<cdna>[\w+>*\-.]+)?\s
                                (\(?p\.\(?(?<impact>\w+)\))?)/ix

            VARIANT_REPORT_REGEX = /(?<report>heterozygous[\w\s\-.>():=,']+)+/ix

            HETEROZYGOUS_GENE_REGEX = /heterozygous[\w\s]+(?<gene>#{GENES})[\w\s]+/ix

            CDNA_REGEX = /c\.(?<cdna>[\w+>*\-]+)?[\w\s.]+/ix

            TARG_GENE_REGEX = /(?<gene>#{GENES})[\w\s]+(c\.(?<cdna>[\w+>*\-]+)?[\w\s.]+|exon)/ix

            PROTEIN_REGEX = /\(?p\.\(?(?<impact>\w+)\)?/ix

            EXON_VARIANT_REGEX = /(?<variant>del|dup|ins).+ex(on)?s?\s?
                                  (?<exons>[0-9]+(-[0-9]+)?)|
                                  ex(on)?s?\s?(?<exons>[0-9]+(-[0-9]+)?)\s?
                                  (?<variant>del|dup|ins)|
                                  ex(on)?s?\s?(?<exons>[0-9]+\s?(\s?-\s?[0-9]+)?)\s?
                                  (?<variant>del|dup|ins)?|
                                  (?<variant>del|dup|ins)\s?(?<exons>[0-9]+(?<dgs>-[0-9]+)?)|
                                  ex(on)?s?\s?(?<exons>[0-9]+(\sto\s[0-9]+)?)\s
                                  (?<variant>del|dup|ins)|
                                  x(?<exons>[0-9+-? ]+)+(?<variant>del|dup|ins)/ix
            # rubocop:enable Lint/MixedRegexpCaptureTypes
          end
        end
      end
    end
  end
end
