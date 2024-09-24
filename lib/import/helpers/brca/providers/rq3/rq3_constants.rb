module Import
  module Helpers
    module Brca
      module Providers
        module Rq3
          module Rq3Constants
            PASS_THROUGH_FIELDS_BRCA = %w[age sex consultantcode servicereportidentifier
                                          providercode authoriseddate receiveddate
                                          moleculartestingtype specimentype].freeze

            TEST_SCOPE_MAP_BRCA = { '100kgp confirmation' => :full_screen,
                                    'confirmation' => :targeted_mutation,
                                    'diagnosis' => :full_screen,
                                    'family studies' => :targeted_mutation,
                                    'indirect testing' => :full_screen,
                                    'prenatal diagnosis' => :targeted_mutation,
                                    'presymptomatic' => :targeted_mutation,
                                    'ajp confirmation' => :aj_screen,
                                    'ajp screen' => :aj_screen }.freeze

            BRCA_GENES_MAP = { 'AZOVCA' => %w[BRCA1 BRCA2],
                               'BROV' => %w[BRCA1 BRCA2] }.freeze

            REPORT_GENETICTESTSCOPE_REGEX = /previously\sidentified\sin\sthis\sfamily|
                                            previously\sreported\sin\sthis\sfamily|
                                            previously\sfound\sin\san\saffected\srelative/ix

            BRCA_MALFORMED_GENE_MAPPING = {
              'Molecular analysis shows 3875delGTCT mutation in BRCA 1.' => 'BRCA1',
              'Molecular analysis shows 5301InsA mutation in BRCA 2' => 'BRCA2',
              'Molecular analysis confirms presence of mutation previously'\
              ' identified in this patient.' => 'BRCA1',
              'Sequence analysis has detected the missense variant found in '\
              'this patient\'s daughter.' => 'BRCA2',
              'Molecular analysis has shown the familial pathogenic variant c.5280delC'\
              ', p.(Phe1761Serfs*4) in the BRCA gene.' => 'BRCA1',
              'Heterozygous missense variant of uncertain significance, c.736A>T '\
              'p.(Thr246Ser), in the PLAB2 gene.' => 'PALB2'
            }.freeze

            # rubocop:disable Lint/MixedRegexpCaptureTypes
            BRCA_REGEX = /(?<brca>BRCA1|BRCA2|PALB2|ATM|CHEK2|TP53|MLH1|
                          MSH2|MSH6|PMS2|STK11|PTEN|BRIP1|NBN|RAD51C|RAD51D|CDKN2A)/ix

            CDNA_REGEX = /c\.(?<cdna>[0-9]+[+>_-][0-9][+>_-][0-9]+[+>_-][0-9][ACGTdelinsup]+|
                         [0-9]+[+>_-][0-9]+[ACGTdelinsup][+>_-][ACGTdelinsup]|
                         [0-9]+[ACGTdelinsup]+[+>_-][ACGTdelinsup]|
                         [0-9]+[+>_-][0-9]+[ACGTdelinsup]+|
                         [0-9]+[+>_-][0-9]+[+>_-][0-9]+[0-9]+[ACGTdelinsup]+|
                         [0-9]+[ACGTdelinsup]+)/x

            NO_EVIDENCE_REGEX = /no evidence.*?[^cp]\.|no further.*?[^cp]\./i
            NO_EVIDENCE_EXCEPTION_REGEX = /however\sthe\spreviously\sreported\sheterozygous\svariant\sc.*\sin\sthe\s\S+
            \sgene\sis\snow\sconsidered\sa\svariant\sof\sunknown\ssignificance/ix
            PROTEIN_REGEX = /p\.\(?(?<impact>.[a-z]+[0-9]+[a-z]+([^[:alnum:]][0-9]+)?|
            [a-z]+[0-9]+[^[:alnum:]])/ix

            CHR_VARIANTS_REGEX = /truncation|
                                  insertion|
                                  deletion|
                                  duplication
                                  /ix

            CHR_MALFORMED_REGEX = /missense|
                                  frameshift|
                                  splice site|
                                  splice-site|
                                  substitution|
                                  Splice site mutation|
                                  Nonsense/ix
            EXON_LOCATION = /(?<variant>del|dup|ins).+ex(on)?s?\s?
                             (?<exons>[0-9]+((to|and|-|\s)+[0-9]+)?)|
                             ex(on)?s?\s?(?<exons>[0-9]+((to|and|-|\s)+[0-9]+)?)\s?
                             (?<variant>del|dup|ins)?/x
            MUTATION_REGEX = /(?<mutation>[0-9_-]+(del|ins)[a-z0-9]+)/ix
            MALFORMED_MUTATION_REGEX = %r{(?<cdnamutation>[0-9-]+[ACGT]>[ACGT]+|
            [0-9-]+[ACGT]/[ACGT]+)}ix
            EXON_LOCATION_REGEX_COLO = /exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?)/i
            # rubocop:enable Lint/MixedRegexpCaptureTypes
          end
        end
      end
    end
  end
end
