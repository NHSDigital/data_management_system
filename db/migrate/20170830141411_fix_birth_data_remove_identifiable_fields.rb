# Drop all identifiable columns from birth_data table (stored in demographics hash instead)
class FixBirthDataRemoveIdentifiableFields < ActiveRecord::Migration[5.0]
  def change
    # Generated with:
    # piped_fields = (Import::DelimitedFile::DIRECT_BIRTH_IDENTIFIERS+Import::DelimitedFile::INDIRECT_BIRTH_IDENTIFIERS).join('|')
    # puts (Import::DelimitedFile::DIRECT_BIRTH_IDENTIFIERS+Import::DelimitedFile::INDIRECT_BIRTH_IDENTIFIERS).join('|')
    # system("egrep ':(#{piped_fields}),' db/migrate/20161024104938_add_columns_to_pseudo_birth_data.rb | sed -e 's/add_column/remove_column/'")
    remove_column :birth_data, :pcdpob, :string
    remove_column :birth_data, :pobt, :string
    remove_column :birth_data, :sbind, :integer
    remove_column :birth_data, :dob, :string
    remove_column :birth_data, :fnamch1, :string
    remove_column :birth_data, :fnamch2, :string
    remove_column :birth_data, :fnamch3, :string
    remove_column :birth_data, :fnamchx_1, :string
    remove_column :birth_data, :fnamchx_2, :string
    remove_column :birth_data, :gestatn, :integer
    remove_column :birth_data, :icdpv_1, :string
    remove_column :birth_data, :icdpv_2, :string
    remove_column :birth_data, :icdpv_3, :string
    remove_column :birth_data, :icdpv_4, :string
    remove_column :birth_data, :icdpv_5, :string
    remove_column :birth_data, :icdpv_6, :string
    remove_column :birth_data, :icdpv_7, :string
    remove_column :birth_data, :icdpv_8, :string
    remove_column :birth_data, :icdpv_9, :string
    remove_column :birth_data, :icdpv_10, :string
    remove_column :birth_data, :icdpv_11, :string
    remove_column :birth_data, :icdpv_12, :string
    remove_column :birth_data, :icdpv_13, :string
    remove_column :birth_data, :icdpv_14, :string
    remove_column :birth_data, :icdpv_15, :string
    remove_column :birth_data, :icdpv_16, :string
    remove_column :birth_data, :icdpv_17, :string
    remove_column :birth_data, :icdpv_18, :string
    remove_column :birth_data, :icdpv_19, :string
    remove_column :birth_data, :icdpv_20, :string
    remove_column :birth_data, :icdpvf_1, :string
    remove_column :birth_data, :icdpvf_2, :string
    remove_column :birth_data, :icdpvf_3, :string
    remove_column :birth_data, :icdpvf_4, :string
    remove_column :birth_data, :icdpvf_5, :string
    remove_column :birth_data, :icdpvf_6, :string
    remove_column :birth_data, :icdpvf_7, :string
    remove_column :birth_data, :icdpvf_8, :string
    remove_column :birth_data, :icdpvf_9, :string
    remove_column :birth_data, :icdpvf_10, :string
    remove_column :birth_data, :icdpvf_11, :string
    remove_column :birth_data, :icdpvf_12, :string
    remove_column :birth_data, :icdpvf_13, :string
    remove_column :birth_data, :icdpvf_14, :string
    remove_column :birth_data, :icdpvf_15, :string
    remove_column :birth_data, :icdpvf_16, :string
    remove_column :birth_data, :icdpvf_17, :string
    remove_column :birth_data, :icdpvf_18, :string
    remove_column :birth_data, :icdpvf_19, :string
    remove_column :birth_data, :icdpvf_20, :string
    remove_column :birth_data, :nhsno, :string
    remove_column :birth_data, :sex, :integer
    remove_column :birth_data, :snamch, :string
    remove_column :birth_data, :codfft_1, :string
    remove_column :birth_data, :codfft_2, :string
    remove_column :birth_data, :codfft_3, :string
    remove_column :birth_data, :codfft_4, :string
    remove_column :birth_data, :codfft_5, :string
    remove_column :birth_data, :deathlab, :string
    remove_column :birth_data, :addrmt, :string
    remove_column :birth_data, :dobm, :string
    remove_column :birth_data, :fnamf_1, :string
    remove_column :birth_data, :fnamf_2, :string
    remove_column :birth_data, :fnamf_3, :string
    remove_column :birth_data, :fnamfx_1, :string
    remove_column :birth_data, :fnamfx_2, :string
    remove_column :birth_data, :fnamm_1, :string
    remove_column :birth_data, :fnamm_2, :string
    remove_column :birth_data, :fnamm_3, :string
    remove_column :birth_data, :fnammx_1, :string
    remove_column :birth_data, :fnammx_2, :string
    remove_column :birth_data, :namemaid, :string
    remove_column :birth_data, :pcdrm, :string
    remove_column :birth_data, :snamf, :string
    remove_column :birth_data, :snamm, :string
    remove_column :birth_data, :snammcf, :string
  end
end
