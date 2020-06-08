# Change datatypes for id-related fields, including primary keys,
#  to be consistent with other (Oracle) systems, and for future expansion
#  with very large datasets.
# PostgreSQL bigserial sequence type is a bigint (8 bytes) with an auto_increment property,
# assigned the range 1 to 9223372036854775807.
# -- for birth/death/molecular/prescriptions data
class ChangePseudoFields < ActiveRecord::Migration[5.0]
  def change
    # --- primary keys ---
    # the order is important, due to foreign-key constraints
    change_column :ppatient_rawdata, :ppatient_rawdataid, :bigint

    change_column :ppatients, :id, :bigint
    change_column :ppatients, :ppatient_rawdata_id, :bigint

    change_column :birth_data, :birth_dataid, :bigint
    change_column :birth_data, :ppatient_id, :bigint

    change_column :death_data, :death_dataid, :bigint
    change_column :death_data, :ppatient_id, :bigint

    change_column :molecular_data, :molecular_dataid, :bigint
    change_column :molecular_data, :ppatient_id, :bigint
    change_column :molecular_data, :genetictestid, :bigint
    change_column :molecular_data, :genetictestresultid, :bigint

    change_column :prescription_data, :prescription_dataid, :bigint
    change_column :prescription_data, :ppatient_id, :bigint

    # --- not a primary key ---
    # percentage, with one place after decimal point
    change_column :molecular_data, :pcmutallabkar, :decimal, precision: 3, scale: 1
  end
end
