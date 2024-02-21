module Import
  module Helpers
    module Colorectal
      module Providers
        module Rth
          # Constants used by OxfordColorectal
          module Constants
            TEST_METHOD_MAP = { 'Sequencing, Next Generation Panel (NGS)' => :ngs,
                                'Sequencing, Dideoxy / Sanger'            => :sanger }.freeze

            PASS_THROUGH_FIELDS = %w[age consultantcode
                                     servicereportidentifier
                                     providercode
                                     authoriseddate
                                     requesteddate
                                     sampletype
                                     referencetranscriptid].freeze

            COLORECTAL_GENES_REGEX = /(?<colorectal>ACD|
                                      APC|
                                      ATM|
                                      BAP1|
                                      BARD1|
                                      BLM|
                                      BMPR1A|
                                      BRCA1|
                                      BRCA2|
                                      BRIP1|
                                      CDH1|
                                      CDK4|
                                      CDKN2A|
                                      CDKN2B|
                                      CHEK2|
                                      EPCAM|
                                      FH|
                                      FLCN|
                                      GREM1|
                                      KIT|
                                      MEN1|
                                      MET|
                                      MLH1|
                                      MRE11A|
                                      MSH2|
                                      MSH6|
                                      MUTYH|
                                      NBN|
                                      NTHL1|
                                      PALB2|
                                      PDGFRA|
                                      PMS2|
                                      POLD1|
                                      POLE|
                                      POT1|
                                      PTCH1|
                                      PTEN|
                                      RAD50|
                                      RAD51C|
                                      RAD51D|
                                      RET|
                                      RHOA|
                                      RNF43|
                                      SDHA|
                                      SDHAF2|
                                      SDHB|
                                      SDHC|
                                      SDHD|
                                      SMAD4|
                                      STK11|
                                      TERF2IP|
                                      TERT|
                                      TP53|
                                      VHL)/xi

            FULL_SCREEN_REGEX = /(?<fullscreen>Panel|
                                full\sgene|
                                full\s?screen|
                                full\sscreem|
                                exons\s8-13|
                                exons\s9-14|
                                APC\sCNV\sanalysis|
                                HCS|
                                CNV.*only|
                                CNV.*analysis|
                                SNV.*only|
                                whole\sgene\sscreen)/xi
            # rubocop:disable Lint/MixedRegexpCaptureTypes
            PROTEIN_REGEX            = /p\.\[(?<impact>(.*?))\]|p\..+/i
            CDNA_REGEX               = /c\.\[?(?<cdna>[-0-9?.>_+a-z]+)\]?/i
            GENOMICCHANGE_REGEX      = /Chr(?<chromosome>\d+)\.hg(?<genome_build>\d+)
                                       :g\.(?<effect>.+)/xi
            VAR_PATH_CLASS_MAP = {
              'c3' => 3,
              'c4' => 4,
              'c5' => 5,
              '10' => '',
              'n/a' => ''
            }.freeze
            CHROMOSOME_VARIANT_REGEX = /(?<chromvar>del|ins|dup|inv)/i
            # rubocop:enable Lint/MixedRegexpCaptureTypes
          end
        end
      end
    end
  end
end
