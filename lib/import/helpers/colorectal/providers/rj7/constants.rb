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
                'Carrier testing for known familial mutation(s)' => :carrier,
                'Diagnostic testing for known mutation(s)' => :diagnostic,
                'Family follow-up testing to aid variant interpretation' => :diagnostic,
                'Predictive testing for known familial mutation(s)' => :predictive,
                'Inherited MMR deficiency (Lynch syndrome)' => :diagnostic,
                'Inherited colorectal cancer (with or without polyposis)' => :diagnostic,
                'Inherited polyposis - germline test' => :diagnostic,
                'APC associated Polyposis' => :diagnostic
              }.freeze

            TEST_SCOPE_MAP =
              {
                'Carrier testing for known familial mutation(s)' => 'targeted',
                'Diagnostic testing for known mutation(s)' => 'targeted',
                'Family follow-up testing to aid variant interpretation' => 'targeted',
                'Predictive testing for known familial mutation(s)' => 'targeted',
                'Inherited MMR deficiency (Lynch syndrome)' => 'fullscreen',
                'Inherited colorectal cancer (with or without polyposis)' => 'fullscreen',
                'Inherited polyposis - germline test' => 'fullscreen',
                'APC associated Polyposis' => 'fullscreen'
              }.freeze

            FULL_SCREEN_TESTS_MAP =
              {
                'R209' => %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1
                             PMS2 POLD1 POLE PTEN SMAD4 STK11],
                'Lynch (R210)' => %w[EPCAM MLH1 MSH2 MSH6 PMS2],
                'R414' => ['APC'],
                'Polyedge' => [],
                'ExomeDepth' => [],
                'RPKM_0723' => [],
                'LR-PCR' => [],
                'MLPA' => [],
                'RPKM' => [],
                'SANGER' => [],
                'VUS check' => []
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

            EXON_REGEX = /((?<zygosity>Het)\s?(?<mutationtype>dup|del)\s?(\.\s?)?ex\s?(?<exons>[0-9]+(-(ex)?[0-9]+)?) |
              (?<mutationtype>del)\s?ex\s?(?<exons>[0-9]+_[0-9]+) |
              ex(on)?\s?(?<exons>[0-9]+(-[0-9]+)?)\s?(?<zygosity>Het)?\s?(?<mutationtype>del(etion)?|dup))/ix
          end
        end
      end
    end
  end
end
