module Import
  module Helpers
    module Colorectal
      module Providers
        module Kgc
          # Constants used by LondonKgcHandlerColorectal
          module KgcConstants
            PASS_THROUGH_FIELDS_COLO = %w[age sex consultantcode collecteddate receiveddate
                                          authoriseddate servicereportidentifier providercode].freeze

            LYNCH = /Trusight Cancer panel\: lynch syndrome|Bowel Cancer|Colorectal Cancer|Lynch Syndrome|Lynch syndrome/i .freeze
            LYNCH_SPECIFIC = /(?<override>for MSH6 testing|loss MLH1 and PMS2|Loss MLH1\- PMS2|Loss of MSH2 and MSH6 on IHC \+ history of endometrial and ovarian cancer|MLH1 and PMS2|MLH1 testing|MSH1\/MSH2\/MSH6 testing|msh2 \& msh6 TESTING|MSH2 and MSH6 \(if req\'d\)|MSH2 exon 5 reanalysis|MSH2 reanalysis requested|MSH6 testing)/i .freeze
            MSH2_6 = /Loss MSH2\/6/i .freeze
            NON_LYNCH_REGEX = /Familial Adenomatous Polyposis|MAP|MUTYH common testing|MUTYH\-associated Polyposis|Trusight Cancer panel\: APC\, MUTYH|Polyp panel including POLD\/E\.|Polyp panel|Polyposis genes|MUTYH-associated Polyposis\, POLD1\/POLE|Pol Proof-reading Polyposis|POLE\/POLD1|pole\/pold1 testing|POLE\/POLD1 testing as well|Peutz Jeghers Syndrome|req\. STK11 testing|stk11 testing|Cowden syndrome|PTEN Harmatoma Tumour Syn\.|For PTEN and renal cancer panel in Birmingham|Juvenile Polyposis Syndrome|SMAD4 testing requested|Hered Mixed Polyposis|GREM1|Full MYH and GREM1|Requeste full MYH and GREM1/i .freeze
            EXON_REGEX = /ex(?:on) (?<exno>[0-9]{1,2}(-[0-9]{1,2})?).+(?<deldupins>(del|dup|ins))|(?<deldupins>(del|dup|ins)).+ex(?:on(s)?) (?<exno>[0-9]{1,2}(-[0-9]{1,2})?)/i .freeze
            CDNA_REGEX = /c\.(?<dna>[0-9]+([a-z]+|[^[:alnum:]])([0-9]+[a-z]+>[a-z]|[0-9]+[a-z]+|[^[:alnum:]][a-z]+))/i .freeze
            PROTEIN_REGEX_COLO = /p\.(\(|\[)?(?<impact>[a-z]+[0-9]+([a-z]+[^[:alnum:]]|[a-z]+|[^[:alnum:]]))/i .freeze
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

            NON_LYNCH_MAP = { 'Familial Adenomatous Polyposis' => 'APC',
                              'MAP' => 'MUTYH',
                              'MUTYH common testing' => 'MUTYH',
                              'MUTYH-associated Polyposis' => 'MUTYH',
                              'Trusight Cancer panel: APC, MUTYH' => %w[APC MUTYH],
                              'Polyp panel' => %w[APC MUTYH],
                              'Polyposis genes' => %w[APC MUTYH],
                              'Polyp panel including POLD/E.' => %w[APC MUTYH POLD1 POLE],
                              'MUTYH-associated Polyposis, POLD1/POLE' => %w[MUTYH POLD1 POLE],
                              'Pol Proof-reading Polyposis' => %w[POLD1 POLE],
                              'POLE/POLD1' => %w[POLD1 POLE],
                              'pole/pold1 testing' => %w[POLD1 POLE],
                              'POLE/POLD1 testing as well' => %w[POLD1 POLE],
                              'Peutz Jeghers Syndrome' => 'STK11',
                              'req. STK11 testing' => 'STK11',
                              'stk11 testing' => 'STK11',
                              'Cowden syndrome' => 'PTEN',
                              'PTEN Harmatoma Tumour Syn.' => 'PTEN',
                              'For PTEN and renal cancer panel in Birmingham' => 'PTEN',
                              'Juvenile Polyposis Syndrome' => %w[SMAD4 BMPR1A],
                              'SMAD4 testing requested' => 'SMAD4',
                              'Hered Mixed Polyposis' => 'GREM1',
                              'GREM1' => 'GREM1',
                              'Full MYH and GREM1' => %w[MUTYH GREM1],
                              'Requeste full MYH and GREM1' => %w[MUTYH GREM1],
                              'requested APC- MUTYH-SMAD4-MLH1- MLH2- MLH6 testing' => %w[APC MUTYH SMAD4 MLH1 MSH2 MSH6],
                              'Trusight Cancer panel: APC, MUTYH, STK11, PTEN, JPS' => %w[APC MUTYH STK11 PTEN SMAD4 BMPR1A] } .freeze

            LYNCHGENES = %w[MLH1 MSH2 MSH6 EPCAM].freeze

            # The following is for "rogue" genotypes that needed to be
            # Manually extracted.
            LYNCHGENE_PROCESS_METHODS = {
              'MSH2 ex1-6 duplication'                         => :lynchgene_msh2_ex1_6,
              'MSH2 c.1760-2_1783del p.(Gly587Aspfs*6)'        => :lynchgene_msh2_c_1760_2,
              'MSH2 del exon11'                                => :lynchgene_msh2_del_exon11,
              'MSH2 ex11del'                                   => :lynchgene_msh2_ex11del,
              'MLH1 c.532delG'                                 => :lynchgene_msh2_c_532del,
              'Deletion including EPCAM ex2-9 and MSH2 ex 1-5' => :lynchgene_deletion_epcam,
              'No mutation detected in MLH1'                   => :lynchgene_no_mutation,
              'MSH2 ex7del'                                    => :lynchgene_msh2_ex7del
            }.freeze

            # The following is for "rogue" non_lynch genotypes that needed to be
            # Manually extracted.
            NON_LYNCHGENE_PROCESS_METHODS = {
              'APC promoter 1B deletion (single probe)' => :non_lynchgene_apc_promoter_1b,
              'APC c.423-34_423-17delinsA'              => :non_lynchgene_apc_c423_34_423,
              'APC ex10-18del'                          => :non_lynchgene_apc_ex10_18del,
              'MUTYH p.Glu480* homozygote'              => :non_lynchgene_mutyh_p_glu480,
              'STK11 ex1-10del'                         => :non_lynchgene_stk11_ex1_10del
            }.freeze

            # The following is for "rogue" union lynch genotypes that needed to be
            # Manually extracted.
            UNION_LYNCHGENE_PROCESS_METHODS = {
              'BMPR1A: c.972dupT' => :union_lynchgene_bmpr1a,
              'APC c.1880dupA'    => :union_lynchgene_apc,
              'MSH6 c.*24_28del'  => :union_lynchgene_msh6
            }.freeze

            NEGATIVE_TEST_LOG = 'SUCCESSFUL gene parse for negative test for'.freeze
            NEGATIVE_LYNCH_SPECIFIC_TEST_LOG = 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                                                'LYNCH SPECIFIC for'.freeze
            NEGATIVE_NON_LYNCH_TEST_LOG = 'SUCCESSFUL gene parse for NEGATIVE test ' \
                                           'IN NON LYNCH for'.freeze

            NEGATIVE_LYNCH_AND_NON_LYNCH_TEST_LOG = 'SUCCESSFUL gene parse for NEGATIVE test ' \
                                                    'in LYNCH AND NON-LYNCH for'.freeze

            MSH2_MSH6_GENES = %w[MSH2 MSH6].freeze
          end
        end
      end
    end
  end
end
