# for BRCA data
class CreateMolecularData < ActiveRecord::Migration[5.0]
  # - inflection for singular/plural changed in config/initializers/inflections.rb
  def change
    create_table :molecular_data, id: false do |t|
      t.primary_key  :molecular_dataid
      t.references   :ppatient, index: true # i.e. belongs_to (alias)

      t.text      :providercode         # ZProvider (NACS code if possible)
      t.text      :consultantcode       # GMC code if possible
      t.text      :patienttype          # routine/(NHS) or private
      t.decimal   :genetictestid, precision:19, scale:0
      t.date      :requesteddate
      t.date      :collecteddate
      t.date      :receiveddate
      t.date      :authoriseddate
      t.integer   :indicationcategory
      t.text      :clinicalindication
      t.integer   :moleculartestingtype
      t.text      :organisationcode_testresult
      t.text      :servicereportidentifier
      # [LOOKUP: ZSPECIMENTYPE] Nature of biological material tested (will be blood or buccal swab for BRCA testing)
      t.integer   :specimentype
      t.text      :otherspecimentype
      t.text      :tumourpercentage
      t.integer   :specimenprep
      t.integer   :karyotypingmethod
      # Indicate what part of the genome was tested (e.g. whole exome, single gene, specific mutation(s),
      # NGS panel, FISH probes, type/resolution of microarray etc.)
      # and give details of any bioinformatic filters that were applied.
      t.text      :genetictestscope
      t.text      :isresearchtest
      t.decimal   :genetictestresultid, precision:19, scale:0
      t.integer   :teststatus
      t.integer   :geneticaberrationtype
      t.text      :karyotypearrayresult
      t.integer   :rapidniptresult
      t.integer   :gene
      t.text      :gene_name            # [LOOKUP: ZGENE] 'BRCA1' OR 'BRCA2' (Use official HGNC symbol)
      t.text      :genotype
      t.integer   :zygosity
      t.text      :chromosomenumber
      t.text      :chromosomearm
      t.text      :cytogeneticband
      t.integer   :fusionpartnergene
      t.integer   :fusionpartnerchromosomenumber
      t.integer   :fusionpartnerchromosomearm
      t.text      :fusionpartnercytogeneticband
      t.integer   :msistatus
      t.text      :report
      t.integer   :geneticinheritance
      t.text      :percentmutantalabkaryotype
      # [ZGENETICINHERITANCE (CARA: ZINHERITANCE)]
      t.text      :originmutrearr       # Origin of the mutation/abnormality/aneuploidy/rearrangement/VUS
      # Only to be completed if data item above = Mosaic or Somatic. [so - don't need?]
      # Percentage of mutant allele / abnormality / aneuploidy in sample
      t.decimal   :pcmutallabkar, precision:3, scale:1        # percentage, with one place after decimal point
      t.text      :genmutloc            # Where in the gene the mutation is located (exon or intron number)
      t.text      :genmuttype           # [LOOKUP] Nature/class of mutation
      t.text      :muttrunc             # Whether the mutation is predicted to be truncating (Yes/No/Unknown)
      # If the mutation/rearrangement/zygosity cannot be described using standard nomenclature,
      # please enter details here. Any other observations about the mutation(s) can be entered here
      # (e.g. if >1 mutation, are they on the same allele?)
      t.text      :muttypecomment
    end
  end
end
