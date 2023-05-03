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

            COLORECTAL_GENES_REGEX = /(?<colorectal>APC|
                                                  BMPR1A|
                                                  EPCAM|
                                                  MLH1|
                                                  MSH2|
                                                  MSH6|
                                                  MUTYH|
                                                  GREM1|
                                                  PMS2|
                                                  POLD1|
                                                  POLE|
                                                  PTEN|
                                                  SMAD4|
                                                  STK11|
                                                  NTHL1)/xi

            FULL_SCREEN_REGEX = /(?<fullscreen>Panel|
            full\sgene\sscreen|
            full.+screen|
            full.+screem|
            fullscreen|
            BRCA_Multiplicom|
            HCS|
            BRCA1|
            BRCA2)/xi
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
