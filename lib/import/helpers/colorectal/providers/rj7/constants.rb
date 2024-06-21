module Import
    module Helpers
      module Colorectal
        module Providers
          module Rj7
            module Constants
              PASS_THROUGH_FIELDS = %w[age sex consultantcode requesteddate
                                       authoriseddate servicereportidentifier
                                       providercode receiveddate specimentype].freeze
  
              TEST_TYPE_MAP =
                {
                  'carrier testing for known familial mutation(s)' => :carrier,
                  'diagnostic testing for known mutation(s)' => :diagnostic,
                  'predictive testing for known familial mutation(s)' => :predictive,
                  'apc associated polyposis' => :diagnostic
                }.freeze
  
              TEST_SCOPE_MAP =
                {
                  'carrier testing for known familial mutation(s)' => :targeted_mutation,
                  'diagnostic testing for known mutation(s)' => :targeted_mutation,
                  'family follow-up testing to aid variant interpretation' => :targeted_mutation,
                  'predictive testing for known familial mutation(s)' => :targeted_mutation,
                  'inherited mmr deficiency (lynch syndrome)' => :full_screen,
                  'inherited colorectal cancer (with or without polyposis)' => :full_screen,
                  'inherited polyposis - germline test' => :full_screen,
                  'apc associated polyposis' => :full_screen
                }.freeze
  
              FULL_SCREEN_TESTS_MAP =
                {
                  'r209' => %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1
                               PMS2 POLD1 POLE PTEN SMAD4 STK11],
                  'lynch (r210)' => %w[EPCAM MLH1 MSH2 MSH6 PMS2],
                  'r414' => ['APC'],
                  'polyedge' => [],
                  'exomedepth' => [],
                  'rpkm_0723' => [],
                  'lr-pcr' => [],
                  'mlpa' => [],
                  'rpkm' => [],
                  'sanger' => [],
                  'vus check' => []
                }.freeze
  
              CRC_GENE_REGEX = /APC|
                              BMPR1A|
                              EPCAM|
                              GREM1|
                              MLH1|
                              MSH2|
                              MHS2|
                              MSH6|
                              MUTYH|
                              NTHL1|
                              PMS2|
                              PMS|
                              POLD1|
                              POLE|
                              PTEN|
                              SMAD4|
                              STK11|
                              TP53|
                              RNF43|
                              ATM/ix
  
              CRC_GENE_MAP =
                {
                  'APC' => ['APC'],
                  'BMPR1A' => ['BMPR1A'],
                  'EPCAM' => ['EPCAM'],
                  'GREM1' => ['GREM1'],
                  'MLH1' => ['MLH1'],
                  'MSH2' => ['MSH2'],
                  'MHS2' => ['MSH2'],
                  'MSH6' => ['MSH6'],
                  'MUTYH' => ['MUTYH'],
                  'NTHL1' => ['NTHL1'],
                  'PMS2' => ['PMS2'],
                  'PMS' => ['PMS2'],
                  'POLD1' => ['POLD1'],
                  'POLE' => ['POLE'],
                  'PTEN' => ['PTEN'],
                  'SMAD4' => ['SMAD4'],
                  'STK11' => ['STK11'],
                  'TP53' => ['TP53'],
                  'RNF43' => ['RNF43'],
                  'ATM' => ['ATM']
                }.freeze
  
              EXON_REGEX = /((?<zygosity>Het)\s?(?<mutationtype>dup|del)\s?.+(\.\s?)?ex\s?(?<exons>[0-9]+(-(ex)?[0-9]+)?) |
                (?<mutationtype>del)\s?ex\s?(?<exons>[0-9]+_[0-9]+) |
                ex(on)?\s?(?<exons>[0-9]+(-[0-9]+)?)\s?(?<zygosity>Het)?\s?(?<mutationtype>del(etion)?|dup))/ix
            end
          end
        end
      end
    end
  end
  