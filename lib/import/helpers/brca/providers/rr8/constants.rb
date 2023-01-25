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
            BRCA_REGEX = /(#{GENES})/ix

            ASSOC_GENE_REGEX = /((?<gene>(#{GENES}))[\s\w]+variant\sc\.(?<cdna>[\w+>*\-.]+)?\s(\(?p\.\(?(?<impact>\w+)\))?)/ix

            VARIANT_REPORT_REGEX = /(?<report>heterozygous[\w\s\-.>():=,']+)+/ix

            HETEROZYGOUS_GENE_REGEX = /heterozygous[\w\s]+(?<gene>#{GENES})[\w\s]+/ix

            CDNA_REGEX = /c\.(?<cdna>[\w+>*\-]+)?[\w\s.]+/ix

            PROTEIN_REGEX = /\(?p\.\(?(?<impact>\w+)\)?/ix

            EXON_VARIANT_REGEX = /(?<variant>del|dup|ins).+ex(?<on>on)?(?<s>s)?\s
                                  (?<exons>[0-9]+(?<dgs>-[0-9]+)?)|
                                ex(?<on>on)?(?<s>s)?\s?(?<exons>[0-9]+(?<dgs>-[0-9]+)?)\s?
                                (?<variant>del|dup|ins)|
                                (?<variant>del|dup|ins)\sexon(?<s>s)?\s
                                (?<exons>[0-9]+(?<dgs>\sto\s[0-9]+))|
                                ex(on)?(s)?\s?(?<exons>[0-9]+\s?(\s?-\s?[0-9]+)?)\s?
                                (?<variant>del|dup|ins)?|
                                (?<variant>del|dup|ins)(?<s>\s)?(?<exons>[0-9]+(?<dgs>-[0-9]+)?)|
                                ex(?<on>on)?(?<s>s)?\s(?<exons>[0-9]+(?<dgs>\sto\s[0-9]+)?)\s
                                (?<variant>del|dup|ins)|
                                x(?<exons>[0-9]+-?[0-9]+)\s?(?<variant>del|dup|ins)|
                                x(?<exons>[0-9]+-?[0-9]?)\s?(?<variant>del|dup|ins)/ix
            # rubocop:enable Lint/MixedRegexpCaptureTypes
          end
        end
      end
    end
  end
end
