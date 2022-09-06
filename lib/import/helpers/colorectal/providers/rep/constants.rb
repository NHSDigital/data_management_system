module Import
  module Helpers
    module Colorectal
      module Providers
        module Rep
          module Constants
            PASS_THROUGH_FIELDS = %w[age sex consultantcode requesteddate
                                     authoriseddate servicereportidentifier
                                     providercode receiveddate specimentype].freeze

            TEST_SCOPE_MAP = { 'full gene screen' => :full_screen,
                               'partial gene screen' => :full_screen,
                               'targeted mutation analysis' => :targeted_mutation,
                               'targeted mutation panel' => :aj_screen }.freeze

            TEST_STATUS_MAP = { 'no variants detected' => 1,
                                'heterozygous variant detected' => 2,
                                'heterozygous variant detected (mosaic)' => 2,
                                'fail - cannot interpret data' => 9 }.freeze

            # rubocop:disable Lint/MixedRegexpCaptureTypes
            CDNA_REGEX = /c\.?,?\[?(?<cdna>
                                ([0-9]+[+>_-][0-9][+>_-][0-9]+[+>_-][0-9][ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9][+>_-][0-9]+[+>_-][0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9]+[ACGTdelinsup][+>_-][ACGTdelinsup])|
                                ([0-9]+[ACGTdelinsup]+[+>_-][ACGTdelinsup])|
                                ([0-9]+[+>_-][0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[+>_-][0-9]+[ACGTdelinsup]?)|
                                ([0-9]+[+>_-][0-9]+[+>_-][0-9]+[0-9]+[ACGTdelinsup]+)|
                                ([0-9]+[?+>_-]+[0-9]+[?+>_-]+[ACGTdelinsup]+)|
                                ([0-9]+[ACGTdelinsup]+)|
                                ([+>_-][0-9]+[ACGTdelinsup>]+)
                                )\]?/ix

            EXON_VARIANT_REGEX = /(?<variant>del|dup|ins).+ex(?<on>on)?(?<s>s)?\s
                                  (?<exons>[0-9]+(?<dgs>-[0-9]+)?)|
                                ex(?<on>on)?(?<s>s)?\s?(?<exons>[0-9]+(?<dgs>-[0-9]+)?)\s?
                                (?<variant>del|dup|ins)|
                                (?<variant>del|dup|ins)\sexon(?<s>s)?\s
                                (?<exons>[0-9]+(?<dgs>\sto\s[0-9]+))|
                                ex(on)?(s)?\s?(?<exons>[0-9]+\s?(\s?-\s?[0-9]+)?)\s?
                                (?<variant>del|dup|ins)?|
                                (?<variant>del|dup|ins)(?<s>\s)?(?<exons>[0-9]+(?<dgs>-[0-9]+)?)|
                                ex(?<on>on)?(?<s>s)?\s(?<exons>[0-9]+(?<dgs>\sto\s[0-9]+)?)\s
                                (?<variant>del|dup|ins)|
                                x(?<exons>[0-9]+-?[0-9]+)\s?(?<variant>del|dup|ins)|
                                x(?<exons>[0-9]+-?[0-9]?)\s?(?<variant>del|dup|ins)/ix

            PROTEIN_REGEX = /p\.[\[(]?(?<impact>([a-z]+[0-9]+[a-z]+([^[:alnum:]][0-9]+)?)|
                                   ([a-z]+[0-9]+[^[:alnum:]]))[)\]]?/ix
            # rubocop:enable Lint/MixedRegexpCaptureTypes
          end
        end
      end
    end
  end
end
