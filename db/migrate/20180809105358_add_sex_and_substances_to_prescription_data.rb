class AddSexAndSubstancesToPrescriptionData < ActiveRecord::Migration[5.0]
  def change
    # sex,form_type,chemical_substance_bnf,chemical_substance_bnf_descr,vmp_id,vmp_name,vtm_name
    # sex values are 0, 1, 2, 9
    add_column :prescription_data, :sex, :text
    add_column :prescription_data, :form_type, :text
    add_column :prescription_data, :chemical_substance_bnf, :text
    add_column :prescription_data, :chemical_substance_bnf_descr, :text
    add_column :prescription_data, :vmp_id, :bigint
    add_column :prescription_data, :vmp_name, :text
    add_column :prescription_data, :vtm_name, :text
  end
end
