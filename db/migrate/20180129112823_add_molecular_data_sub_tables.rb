class AddMolecularDataSubTables < ActiveRecord::Migration[5.0]
  def change
    create_table :genetic_test_results, id: false do |t|
      t.primary_key  :genetictestresultid
      t.references   :molecular_data, index: true
      t.decimal      :teststatus, precision:19, scale:0
      t.decimal      :geneticaberrationtype, precision:19, scale:0
      t.text         :karyotypearrayresult
      t.decimal      :rapidniptresult, precision:19, scale:0
      t.text         :gene
      t.text         :genotype
      t.decimal      :zygosity, precision:19, scale:0
      t.decimal      :chromosomenumber, precision:19, scale:0
      t.decimal      :chromosomearm, precision:19, scale:0
      t.text         :cytogeneticband
      t.text         :fusionpartnergene
      t.decimal      :fusionpartnerchromosomenumber, precision:19, scale:0
      t.decimal      :fusionpartnerchromosomearm, precision:19, scale:0
      t.text         :fusionpartnercytogeneticband
      t.decimal      :msistatus, precision:19, scale:0
      t.text         :report
      t.decimal      :geneticinheritance, precision:19, scale:0
      t.text         :percentmutantalabkaryotype
      t.decimal      :oncotypedxbreastrecurscore, precision:19, scale:0
      t.text         :raw_record
    end
    
    create_table :genetic_sequence_variants, id: false do |t|
      t.primary_key  :geneticsequencevariantid
      t.references   :genetic_test_result, index: true
      #t.integer      :genetictestresultid
      t.decimal      :humangenomebuild, precision:19, scale:0
      t.text         :referencetranscriptid
      t.text         :genomicchange
      t.text         :codingdnasequencechange
      t.text         :proteinimpact
      t.text         :clinvarid
      t.text         :cosmicid
      t.decimal      :variantpathclass, precision:19, scale:0
      t.decimal      :variantlocation, precision:19, scale:0
      t.text         :exonintroncodonnumber
      t.decimal      :sequencevarianttype, precision:19, scale:0
      t.decimal      :variantimpact, precision:19, scale:0
      t.decimal      :variantgenotype, precision:19, scale:0
      t.float        :variantallelefrequency
      t.text         :variantreport
      t.text         :raw_record
    end
  end
end
