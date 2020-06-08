# Move nested -> Genetictestresult -> Geneticsequencevariant data to a JSONB field in table MolecularData, with structure similar to era codebase
# (Vgenetictest = Event + Genetictest)
class AddJsonbToMolecularData < ActiveRecord::Migration[5.0]
  def change
    add_column :molecular_data, :genetictestresults, :jsonb
    # add_foreign_key :vgenetictest, :ppatients, column: :ppatient_id, primary_key: 'id', on_delete: :cascade, name: :vgenetictest_ppatients_fk
    # Rename for consistency with Vgenetictest
    rename_column :molecular_data, :consultantcode, :practitionercode
    # Nested data fields will move to JSONB field :genetictestresults
    remove_column :molecular_data, :genetictestid, :bigint
    remove_column :molecular_data, :genetictestresultid, :integer, precision:19, scale:0
    remove_column :molecular_data, :teststatus, :integer
    remove_column :molecular_data, :geneticaberrationtype, :integer
    remove_column :molecular_data, :karyotypearrayresult, :text
    remove_column :molecular_data, :rapidniptresult, :integer
    remove_column :molecular_data, :gene, :integer
    remove_column :molecular_data, :genotype, :text
    remove_column :molecular_data, :zygosity, :integer
    remove_column :molecular_data, :chromosomenumber, :text
    remove_column :molecular_data, :chromosomearm, :text
    remove_column :molecular_data, :cytogeneticband, :text
    remove_column :molecular_data, :fusionpartnergene, :integer
    remove_column :molecular_data, :fusionpartnerchromosomenumber, :integer
    remove_column :molecular_data, :fusionpartnerchromosomearm, :integer
    remove_column :molecular_data, :fusionpartnercytogeneticband, :text
    remove_column :molecular_data, :msistatus, :integer
    remove_column :molecular_data, :report, :text
    remove_column :molecular_data, :geneticinheritance, :integer
    remove_column :molecular_data, :percentmutantalabkaryotype, :text
    # Columns in molecular_data not in encore
    remove_column :molecular_data, :gene_name, :text
    remove_column :molecular_data, :originmutrearr, :text
    remove_column :molecular_data, :pcmutallabkar, :integer, precision:3, scale:1
    remove_column :molecular_data, :genmutloc, :text
    remove_column :molecular_data, :genmuttype, :text
    remove_column :molecular_data, :muttrunc, :text
    remove_column :molecular_data, :muttypecomment, :text
  end
end
