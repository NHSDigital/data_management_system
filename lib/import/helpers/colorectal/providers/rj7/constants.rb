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
                                         'Carrier testing for known familial mutation(s)' => 'carrier',
                                         'Diagnostic testing for known mutation(s)' => 'diagnostic',
                                         'Family follow-up testing to aid variant interpretation' => 'diagnostic',
                                         'Predictive testing for known familial mutation(s)' => 'predictive',
                                         'Inherited MMR deficiency (Lynch syndrome)' => 'diagnostic',
                                         'Inherited colorectal cancer (with or without polyposis)' => 'diagnostic',
                                         'Inherited polyposis - germline test' => 'diagnostic',
                                         'APC associated Polyposis' => 'diagnostic'
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
                                        'R209' => %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN SMAD4 STK11],
                                        'Lynch (R210)' => %w[EPCAM MLH1 MSH2 MSH6 PMS2],
                                        'R211' => %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN SMAD4 STK11], #use from prior to 18.07.22 
                                        'R211_' => %w[APC BMPR1A EPCAM MLH1 MSH2 MSH6 MUTYH NTHL1 PMS2 POLD1 POLE PTEN SMAD4 STK11 GREM1 RNF43], #use from 18.07.22 onwards
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

                                    CRC_GENE_MAP =
                                    {
                                        'ATM' => ['ATM'],
                                        'BMPR1A' => ['BMPR1A'],
                                        'EPCAM' => ['EPCAM'],
                                        'GREM1' => ['GREM1'],
                                        'MLH1' => ['MLH1'],
                                        'MSH2' => %w[MSH2 MHS2],
                                        'MSH6' => ['MSH6'],
                                        'MUTYH' => ['MUTYH'],
                                        'NTHL1' => ['NTHL1'],
                                        'PMS2' => %w[PMS2 PMS],
                                        'POLD1' => ['POLD1'],
                                        'POLE' => ['POLE'],
                                        'PTEN' => ['PTEN'],
                                        'SMAD4' => ['SMAD4'],
                                        'STK11' => ['STK11'],
                                        'TP53' => ['TP53']
                                    }.freeze

                    TARGETED_TEST_STATUS = [{ column: 'gene (other)', expression: /FAIL|^Blank\scontamination/ix, status: 9, regex: 'regex' },
                                    { column: 'gene (other)', expression: /^het|del|dup|^c\./ix, status: 2, regex: 'regex' },
                                    { column: 'variant dna', expression: /^fail|^Blank\scontamination/ix, status: 9,regex: 'regex' },
                                    { column: 'variant dna', expression: /^Normal|no\sdel\/dup/ix, status: 1,regex: 'regex' },
                                    { column: 'variant dna', expression: /SNP\spresent|see\scomments/ix, status: 4,regex: 'regex' }, #Note this is in the context of 'c.1284T>C SNP present', where the designation of this benign variant as a SNP should override the regex 'c.*'
                                    { column: 'variant dna', expression: /het\sdel|het\sdup|het\sinv|^ex.*del|^ex.*dup|^ex.*inv|^del\sex|^dup\sex|^inv\sex|^c\./ix, status: 2, regex: 'regex' },
                                    { column: 'variant protein', expression: /p\./ix, status: 2, regex: 'regex' },
                                    { column: 'variant protein', expression: /fail/ix, status: 9, regex: 'regex' }].freeze
                    
                                    #FULL_SCREEN_TESTS_STATUS
                
              
          
            end
          end
        end
      end 
    end
  end

