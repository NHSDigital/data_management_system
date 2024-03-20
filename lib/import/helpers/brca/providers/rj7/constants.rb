module Import
  module Helpers
    module Brca
      module Providers
        module Rj7
          module Constants
            PASS_THROUGH_FIELDS = %w[age sex consultantcode requesteddate
                                     authoriseddate servicereportidentifier
                                     providercode receiveddate specimentype].freeze

            TEST_TYPE_MAP =
                            {
                            'Diagnostic testing for known mutation(s)' => 'diagnostic',
                            'Family follow-up testing to aid variant interpretation' => 'diagnostic',
                            'Inherited breast cancer and ovarian cancer' => 'diagnostic',
                            'Inherited ovarian cancer (without breast cancer)' => 'diagnostic',
                            'Predictive testing for known familial mutation(s)' => 'predictive',
                            }.freeze

            TEST_SCOPE_MAP =
                            {
                            'Diagnostic testing for known mutation(s)' => 'targeted',
                            'Family follow-up testing to aid variant interpretation' => 'targeted',
                            'Inherited breast cancer and ovarian cancer' => 'fullscreen',
                            'Inherited ovarian cancer (without breast cancer)' => 'fullscreen',
                            'Predictive testing for known familial mutation(s)' => 'targeted',
                            }.freeze

            FULL_SCREEN_TESTS_MAP =
                            {
                            'BRCA1/2_V1' => ['BRCA1', 'BRCA2'],
                            'CHEK2_v1' => ['CHEK2'],
                            'HBOC_V1' => ['BRCA1', 'BRCA2', 'CHEK2', 'PALB2'],
                            'HBOC_v2' => ['BRCA1', 'BRCA2', 'PALB2'],
                            'TP53_V1' => ['TP53'],
                            'MLPA' => [],
                            'SANGER' => [],
                            'VUS check' => [] ,
                            'RPKM' => [],
                            'R207' => ['BRCA1', 'BRCA2', 'BRIP1', 'MLH1', 'MSH2', 'MSH6', 'PALB2', 'RAD51C', 'RAD51D'],
                            'R208+C' => ['BRCA1', 'BRCA2', 'CHEK2', 'PALB2'],
                            }.freeze


            BRCA_GENE_REGEX=/ATM|ATM-1|BRCA1\/2|BRCA1\+2|BRCA1|BR1|BRCA1\/2|BRCA2|BR2|BRIP1|CHEK2
                            |CHECK2|EPCAM|MLH1|MSH2|MSH6|PALB2|PALB1|PLAB2|PMS2|RAD51C|RAD51D|TP53/ix


            BRCA_GENE_MAP={
                        "ATM" => ['ATM'],
                        "ATM-1" => ['ATM'],
                        "BRCA1/2" => ['BRCA1', 'BRCA2'],
                        "BRCA1+2" => ['BRCA1', 'BRCA2'],
                        "BRCA1" => ['BRCA1'],
                        "BR1" => ['BRCA1'],
                        "BRCA2" => ['BRCA2'],
                        "BR2" => ['BRCA2'],
                        "BRIP1"=>['BRIP1'],
                        "CHEK2"=>['CHEK2'],
                        "CHECK2"=>['CHEK2'],
                        "EPCAM"=>['EPCAM'],
                        "MLH1"=>['MLH1'],
                        "MSH2"=>['MSH2'],
                        "MSH6"=>['MSH6'],
                        "PALB2"=>['PALB2'],
                        "PALB1"=>['PALB2'],
                        "PLAB2"=>['PALB2'],
                        "PMS2"=>['PMS2'],
                        "RAD51C"=>['RAD51C'],
                        "RAD51D"=>['RAD51D'],
                        "TP53"=>['TP53'],
                        }.freeze


            # in order of priority
            TARGETED_TEST_STATUS = [{column:'gene(other)', expression:/Fail/ix, status: 9, regex:'regex'},
                                   {column: 'gene(other)', expression: /het|del|dup|c\./ix, status:2, regex:'regex'},
                                   {column:'variant dna', expression:/Fail|Wrong\samplicon\stested/ix, status: 9, regex:'regex'},
                                   {column:'variant dna', expression:'N', status: 1, regex: 'match'},
                                   {column:'variant dna', expression:/het|del|dup|c\./ix, status:2, regex:'regex'},
                                   {column:'variant protein', expression:'N', status:1, regex:'match'},
                                   {column:'variant protein', expression:'nil', status:4, regex:'match'},
                                   ]


            EXON_REGEX =/((?<zygosity>Het)\s?(?<mutationtype>dup|del)\s?(\.\s?)?ex\s?(?<exons>[0-9]+(\-(ex)?[0-9]+)?) |
              (?<mutationtype>del)\s?ex\s?(?<exons>[0-9]+_[0-9]+) |
              ex(on)?\s?(?<exons>[0-9]+(\-[0-9]+)?)\s?(?<zygosity>Het)?\s?(?<mutationtype>del(etion)?|dup))/ix

            # rubocop:enable Lint/MixedRegexpCaptureTypes
        end
    end
  end
end
end
end