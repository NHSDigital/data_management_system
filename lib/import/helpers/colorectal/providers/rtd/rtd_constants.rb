module Import
  module Helpers
    module Colorectal
      module Providers
        module Rtd
          module RtdConstants
            TEST_TYPE_MAP_COLO = { 'diag - symptoms' => :diagnostic,
                                   'diagnosis' => :diagnostic,
                                   'diagnostic' => :diagnostic,
                                   'diagnostic test' => :diagnostic,
                                   'presymptomatic' => :predictive,
                                   'predictive' => :predictive,
                                   'predictive test' => :predictive,
                                   'carrier' => :carrier,
                                   'carrier test' => :carrier,
                                   'prenatal diagnosis' => :prenatal }.freeze

            TEST_SCOPE_FROM_TYPE_MAP_COLO = { 'carrier' => :targeted_mutation,
                                              'carrier test' => :targeted_mutation,
                                              'diag - symptoms' => :full_screen,
                                              'diagnosis' => :full_screen,
                                              'diagnostic' => :full_screen,
                                              'diagnostic test' => :full_screen,
                                              'diagnostic/forward' => :full_screen,
                                              'bmt' => :targeted_mutation,
                                              'family studies' => :targeted_mutation,
                                              'predictive' => :targeted_mutation,
                                              'predictive test' => :targeted_mutation,
                                              'presymptomatic' => :targeted_mutation,
                                              'presymptomatic test' => :targeted_mutation,
                                              'storage' => :full_screen,
                                              'unknown / other' => :no_gentictestscope,
                                              'unknown' => :no_gentictestscope,
                                              'msi screen' => :no_gentictestscope,
                                              'rna studies' => :no_gentictestscope }.freeze

            PASS_THROUGH_FIELDS_COLO = %w[age authoriseddate
                                          requesteddate
                                          specimentype
                                          providercode
                                          consultantcode
                                          servicereportidentifier].freeze
            FIELD_NAME_MAPPINGS_COLO = { 'consultantcode' => 'practitionercode',
                                         'ngs sample number' => 'servicereportidentifier' }.freeze

            INVESTIGATION_CODE_GENE_MAPPING = {
              'fap' => %w[APC],
              'fap/map' => %w[APC MUTYH],
              'fap-mlpa' => %w[APC],
              'hnpcc' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM],
              'hnpcc_pred' => %w[MLH1 MSH2 MSH6 PMS2 EPCAM],
              'hnpcc-mlpa' => %w[MLH1 MSH2 MSH6 EPCAM],
              'colorectal cancer' => %w[APC BMPR1A EPCAM GREM1 MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2
                                        POLD1 POLE PTEN SMAD4 STK11],
              'colerectal cancer' => %w[APC BMPR1A EPCAM GREM1 MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2
                                        POLD1 POLE PTEN SMAD4 STK11],
              'tp53' => %w[TP53]
            }.freeze

            NON_PATHEGENIC_CODES = ['nmd',
                                    'likely benign',
                                    'benign',
                                    'non-pathological variant'].freeze
            # rubocop:disable Lint/MixedRegexpCaptureTypes
            CDNA_REGEX = /c\.?,?\[?(?<cdna>
                                ([0-9]+[+>_-][0-9][+>_-][0-9]+[+>_-][0-9][ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9][+>_-][0-9]+[+>_-][0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9]+[ACGTdelinsup][+>_-][ACGTdelinsup])|
                                ([0-9]+[ACGTdelinsup]+[+>_-][ACGTdelinsup])|
                                ([0-9]+[+>_-][0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9]+[ACGTdelinsup]?)|
                                ([0-9]+[+>_-][0-9]+[+>_-][0-9]+[0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[?+>_-]+[0-9]+[?+>_-]+[ACGTdelinsup]+)|
                                ([0-9]+[ACGTdelinsup]+)|
                                ([+>_-][0-9]+[ACGTdelinsup>]+)
                                )\]?/ix

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

            PROTEIN_REGEX = /p\.[\[(]?(?<impact>([a-z]+[0-9]+[a-z]+([^[:alnum:]][0-9]+)?)|
                                   ([a-z]+[0-9]+[^[:alnum:]]))[)\]]?/ix

            IMPACT_REGEX = /.p\.(?<impact>[A-Za-z]+[0-9]+[A-Za-z]+)/i
            # rubocop:enable Lint/MixedRegexpCaptureTypes
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
                                                  STK11|
                                                  GREM1|
                                                  NTHL1)/ix
            HNPCC = %w[MLH1 MSH2 MSH6 PMS2 EPCAM].freeze
            HNPCCMLPA = %w[MLH1 MSH2 MSH6 EPCAM].freeze
            COLORECTALCANCER = %w[APC BMPR1A EPCAM GREM1 MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2
                                  POLD1 POLE PTEN SMAD4 STK11].freeze
            FAPMAP = %w[APC MUTYH].freeze
          end
        end
      end
    end
  end
end
