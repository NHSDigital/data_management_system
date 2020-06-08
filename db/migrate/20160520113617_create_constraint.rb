# Add foreign-key constraints to tables
class CreateConstraint < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :ppatients, :e_batch, column: :e_batch_id, primary_key: 'e_batchid'
    add_foreign_key :ppatients, :ppatient_rawdata, column: :ppatient_rawdata_id, primary_key: 'ppatient_rawdataid'

    add_foreign_key :birth_data, :ppatients, column: :ppatient_id, primary_key: 'id', on_delete: :cascade
    add_foreign_key :death_data, :ppatients, column: :ppatient_id, primary_key: 'id', on_delete: :cascade
    add_foreign_key :molecular_data, :ppatients, column: :ppatient_id, primary_key: 'id', on_delete: :cascade
    add_foreign_key :prescription_data, :ppatients, column: :ppatient_id, primary_key: 'id', on_delete: :cascade

    add_foreign_key :pseudonymisation_keys, :ppatients, column: :ppatient_id, primary_key: 'id', on_delete: :cascade
    add_foreign_key :pseudonymisation_keys, :ze_type, column: :e_type, primary_key: 'ze_typeid'
    add_foreign_key :pseudonymisation_keys, :zprovider, column: :provider, primary_key: 'zproviderid'

    add_foreign_key :e_action, :e_batch, column: :e_batchid, primary_key: 'e_batchid'
    add_foreign_key :e_action, :ze_actiontype, column: :e_actiontype, primary_key: 'ze_actiontypeid'

    add_foreign_key :e_batch, :ze_type, column: :e_type, primary_key: 'ze_typeid'
    add_foreign_key :e_batch, :zprovider, column: :provider, primary_key: 'zproviderid'
    add_foreign_key :e_batch, :zprovider, column: :registryid, primary_key: 'zproviderid'

    add_foreign_key :e_workflow, :ze_actiontype, column: :last_e_actiontype, primary_key: 'ze_actiontypeid'
    add_foreign_key :e_workflow, :ze_actiontype, column: :next_e_actiontype, primary_key: 'ze_actiontypeid'
    add_foreign_key :e_workflow, :ze_type, column: :e_type, primary_key: 'ze_typeid'
    add_foreign_key :e_workflow, :zprovider, column: :provider, primary_key: 'zproviderid'

    add_foreign_key :zuser, :zuser, column: :qa_supervisorid, primary_key: 'zuserid'
  end
end
