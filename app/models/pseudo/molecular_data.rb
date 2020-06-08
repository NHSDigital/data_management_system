# Molecular data
# - inflection for singular/plural changed in config/initializers/inflections.rb

module Pseudo
  # Molecular data, corresponding to Vgenetictest / Genetictestresult / Geneticsequencevariant
  # data in encore.
  # The nested tables are stored as JSONB objects in the genetictestresults fields
  class MolecularData < ActiveRecord::Base
    belongs_to :ppatient

    validates :ppatient_id, presence: true

    #validate :ensure_valid_genetictestresults_format

    #after_initialize :populate_genetictestresults

    GENETICTESTRESULTS_KEYS = %w(
      teststatus geneticaberrationtype karyotypearrayresult rapidniptresult gene genotype
      zygosity chromosomenumber chromosomearm cytogeneticband fusionpartnergene
      fusionpartnerchromosomenumber fusionpartnerchromosomearm fusionpartnercytogeneticband
      msistatus report geneticinheritance percentmutantalabkaryotype oncotypedxbreastrecurscore
      geneticsequencevariants raw_record
    ).freeze

    GENETICSEQUENCEVARIANT_KEYS = %w(
      humangenomebuild referencetranscriptid genomichange codingdnasequencechange proteinimpact
      clinvarid cosmicid variantpathclass variantlocation exonintroncodonnumber genomicchange
      sequencevarianttype variantimpact variantreport variantgenotype variantallelefrequency raw_recordxf
    ).freeze

    private

    # Ensure that genetictestresults correctly correspond to the expected structure
    # To extract records, use something like:
    # SQL> select * from molecular_data, jsonb_array_elements(genetictestresults)
    #      p(genetictestresult_row), jsonb_to_record(genetictestresult_row) as x(a int, b text);
    def ensure_valid_genetictestresults_format
      unless genetictestresults.is_a?(Array)
        errors.add(:genetictestresults, 'is not an array')
        return
      end
      genetictestresults.each_with_index do |gtr, i|
        unless gtr.is_a?(Hash)
          errors.add(:genetictestresults, "genetictestresult[#{i}] is not a hash")
          next
        end
        bad_keys = gtr.keys - GENETICTESTRESULTS_KEYS
        if bad_keys.present?
          errors.add(:genetictestresults,
                     "genetictestresult[#{i}] has invalid keys #{bad_keys.inspect}")
          next
        end
        geneticsequencevariants = gtr['geneticsequencevariants']
        next if geneticsequencevariants.nil?
        unless geneticsequencevariants.is_a?(Array)
          errors.add(:genetictestresults,
                     "genetictestresult[#{i}]['geneticsequencevariants'] is not an array")
          next
        end
        geneticsequencevariants.each_with_index do |gsv, j|
          unless gsv.is_a?(Hash)
            errors.add(:genetictestresults,
                       "genetictestresult[#{i}]['geneticsequencevariants'][#{j}] is not a hash")
            next
          end
          bad_keys2 = gsv.keys - GENETICSEQUENCEVARIANT_KEYS
          if bad_keys2.present?
            errors.add(:genetictestresults, "genetictestresult[#{i}]['geneticsequencevariants']" \
                                            "[#{j}] has invalid keys #{bad_keys2.inspect}")
          end
        end
      end
    end

    # Ensure genetictestresults is always an array
    def populate_genetictestresults
      self.genetictestresults ||= []
    end
  end
end
