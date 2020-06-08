module Export
  # Export and de-pseudonymise annual Viral Hepatitis death extract
  # Specification file: "Viral Hepititis 2016.pdf"
  # Specification updated in plan.io #9852:
  # Can you re run the 2016 extract but with the following fields only:
  # dester podt icd9_icd10 icd9f_icd10f icd9sc_icd10sc icd9scf_icd10scf icd9u_icd10u
  # icd9uf_icd10uf pcdpod doddy dodmt dodyr pcdr dobdy dobmt dobyr sex linen09_lneno10
  # lineno9f_lneno10f codt agec ctrypob occtype pobt occhft occmt dor occdt cod10r cod10rf
  #  ctryr ctyr occfft codfft
  # Specification updated in plan.io #17015:
  # The same fields as before, but with additional ICD codes in extraction pattern
  class ViralHepatitisDeathsFile3 < ViralHepatitisDeathsFile2
    # Codes extracted are B15-B19 C22 I85 (I85.0 + I85.9) I98.2, I98.3, K70-77 P35.3 R16, R17, R18
    SURVEILLANCE_PATTERN = /\A(C22|I85|I98[23]|B1[5-9]|K7[0-7]|P353|R1[6-8])/.freeze
  end
end
