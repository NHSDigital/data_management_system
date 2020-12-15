module Import
  module Helpers
    module Colorectal
      module Providers
        module Rq3
          module Rq3Constants
            PASS_THROUGH_FIELDS_COLO = %w[age sex consultantcode servicereportidentifier providercode
                                          authoriseddate receiveddate moleculartestingtype
                                          specimentype].freeze

            TEST_SCOPE_MAP_COLO_COLO = { '100kgp confirmation'  => :full_screen,
                                         'carrier testing'      => :targeted_mutation,
                                         'confirmation'         => :targeted_mutation,
                                         'diagnosis'            => :full_screen,
                                         'family studies'       => :targeted_mutation,
                                         'follow-up'            => :targeted_mutation,
                                         'indirect testing'     => :full_screen,
                                         'pold1/ pole analysis' => :full_screen,
                                         'prenatal diagnosis'   => :targeted_mutation,
                                         'presymptomatic'       => :targeted_mutation }.freeze

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
                                                  STK11)/xi .freeze

            COLORECTAL_GENES_MAP = { 'PJS' =>        'STK11',
                                     'PHTS' =>       'PTEN',
                                     'MAP' =>        'MUTYH',
                                     'FAP' =>        'APC',
                                     'PPAP' =>       %w[POLE POLD1],
                                     'COCA' =>       %w[MLH1 MSH2],
                                     'POLY' =>       %w[APC MUTYH],
                                     'NGS_COLON' =>  %w[MLH1 MSH2 MSH6 APC MUTYH],
                                     'COLON' =>      %w[MLH1 MSH2 MSH6 PMS2 APC MUTYH PTEN SMAD4 BMPR1A STK11],
                                     'HNPCC'  =>     %w[MLH1 MSH2 MSH6 PMS2 EPCAM] } .freeze

            CDNA_REGEX_COLO = /c\.(?<cdna>.*)/i.freeze
            PROTEIN_REGEX_COLO = /p.(?:\((?<impact>.*)\))/.freeze
            EXON_LOCATION_REGEX_COLO = /exons? (\d+[a-z]*(?: ?- ?\d+[a-z]*)?)/i.freeze

          end
        end
      end
    end
  end
end
