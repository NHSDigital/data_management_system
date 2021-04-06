# This module stores the three-letter and single-letter representations
# of amino acids, principally so we can identify them in protein impact
# strings when needed
module Import
  module AminoAcids
    AMINO_ACID_CODE_MAP = { 'Ala' => 'A',
                            'Arg' => 'R',
                            'Asn' => 'N',
                            'Asp' => 'D',
                            'Asx' => 'B',
                            'Cys' => 'C',
                            'Glu' => 'E',
                            'Gln' => 'Q',
                            'Glx' => 'Z',
                            'Gly' => 'G',
                            'His' => 'H',
                            'Ile' => 'I',
                            'Leu' => 'L',
                            'Lys' => 'K',
                            'Met' => 'M',
                            'Phe' => 'F',
                            'Pro' => 'P',
                            'Ser' => 'S',
                            'Thr' => 'T',
                            'Trp' => 'W',
                            'Tyr' => 'Y',
                            'Val' => 'V',
                            'Ter' => '*' } .freeze
    def triplet_codes
      AMINO_ACID_CODE_MAP.keys.map(&:downcase)
    end
  end
end
