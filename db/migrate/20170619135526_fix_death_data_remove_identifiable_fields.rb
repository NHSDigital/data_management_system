# Drop all identifiable columns from death_data table (stored in demographics hash instead)
class FixDeathDataRemoveIdentifiableFields < ActiveRecord::Migration[5.0]
  def change
    # Generated with:
    # piped_fields = (Import::DelimitedFile::DIRECT_DEATH_IDENTIFIERS+Import::DelimitedFile::INDIRECT_DEATH_IDENTIFIERS).join('|')
    # puts (Import::DelimitedFile::DIRECT_DEATH_IDENTIFIERS+Import::DelimitedFile::INDIRECT_DEATH_IDENTIFIERS).join('|')
    # system("egrep ':#{piped_fields},' db/migrate/20161019132333_add_columns_to_pseudo_death_data.rb | sed -e 's/add_column/remove_column/'")
    remove_column :death_data, :mbism204id, :string
    remove_column :death_data, :ledrid, :integer
    remove_column :death_data, :pcdpod, :string
    remove_column :death_data, :addrdt, :string
    remove_column :death_data, :agec, :integer
    remove_column :death_data, :ageu1d, :string
    remove_column :death_data, :aksnamd_1, :string
    remove_column :death_data, :aksnamd_2, :string
    remove_column :death_data, :aksnamd_3, :string
    remove_column :death_data, :aksnamd_4, :string
    remove_column :death_data, :aksnamd_5, :string
    remove_column :death_data, :akfnamd_1_1, :string
    remove_column :death_data, :akfnamd_1_2, :string
    remove_column :death_data, :akfnamd_1_3, :string
    remove_column :death_data, :akfnamd_1_4, :string
    remove_column :death_data, :akfnamd_1_5, :string
    remove_column :death_data, :akfnamd_2_1, :string
    remove_column :death_data, :akfnamd_2_2, :string
    remove_column :death_data, :akfnamd_2_3, :string
    remove_column :death_data, :akfnamd_2_4, :string
    remove_column :death_data, :akfnamd_2_5, :string
    remove_column :death_data, :akfnamd_3_1, :string
    remove_column :death_data, :akfnamd_3_2, :string
    remove_column :death_data, :akfnamd_3_3, :string
    remove_column :death_data, :akfnamd_3_4, :string
    remove_column :death_data, :akfnamd_3_5, :string
    remove_column :death_data, :akfndi_1, :string
    remove_column :death_data, :akfndi_2, :string
    remove_column :death_data, :akfndi_3, :string
    remove_column :death_data, :akfndi_4, :string
    remove_column :death_data, :akfndi_5, :string
    remove_column :death_data, :aliasd_1, :string
    remove_column :death_data, :aliasd_2, :string
    remove_column :death_data, :dobdy, :integer
    remove_column :death_data, :dobmt, :integer
    remove_column :death_data, :dobyr, :integer
    remove_column :death_data, :fnamd1, :string
    remove_column :death_data, :fnamd2, :string
    remove_column :death_data, :fnamd3, :string
    remove_column :death_data, :fnamdx_1, :string
    remove_column :death_data, :fnamdx_2, :string
    remove_column :death_data, :namemaid, :string
    remove_column :death_data, :nhsno_1, :string
    remove_column :death_data, :nhsno_2, :string
    remove_column :death_data, :nhsno_3, :string
    remove_column :death_data, :nhsno_4, :string
    remove_column :death_data, :nhsno_5, :string
    remove_column :death_data, :nhsnorss, :string
    remove_column :death_data, :pcdr, :string
    remove_column :death_data, :pobt, :string
    remove_column :death_data, :sex, :integer
    remove_column :death_data, :snamd, :string
    remove_column :death_data, :agecs, :integer
    remove_column :death_data, :namehf, :string
    remove_column :death_data, :namem, :string
    remove_column :death_data, :certifer, :string
    remove_column :death_data, :namec, :string
    remove_column :death_data, :namecon, :string
  end
end
