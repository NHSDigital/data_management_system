module Import
  module Helpers
    module Colorectal
      module Providers
        module Rr8
          module Constants
            TEST_SCOPE_MAP_COLO = { 'carrier test' => :targeted_mutation,
                                    'diagnostic' => :full_screen,
                                    'diagnostic; fap' => :full_screen,
                                    'diagnostic; lynch' => :full_screen,
                                    'diagnostic; pms2' => :full_screen,
                                    'confirmation' => :targeted_mutation,
                                    'predictive' => :targeted_mutation,
                                    'predictive test' => :targeted_mutation,
                                    'familial' => :targeted_mutation,
                                    'r209' => :full_screen,
                                    'r209.1' => :full_screen,
                                    'r210.2' => :full_screen,
                                    'r211.1' => :full_screen }.freeze

            TEST_TYPE_MAP_COLO = { 'carrier test' => :carrier,
                                   'diagnostic' => :diagnostic,
                                   'diagnostic; fap' => :diagnostic,
                                   'diagnostic; lynch' => :diagnostic,
                                   'confirmation' => :diagnostic,
                                   'predictive' => :predictive,
                                   'predictive test' => :predictive,
                                   'familial' => :predictive }.freeze

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

            CDNA_REGEX = /c\.(?<cdna>[0-9]+.>[A-Za-z]+)|c\.(?<cdna>[0-9]+.[0-9]+[A-Za-z]+)/i
            PROTEIN_REGEX = /p\.\((?<impact>.\w+\d+\w+)\)/i
            TESTSTATUS_REGEX = /unaffected|neg|normal/i
            NOPATH_REGEX = /.No pathogenic variant was identified./i
            EXON_LOCATION_REGEX = /(?<exons>exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?))/i

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
                                                  NTHL1)/xi # Added by Francesco
            PATHVAR_REGEX = /((?<homohet>heterozygous|homozygous)[\w\s]+{0,2})?
                            (?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|PMS2|
                                     POLD1|POLE|PTEN|SMAD4|STK11)
                            \s[\w\s]+{0,2}.c\.(?<cdna>[0-9]+[A-Z]+>[A-Z]+|
                                               [0-9]+_[0-9]+[a-z]+|
                                               [0-9]+[a-z]+|
                                               [0-9]+\W[0-9]+[a-z]+>[a-z]+|
                                               [0-9]+_[0-9]+\W[0-9]+[a-z]+
                                               [0-9]+_[0-9]+[a-z]+|
                                               [0-9]+\W[0-9]+_[0-9]+[a-z]+|
                                               [0-9]+\W[0-9]+[a-z]+|
                                               [0-9]+\W[0-9]+_[0-9]+\W[0-9]+[a-z]+|
                                               \W[0-9]+[a-z]+>[a-z]+).
                            (\(?p\.\(?(?<impact>\w+)|\(p\.\(?(?<impact>\w+)\))?/ix

            PATHVAR_BIGINDELS = /(?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|
                              PMS2|POLD1|POLE|PTEN|SMAD4|STK11).+
                               c\.(?<cdna>[0-9]+_[0-9]+.[0-9]+[a-z]+|[0-9]+.[0-9]+.[0-9]+[a-z]+)/ix

            PATHVAR_REGEX2 = /((?<homohet>heterozygous|homozygous)[\w\s]+{0,2})?\s[\w\s]+{0,2}.
                              c\.(?<cdna>[0-9]+[A-Z]+>[A-Z]+|[0-9]+_[0-9]+[a-z]+|
                              [0-9]+[a-z]+|[0-9]+\W[0-9]+[a-z]+>[a-z]+|
                              [0-9]+_[0-9]+\W[0-9]+[a-z]+[0-9]+_[0-9]+[a-z]+|
                              [0-9]+\W[0-9]+_[0-9]+[a-z]+|[0-9]+\W[0-9]+[a-z]+|
                              [0-9]+\W[0-9]+_[0-9]+\W[0-9]+[a-z]+|\W[0-9]+[a-z]+>[a-z]+).
                              (\(?p\.\(?(?<impact>\w+)\)|\(p\.\(?(?<impact>\w+)\))?[\w\s]+
                              (?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|PMS2|POLD1|
                              POLE|PTEN|SMAD4|STK11)/ix

            PATH_TWOGENES_VARIANTS = /((heterozygous)?[\s\w]{2,})(?<path>pathogenic).(?<genes>APC|BMPR1A|
                                   EPCAM|
                                   MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|POLE|PTEN|SMAD4|STK11|GREM1|NTHL1).(sequence)?
                                   (mutation|variant)?.c\.(?<cdna>[0-9]+[A-Z]+>[A-Z]+|[0-9]+_[0-9]+[a-z]+|
                                   [0-9]+[a-z]+|[0-9]+\W[0-9]+[a-z]+>[a-z]+|
                                   [0-9]+_[0-9]+\W[0-9]+[a-z]+[0-9]+_[0-9]+[a-z]+|
                                   [0-9]+\W[0-9]+_[0-9]+[a-z]+|
                                   [0-9]+\W[0-9]+[a-z]+|[0-9]+\W[0-9]+_[0-9]+\W[0-9]+[a-z]+|
                                   \W[0-9]+[a-z]+>[a-z]+).+(heterozygous)?[\s\w]{2,}
                                   (?<genes2>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|POLE|
                                   PTEN|SMAD4|STK11|GREM1|NTHL1)[\s\w]{2,}
                                   c\.(?<cdna2>[0-9]+[A-Z]+>[A-Z]+|[0-9]+_[0-9]+[a-z]+|[0-9]+[a-z]+|
                                   [0-9]+\W[0-9]+[a-z]+>[a-z]+|
                                   [0-9]+_[0-9]+\W[0-9]+[a-z]+[0-9]+_[0-9]+[a-z]+|
                                   [0-9]+\W[0-9]+_[0-9]+[a-z]+|[0-9]+\W[0-9]+[a-z]+|
                                   [0-9]+\W[0-9]+_[0-9]+\W[0-9]+[a-z]+|\W[0-9]+[a-z]+>[a-z]+)|
                                   (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|POLE|PTEN|
                                   SMAD4|STK11|GREM1|NTHL1)[\s\w]{2,}.c\.(?<cdna>[0-9]+[A-Z]+>[A-Z]+|
                                   [0-9]+_[0-9]+[a-z]+|[0-9]+[a-z]+|[0-9]+\W[0-9]+[a-z]+>[a-z]+|
                                   [0-9]+_[0-9]+\W[0-9]+[a-z]+[0-9]+_[0-9]+[a-z]+|
                                   [0-9]+\W[0-9]+_[0-9]+[a-z]+|[0-9]+\W[0-9]+[a-z]+|
                                   [0-9]+\W[0-9]+_[0-9]+\W[0-9]+[a-z]+|
                                   \W[0-9]+[a-z]+>[a-z]+).+(heterozygous)?[\s\w]{2,}
                                   (?<genes2>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|POLE|PTEN|
                                   SMAD4|STK11|GREM1|NTHL1)[\s\w]{2,}c\.(?<cdna2>[0-9]+[A-Z]+>[A-Z]+|
                                   [0-9]+_[0-9]+[a-z]+|[0-9]+[a-z]+|[0-9]+\W[0-9]+[a-z]+>[a-z]+|
                                   [0-9]+_[0-9]+\W[0-9]+[a-z]+[0-9]+_[0-9]+[a-z]+|
                                   [0-9]+\W[0-9]+_[0-9]+[a-z]+|[0-9]+\W[0-9]+[a-z]+|
                                   [0-9]+\W[0-9]+_[0-9]+\W[0-9]+[a-z]+|\W[0-9]+[a-z]+>[a-z]+)/ix

            NOPATH_SINGLEGENE = /(?<genes>APC|BMPR1A|
                                  EPCAM|GREM1|MLH1|MSH2|
                                  MSH6|MUTYH|NTHL1|PMS2|
                                  POLD1|POLE|PTEN|SMAD4|STK11)[\w\s]
                                  +.No pathogenic variant was identified/ix

            PATHVAR_TWOGENES_REGEX = /((?<homohet>heterozygous|homozygous)[\w\s]+{0,2})?
                                       (?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|
                                       NTHL1|PMS2|POLD1|POLE|PTEN|SMAD4|STK11)
                                       \s[\w\s]+{0,2}.
                                       c\.(?<cdna>[0-9]+[A-Z]+>[A-Z]+|[0-9]+_[0-9]+[a-z]+|[0-9]+[a-z]+)
                                       .(\(?p\.\(?(?<impact>\w+)\)?)? (\w)+
                                       c\.(?<cdna2>[0-9]+[A-Z]+>[A-Z]+|[0-9]+_[0-9]+[a-z]+|[0-9]+[a-z]+)
                                       .(\(?p\.\(?(?<impact2>\w+)\)?)?/ix

            PATHVAR_EXONS_REGEX = /(?<homohet>heterozygous|homozygous)[\w\s]+{0,3}(?<deldup>deletion|duplication)[\w\s]+(?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|PMS2|POLD1|POLE|PTEN|SMAD4|STK11)([\w\s]+|\s)?(?<exons>exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?))|(?<homohet>heterozygous|homozygous)[\w\s]+{0,3}(?<genes>APC|BMPR1A|EPCAM|GREM1|MLH1|MSH2|MSH6|MUTYH|NTHL1|PMS2|POLD1|POLE|PTEN|SMAD4|STK11)[\w\s]+(?<deldup>deletion|duplication)([\w\s]+|\s)?(?<exons>exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?))/i

            ABSENT_REGEX = /is absent in this patient/i
            NO_DEL_REGEX = /this patient does not have the deletion/i
            NOMUT_REGEX = /(?<notmut>No mutations were identified in|this patient does not have|has not identified any mutations in this patient|no mutation has been identified|no evidence of a deletion or duplication)|not detected in this patient|did not identify/i
            EXON_ALTERNATIVE_REGEX = /(heterozygous)?[\s\w]{2,} (?<pathogenic>pathogenic)? (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                      POLE|PTEN|SMAD4|STK11|GREM1|NTHL1) (?<delmut>deletion|mutation|inversion|duplication)[\s\w]{2,}(?<exons>exon(s).[0-9]+(.?)[0-9]+?)|
                                      (pathogenic)? (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                      POLE|PTEN|SMAD4|STK11|GREM1|NTHL1)[\w\s]{0,2}(?<invdupdel>inversion|duplication|deletion)\s[\w\s]+{0,2}(?<exons>exon(s).[0-9]+(.?)[0-9]+?)|
                                      (pathogenic)? (?<invdupdel>inversion|duplication|deletion)\s[\w\s]+{0,2}(?<exons>exon(s).[0-9]+(.?)[0-9]+?) ([\w\s]+)?
                                      (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                      POLE|PTEN|SMAD4|STK11|GREM1|NTHL1)[\w\s]{0,2}?|(familial)? pathogenic deletion of
                                      (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                      POLE|PTEN|SMAD4|STK11|GREM1|NTHL1) (?<delmut>deletion|mutation|inversion|duplication)[\s\w]{2,}
                                      (?<exons>exon(s).[0-9]+(.?)[0-9]+?)|(familial)? pathogenic (?<genes>APC|BMPR1A|EPCAM|MLH1|MSH2|MSH6|MUTYH|PMS2|POLD1|
                                      POLE|PTEN|SMAD4|STK11|GREM1|NTHL1) (?<delmut>deletion|mutation|inversion|duplication)/ix
          end
        end
      end
    end
  end
end
